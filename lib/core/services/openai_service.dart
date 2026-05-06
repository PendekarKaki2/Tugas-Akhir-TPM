import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Service untuk komunikasi dengan OpenAI API (ChatGPT)
class OpenAiService {
  final Dio _dio;
  final String baseUrl = 'https://api.openai.com/v1';
  bool _isInitialized = false;

  OpenAiService(this._dio);

  /// Initialize OpenAI service
  void initialize({String? apiKey}) {
    if (!_isInitialized) {
      // Setup Dio interceptor untuk menambah API key
      _dio.options.headers['Authorization'] =
          'Bearer ${apiKey ?? ApiConstants.openAiApiKey}';
      _dio.options.headers['Content-Type'] = 'application/json';
      _isInitialized = true;
    }
  }

  /// Send message to ChatGPT and get response
  Future<String> sendMessage(String message) async {
    try {
      if (!_isInitialized) {
        initialize();
      }

      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: {
          'model': 'gpt-4-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Anda adalah EduFun AI Assistant, tutor yang baik dan helpful. Jawab pertanyaan pembelajaran dengan jelas, singkat, dan menyenangkan.'
            },
            {
              'role': 'user',
              'content': message,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        },
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return content ?? 'Maaf, saya tidak bisa memproses pesan Anda.';
      }

      return 'Error: Terjadi kesalahan saat memproses request (${response.statusCode})';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;
}
