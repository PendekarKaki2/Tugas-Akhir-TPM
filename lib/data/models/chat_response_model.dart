/// Chat Response model untuk menyimpan response beserta referensi materi
class ChatResponseModel {
  final String response;
  final List<ChatReference> references;

  ChatResponseModel({
    required this.response,
    this.references = const [],
  });
}

/// Reference model untuk materi yang digunakan
class ChatReference {
  final int materialId;
  final String title;
  final String excerpt;

  ChatReference({
    required this.materialId,
    required this.title,
    required this.excerpt,
  });
}
