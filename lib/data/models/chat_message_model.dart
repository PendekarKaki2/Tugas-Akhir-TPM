/// Chat Message Model
class ChatMessageModel {
  final String id;
  final String message;
  final bool isUser;
  final String timestamp;

  ChatMessageModel({
    required this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser,
      'timestamp': timestamp,
    };
  }

  /// Create from JSON
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      message: json['message'],
      isUser: json['isUser'],
      timestamp: json['timestamp'],
    );
  }
}
