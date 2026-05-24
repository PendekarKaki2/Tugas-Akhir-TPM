/// API Constants
class ApiConstants {
  // Google Gemini API
  // Dapatkan API key dari: https://aistudio.google.com/apikey
  // Jalankan dengan:
  // flutter run --dart-define=GEMINI_API_KEY=your_key_here
  static String get geminiApiKey {
    const raw = String.fromEnvironment(
      'GEMINI_API_KEY',
      defaultValue: 'AIzaSyAL1pkkD_NAMXIzvOweWexov93tNx81YXs',
    );
    return raw.trim();
  }

  // Model yang digunakan
  static const String geminiModel = 'gemini-2.0-flash';
  
  // Timeout settings
  static const int connectTimeout = 30; // detik
  static const int receiveTimeout = 30; // detik
}

