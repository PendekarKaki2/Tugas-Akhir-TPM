/// API Constants
class ApiConstants {
  // Google Gemini API
  // Dapatkan API key dari: https://aistudio.google.com/apikey
  static const String geminiApiKey = 'AIzaSyDTHt8GhYFkQdg-WXLcw7q5dJbQoFXEMyQ';
  
  // Model yang digunakan
  static const String geminiModel = 'gemini-2.0-flash';
  
  // OpenAI API (Alternatif, jika ingin gunakan ChatGPT)
  // Dapatkan API key dari: https://platform.openai.com/api-keys
  static const String openAiApiKey = 'sk-your-openai-api-key-here';
  static const String openAiModel = 'gpt-4-turbo';
  
  // Timeout settings
  static const int connectTimeout = 30; // detik
  static const int receiveTimeout = 30; // detik
}

