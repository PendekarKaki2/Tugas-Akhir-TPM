/// Material uploaded by mentor
class MaterialModel {
  final int? id;
  final int mentorId;
  final String title;
  final String? content;
  final String? filePath;
  final String? createdAt;

  MaterialModel({
    this.id,
    required this.mentorId,
    required this.title,
    this.content,
    this.filePath,
    this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mentorId': mentorId,
      'title': title,
      'content': content,
      'filePath': filePath,
      'createdAt': createdAt,
    };
  }

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      mentorId: json['mentorId'],
      title: json['title'],
      content: json['content'],
      filePath: json['filePath'],
      createdAt: json['createdAt'],
    );
  }
}
