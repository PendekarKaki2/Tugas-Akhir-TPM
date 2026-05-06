# OpenAI ChatGPT Integration Guide

## 🚀 Cara Setup OpenAI API untuk Chatbot (Alternatif ke Gemini)

### Langkah 1: Dapatkan API Key OpenAI

1. Buka https://platform.openai.com/api-keys
2. Login dengan akun OpenAI Anda (atau buat akun baru)
3. Klik "Create new secret key"
4. Copy API Key yang sudah dibuat
5. **PENTING**: Save di tempat aman, tidak bisa dilihat lagi!

### Langkah 2: Setup API Key di Project

Ikuti langkah yang sama seperti Gemini, tapi untuk OpenAI:

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String openAiApiKey = 'sk-your-api-key-here';
  static const String openAiModel = 'gpt-4-turbo';
}
```

### Langkah 3: Update ChatRemoteDataSource (Opsional)

Jika ingin switch dari Gemini ke OpenAI:

```dart
// lib/data/sources/remote/chat_remote_data_source.dart
import '../../../core/services/openai_service.dart';

class ChatRemoteDataSource {
  final OpenAiService _openAiService; // Ganti dari GeminiService

  ChatRemoteDataSource(this._openAiService);
  
  // ... rest of code
}
```

### Langkah 4: Update main.dart

```dart
// lib/main.dart
import 'core/services/openai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dio = Dio(...);
  final openAiService = OpenAiService(dio); // Ganti dari GeminiService
  
  final chatRemoteDataSource = ChatRemoteDataSource(openAiService);
  
  // ... rest of code
}
```

---

## 💰 Pricing & Quota

**OpenAI Pricing (Per 1M tokens):**
- **GPT-4o**: Input $2.50, Output $10.00
- **GPT-4 Turbo**: Input $10.00, Output $30.00
- **GPT-3.5 Turbo**: Input $0.50, Output $1.50

**Free Trial:**
- $5 credits untuk 3 bulan pertama
- Setelah itu: pay-as-you-go

---

## 🔄 Gemini vs OpenAI - Perbandingan

| Aspek | Gemini | OpenAI |
|-------|--------|--------|
| **Free Tier** | ✅ Unlimited (rate limit) | ❌ No ($5 trial) |
| **Gratis untuk Development** | ✅ Yes | ❌ No |
| **Response Quality** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Speed** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Harga** | Murah | Lebih mahal |
| **Indonesian Support** | Bagus | Bagus |

**Rekomendasi**: Gunakan **Gemini** untuk production karena free tier unlimited!

---

## 📝 Contoh Response OpenAI vs Gemini

**Input**: "Jelaskan fotosintesis dengan cara yang menyenangkan"

**Gemini (2.0-flash)**:
```
Fotosintesis adalah proses dimana tumbuhan mengubah cahaya matahari 
menjadi makanan! Bayangkan tumbuhan seperti pabrik mini dengan panel surya...
```

**GPT-4 Turbo**:
```
Fotosintesis adalah proses biologis menakjubkan dimana tumbuhan hijau 
memanfaatkan energi matahari untuk mengubah karbon dioksida dan air...
```

Keduanya bagus, tinggal preference!

---

## 🐛 Troubleshooting OpenAI

### Error: "Invalid API Key"
- Pastikan API key dimulai dengan `sk-`
- Regenerate key jika perlu
- Check billing aktif (OpenAI butuh payment method)

### Error: "Insufficient quota"
- Anda kehabisan credit
- Tambahkan payment method & top-up
- Atau gunakan model yang lebih murah (gpt-3.5-turbo)

### Error: "Rate limit exceeded"
- OpenAI punya rate limit
- Tunggu sebelum request berikutnya
- Upgrade plan untuk higher limit

---

## ✨ Rekomendasi Implementasi

**Best Practice**: Support kedua API!

```dart
// lib/core/services/ai_service_factory.dart
abstract class AiService {
  Future<String> sendMessage(String message);
  bool get isInitialized;
}

class AiServiceFactory {
  static AiService createService(AiProvider provider, dynamic client) {
    switch (provider) {
      case AiProvider.gemini:
        return GeminiService();
      case AiProvider.openai:
        return OpenAiService(client as Dio);
    }
  }
}

enum AiProvider { gemini, openai }
```

Dengan ini, user bisa pilih AI provider di settings!

---

## 📚 Resources

- [OpenAI API Docs](https://platform.openai.com/docs/api-reference)
- [OpenAI Models](https://platform.openai.com/docs/models)
- [OpenAI Pricing](https://openai.com/pricing)

---

**Pilih yang terbaik untuk project Anda!** 🚀
