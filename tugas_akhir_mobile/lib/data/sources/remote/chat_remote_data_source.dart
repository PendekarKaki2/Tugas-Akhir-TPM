import 'package:dio/dio.dart';

/// Remote Data Source for Chat API
class ChatRemoteDataSource {
  final Dio _dio;
  final String baseUrl = 'https://api.example.com';

  ChatRemoteDataSource(this._dio);

  /// Send message to AI and get response
  Future<String> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        '$baseUrl/chat',
        data: {'message': message},
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return response.data['response'] ?? 'Maaf, saya belum bisa memproses pesan itu.';
      }
      return 'Terjadi kesalahan: ${response.statusCode}';
    } on DioException {
      // Return mock response if API fails
      return _getMockResponse(message);
    }
  }

  /// Get mock response (fallback)
  String _getMockResponse(String message) {
    final normalizedMessage = _normalize(message);

    if (_isGreeting(normalizedMessage)) {
      return 'Halo! Saya EduFun AI Assistant. Saya siap bantu kamu belajar hari ini.';
    }

    final mathResult = _solveSimpleMath(normalizedMessage);
    if (mathResult != null) {
      return mathResult;
    }

    if (_containsAny(normalizedMessage, ['apa aja yang bisa kamu jawab', 'bisa jawab apa', 'kamu bisa apa', 'apa yang bisa kamu bantu'])) {
      return 'Saya bisa bantu menjawab pertanyaan belajar seperti:\n- Sejarah\n- Biologi\n- Matematika dasar\n- IPA\n- Bahasa Indonesia\n- Pengetahuan umum\n\nKalau mau, tulis pertanyaan yang lebih spesifik dan saya akan jawab langsung.';
    }

    if (_containsAny(normalizedMessage, ['bantuan', 'tolong', 'help'])) {
      return 'Saya bisa bantu:\n- Menjawab pertanyaan pelajaran\n- Menjelaskan konsep\n- Memberi ringkasan materi\n- Memberi contoh soal sederhana\n\nCoba kirim pertanyaan seperti: "kapan Indonesia merdeka" atau "jelaskan tentang katak".';
    }

    if (_containsAny(normalizedMessage, ['kapan indonesia merdeka', 'kapan merdeka', 'sejarah indonesia', 'kemerdekaan indonesia'])) {
      return 'Indonesia merdeka pada 17 Agustus 1945. Proklamasi dibacakan oleh Soekarno dan Hatta di Jakarta.';
    }

    if (_containsAny(normalizedMessage, ['siapa presiden indonesia', 'presiden indonesia sekarang', 'siapa presiden sekarang'])) {
      return 'Presiden Indonesia saat ini adalah Prabowo Subianto.';
    }

    if (_containsAny(normalizedMessage, ['ibukota indonesia', 'ibu kota indonesia', 'ibu kota negara indonesia'])) {
      return 'Ibu kota Indonesia saat ini adalah Jakarta.';
    }

    if (_containsAny(normalizedMessage, ['apa itu katak', 'jelaskan tentang katak', 'katak', 'amfibi'])) {
      return 'Katak adalah hewan amfibi yang hidup di dua alam, yaitu air dan darat. Katak bernapas dengan paru-paru dan kulit, mengalami metamorfosis, dan biasanya memakan serangga.';
    }

    if (_containsAny(normalizedMessage, ['apa itu fotosintesis', 'jelaskan fotosintesis', 'fotosintesis'])) {
      return 'Fotosintesis adalah proses tumbuhan membuat makanan sendiri dengan bantuan cahaya matahari, air, dan karbon dioksida. Hasil utamanya adalah glukosa dan oksigen.';
    }

    if (_containsAny(normalizedMessage, ['apa itu mamalia', 'jelaskan mamalia', 'mamalia'])) {
      return 'Mamalia adalah kelompok hewan yang menyusui anaknya, umumnya berambut atau berbulu, dan bernapas dengan paru-paru.';
    }

    if (_containsAny(normalizedMessage, ['apa itu remaja', 'jelaskan remaja', 'remaja'])) {
      return 'Remaja adalah masa peralihan dari anak-anak menuju dewasa, biasanya ditandai dengan perubahan fisik, emosi, dan cara berpikir.';
    }

    if (_containsAny(normalizedMessage, ['apa itu kata benda', 'jelaskan kata benda', 'kata benda'])) {
      return 'Kata benda adalah kata yang merujuk pada nama orang, tempat, benda, atau konsep. Contohnya: buku, Jakarta, guru, dan kebahagiaan.';
    }

    if (_containsAny(normalizedMessage, ['apa itu kata kerja', 'jelaskan kata kerja', 'kata kerja'])) {
      return 'Kata kerja adalah kata yang menyatakan tindakan atau kegiatan. Contohnya: makan, berjalan, belajar, dan menulis.';
    }

    if (_containsAny(normalizedMessage, ['katak', 'amfibi', 'biologi', 'ipa', 'sains', 'science'])) {
      return 'Katak adalah hewan amfibi yang hidup di dua alam, yaitu air dan darat. Katak bernapas dengan paru-paru dan kulit, mengalami metamorfosis, dan biasanya memakan serangga.';
    }

    if (_containsAny(normalizedMessage, ['matematika', 'math', 'hitung'])) {
      return 'Matematika seru! 📐 Mau latihan:\n- Penjumlahan & Pengurangan\n- Perkalian & Pembagian\n- Geometri\n- Aljabar';
    }

    if (_containsAny(normalizedMessage, ['terima kasih', 'makasih', 'thanks'])) {
      return 'Sama-sama! Semangat belajarnya ya. 🚀';
    }

    final questionAnswer = _answerCommonQuestion(normalizedMessage);
    if (questionAnswer != null) {
      return questionAnswer;
    }

    if (_looksLikeQuestion(normalizedMessage)) {
      return 'Saya belum menemukan jawaban yang pasti dari pertanyaan itu. Coba tambahkan konteks, misalnya mata pelajaran, nama tokoh, tempat, atau topik yang dimaksud.';
    }

    return 'Saya siap bantu. Kirim pertanyaan yang lebih spesifik agar saya bisa menjawab dengan tepat.';
  }

  String _normalize(String message) {
    return message
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isGreeting(String message) {
    return _containsAny(message, ['halo', 'hai', 'hello', 'hi']);
  }

  bool _looksLikeQuestion(String message) {
    return message.contains('?') ||
        _containsAny(message, ['apa', 'siapa', 'kapan', 'dimana', 'di mana', 'mengapa', 'kenapa', 'bagaimana', 'jelaskan']);
  }

  String? _answerCommonQuestion(String message) {
    if (_containsAny(message, ['berapa hasil', 'hasil dari', 'berapa'])) {
      return null;
    }

    if (_containsAny(message, ['apa itu', 'jelaskan', 'sebutkan'])) {
      final topic = message
          .replaceFirst(RegExp(r'^(apa itu|jelaskan tentang|jelaskan|sebutkan tentang|sebutkan)\s+'), '')
          .trim();

      if (topic.isNotEmpty) {
        return 'Berikut penjelasan singkat tentang $topic: saya bisa bantu lebih tepat kalau kamu kirim topik yang lebih spesifik atau mata pelajarannya.';
      }
    }

    return null;
  }

  String? _solveSimpleMath(String message) {
    final compact = message.replaceAll(' ', '');
    final expressionMatch = RegExp(r'^(-?\d+(?:[\.,]\d+)?)([+\-*/xX:])(-?\d+(?:[\.,]\d+)?)$').firstMatch(compact);
    if (expressionMatch == null) {
      return null;
    }

    final left = double.tryParse(expressionMatch.group(1)!.replaceAll(',', '.'));
    final right = double.tryParse(expressionMatch.group(3)!.replaceAll(',', '.'));
    final operator = expressionMatch.group(2)!;

    if (left == null || right == null) {
      return null;
    }

    double? result;
    switch (operator) {
      case '+':
        result = left + right;
        break;
      case '-':
        result = left - right;
        break;
      case '*':
      case 'x':
      case 'X':
        result = left * right;
        break;
      case '/':
      case ':':
        if (right == 0) {
          return 'Pembagian dengan nol tidak diperbolehkan.';
        }
        result = left / right;
        break;
    }

    if (result == null) {
      return null;
    }

    final formattedResult = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(2);
    return 'Hasilnya adalah $formattedResult.';
  }

  bool _containsAny(String message, List<String> keywords) {
    for (final keyword in keywords) {
      if (message.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
