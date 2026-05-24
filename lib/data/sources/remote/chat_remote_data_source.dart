import '../../../core/services/gemini_service.dart';
import '../../models/material_model.dart';
import '../../models/chat_response_model.dart';
import '../local/material_local_data_source.dart';


/// Remote Data Source for Chat API.
/// Uses Gemini for real AI responses and a small fallback for offline/error cases.
class ChatRemoteDataSource {
  final GeminiService _geminiService;
  final MaterialLocalDataSource? _materialLocalDataSource;

  ChatRemoteDataSource(this._geminiService, [this._materialLocalDataSource]);

  /// Send message to AI and get response with material references.
  Future<ChatResponseModel> sendMessage(String message) async {
    try {
      if (!_geminiService.isInitialized) {
        _geminiService.initialize();
      }

      // Try to augment user message with relevant materials from local DB.
      String systemContext = '';
      List<ChatReference> references = [];
      try {
        if (_materialLocalDataSource != null) {
          final all = await _materialLocalDataSource.getAllMaterials();
          final relevant = _selectRelevantMaterials(message, all, limit: 3);
          if (relevant.isNotEmpty) {
            systemContext = _buildSystemContext(relevant);
            // Build references
            references = relevant
                .map((m) => ChatReference(
                      materialId: m.id ?? 0,
                      title: m.title,
                      excerpt: _excerpt(_materialText(m), 200),
                    ))
                .toList();
          }
        }
      } catch (_) {
        // ignore material lookup errors and continue with plain AI call
      }

      final response = systemContext.isNotEmpty
          ? await _geminiService.sendMessageWithContext(message, systemContext: systemContext)
          : await _geminiService.sendMessage(message);

      return ChatResponseModel(response: response, references: references);
    } catch (_) {
      return ChatResponseModel(response: _getFallbackResponse(message));
    }
  }

  /// Fallback response when Gemini is unavailable.
  String _getFallbackResponse(String message) {
    final normalizedMessage = _normalize(message);

    if (_isGreeting(normalizedMessage)) {
      return 'Halo! Saya EduFun AI Assistant. Saya siap bantu kamu belajar hari ini. Tanya apa saja!';
    }

    if (_containsAny(normalizedMessage, [
      'apa aja yang bisa kamu jawab',
      'bisa jawab apa',
      'kamu bisa apa',
      'apa yang bisa kamu bantu'
    ])) {
      return 'Saya bisa membantu dengan:\n- Matematika, Fisika, Kimia, Biologi\n- Sejarah, Geografi, Bahasa Indonesia, Bahasa Inggris\n- Seni, Musik, Olahraga\n- Tips belajar dan strategi\n- Pertanyaan lainnya\n\nTanya apa saja yang ingin dipelajari! 📚';
    }

    if (_containsAny(normalizedMessage, ['terima kasih', 'makasih', 'thanks'])) {
      return 'Sama-sama! Semangat belajarnya ya. 🚀';
    }

    return 'Saya belum bisa merespons itu dengan baik. Coba bertanya dengan lebih spesifik atau pastikan koneksi internet stabil.';
  }

  String _normalize(String message) {
    return message.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _isGreeting(String message) {
    return _containsAny(message, ['halo', 'hai', 'hello', 'hi', 'assalamualaikum']);
  }

  bool _containsAny(String message, List<String> keywords) {
    for (final keyword in keywords) {
      if (message.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  List<MaterialModel> _selectRelevantMaterials(String query, List<MaterialModel> materials, {int limit = 3}) {
    final q = query.toLowerCase();
    final scored = <MaterialModel, int>{};
    for (final m in materials) {
      var score = 0;
      final title = m.title.toLowerCase();
      final content = (m.content ?? '').toLowerCase();
      if (title.contains(q)) score += 3;
      if (content.contains(q)) score += 2;

      // also simple keyword split matching
      for (final part in q.split(RegExp(r'\s+'))) {
        if (part.isEmpty) continue;
        if (title.contains(part)) score += 1;
        if (content.contains(part)) score += 1;
      }

      if (score > 0) scored[m] = score;
    }

    final sorted = scored.keys.toList()
      ..sort((a, b) => (scored[b]!).compareTo(scored[a]!));

    return sorted.take(limit).toList();
  }

  String _buildSystemContext(List<MaterialModel> materials) {
    final buffer = StringBuffer();
    buffer.writeln('Kamu adalah tutor AI untuk EduFun. Gunakan materi yang diupload mentor/educator sebagai sumber utama jawaban.');
    buffer.writeln('Jika pertanyaan siswa terkait langsung dengan materi di bawah, prioritaskan isi materi dan jelaskan dengan bahasa sederhana.');
    buffer.writeln('Jika jawaban tidak ada di materi, katakan dengan jujur bahwa materi yang tersedia belum cukup, lalu beri penjelasan umum yang membantu.');
    for (final m in materials) {
      buffer.writeln('\nJudul: ${m.title}');
      final excerpt = _excerpt(_materialText(m), 600);
      buffer.writeln('Isi materi: $excerpt');
      if (m.filePath != null && m.filePath!.isNotEmpty) {
        buffer.writeln('Lampiran: ${m.filePath}');
      }
    }
    return buffer.toString();
  }

  String _materialText(MaterialModel material) {
    final buffer = StringBuffer();
    if (material.title.trim().isNotEmpty) {
      buffer.write(material.title.trim());
    }
    if ((material.content ?? '').trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write(material.content!.trim());
    }
    if ((material.filePath ?? '').trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('File: ${material.filePath!.trim()}');
    }
    return buffer.toString();
  }

  String _excerpt(String text, int maxLen) {
    final t = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= maxLen) return t;
    return '${t.substring(0, maxLen).trim()}...';
  }
}
