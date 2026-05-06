# Gemini AI Chatbot Integration Setup Guide

## 🚀 Cara Setup Gemini AI untuk Chatbot

### Langkah 1: Dapatkan API Key Gemini

1. Buka https://aistudio.google.com/apikey
2. Login dengan akun Google Anda
3. Klik tombol "Get API Key" atau "Create API Key"
4. Pilih project atau buat project baru
5. Copy API Key yang sudah dibuat

### Langkah 2: Setup API Key di Project

**Opsi A: Langsung di Code (Tidak Aman - Hanya untuk Testing)**
```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const String geminiModel = 'gemini-2.0-flash';
}
```

**Opsi B: Menggunakan Environment Variables (RECOMMENDED)**

1. Buat file `.env` di root project:
```
GEMINI_API_KEY=your_api_key_here
```

2. Update `pubspec.yaml`:
```yaml
dependencies:
  flutter_dotenv: ^5.2.0
```

3. Ubah `api_constants.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String geminiModel = 'gemini-2.0-flash';
}
```

4. Update `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const MyApp());
}
```

### Langkah 3: Install Dependencies

```bash
flutter pub get
```

### Langkah 4: Jalankan App

```bash
flutter run
```

---

## 📚 Struktur Gemini Integration

### File-file yang Dibuat:

1. **`lib/core/services/gemini_service.dart`**
   - Service untuk komunikasi dengan Gemini API
   - Handle initialization dan multi-turn conversation
   - Fallback jika API error

2. **`lib/core/constants/api_constants.dart`**
   - Konstanta API key dan model
   - Timeout settings

3. **Updated `lib/data/sources/remote/chat_remote_data_source.dart`**
   - Menggunakan GeminiService bukan Dio
   - Fallback responses jika API gagal

4. **Updated `lib/main.dart`**
   - Initialize GeminiService
   - Inject ke ChatRemoteDataSource

---

## 🎯 Features

✅ **Real-time AI Responses**
- Chatbot yang benar-benar berbicara dengan AI
- Bukan hardcoded responses

✅ **Multi-turn Conversations**
- AI mengingat konteks percakapan sebelumnya
- Lebih natural dan interactive

✅ **Error Handling**
- Fallback responses jika API gagal
- Graceful degradation

✅ **Efficient API Usage**
- Chat session di-maintain untuk mengurangi API calls
- Support untuk clearing history

---

## 💡 Contoh Penggunaan

User dapat bertanya tentang apa saja, bukan hanya hardcoded topics:

```
User: "Bagaimana cara belajar efektif?"
AI: [Real response dari Gemini AI]

User: "Jelaskan tentang fotosintesis dengan analogi yang menarik"
AI: [Real-time creative response]

User: "Berapa hasil dari 2²³?"
AI: [Calculated response]
```

---

## ⚙️ Models Available

Gemini menyediakan beberapa model:
- **`gemini-2.0-flash`** (Recommended) - Fast, free tier available
- `gemini-1.5-pro` - More powerful, paid
- `gemini-1.5-flash` - Budget friendly

---

## 🔒 Security Best Practices

1. **Jangan commit API key ke repository**
   - Gunakan `.env` file dan tambahkan ke `.gitignore`
   - Gunakan environment variables di production

2. **Rate Limiting**
   - Gemini punya rate limit, monitor usage
   - Free tier: ~60 requests per minute

3. **Input Validation**
   - Validasi user input sebelum mengirim ke API
   - Cegah injection attacks

---

## 📊 Quota & Pricing

**Free Tier:**
- 60 requests per minute
- Unlimited requests per day (dengan rate limit)
- Semua model tersedia

**Paid Tier:**
- Higher rate limits
- Volume discount

Cek lebih lanjut: https://ai.google.dev/pricing

---

## 🐛 Troubleshooting

### Error: "Invalid API Key"
- Pastikan API key benar dan aktif
- Regenerate API key jika perlu

### Error: "Rate limit exceeded"
- Tunggu beberapa saat sebelum request lagi
- Upgrade ke paid tier jika perlu

### Error: "Model not found"
- Pastikan model name benar di `api_constants.dart`
- Gunakan model yang tersedia di region Anda

### Gemini tidak respond
- Check internet connection
- Lihat logs untuk error message
- Fallback response akan di-return

---

## 📚 Resources

- [Gemini API Docs](https://ai.google.dev/gemini-api)
- [Google Generative AI Package](https://pub.dev/packages/google_generative_ai)
- [Gemini API Models](https://ai.google.dev/models/gemini-2-0-flash)

---

## ✨ Next Steps

Untuk meningkatkan chatbot lebih lanjut:

1. **System Prompt**: Tambah custom system context untuk tutor yang lebih baik
2. **Streaming**: Implement streaming responses untuk UX yang lebih baik
3. **Caching**: Cache responses untuk pertanyaan yang sama
4. **Analytics**: Track user questions untuk improvement
5. **Multi-language**: Support bahasa lain selain Indonesia

---

**Happy Learning! 🚀**
