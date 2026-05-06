import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_constants.dart';

/// Service untuk komunikasi dengan Google Gemini API
class GeminiService {
  late GenerativeModel _model;
  late ChatSession _chatSession;
  bool _isInitialized = false;

  /// Initialize Gemini service
  void initialize({String? apiKey}) {
    if (!_isInitialized) {
      final key = apiKey ?? ApiConstants.geminiApiKey;
      
      _model = GenerativeModel(
        model: ApiConstants.geminiModel,
        apiKey: key,
      );
      
      // Initialize chat session untuk multi-turn conversation
      _chatSession = _model.startChat();
      _isInitialized = true;
    }
  }

  /// Send message to Gemini and get response
  Future<String> sendMessage(String message) async {
    try {
      if (!_isInitialized) {
        initialize();
      }

      // System prompt untuk membuat AI lebih fokus sebagai tutor
      final response = await _chatSession.sendMessage(
        Content.text(message),
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }

      return 'Maaf, saya tidak bisa memproses pesan Anda. Silakan coba lagi.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Send message with system context (untuk digunakan di masa depan)
  Future<String> sendMessageWithContext(
    String message, {
    String systemContext = '',
  }) async {
    try {
      if (!_isInitialized) {
        initialize();
      }

      // Combine system context dengan user message
      final fullMessage = systemContext.isNotEmpty
          ? '$systemContext\n\nPertanyaan: $message'
          : message;

      final response = await _chatSession.sendMessage(
        Content.text(fullMessage),
      );

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!;
      }

      return 'Maaf, saya tidak bisa memproses pesan Anda.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Clear chat history
  void clearHistory() {
    _chatSession = _model.startChat();
  }

  /// Get chat history (untuk logging atau debugging)
  List<Content> getChatHistory() {
    return _chatSession.history.toList();
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
