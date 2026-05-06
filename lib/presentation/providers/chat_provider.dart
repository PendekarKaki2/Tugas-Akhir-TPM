import 'package:flutter/material.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/models/chat_response_model.dart';

/// Chat Provider for AI Chatbot
class ChatProvider extends ChangeNotifier {
  final ChatRepository _chatRepository;

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._chatRepository);

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Send message
  Future<void> sendMessage(String message) async {
    // Add user message
    _messages.add({
      'text': message,
      'isUser': true,
      'timestamp': DateTime.now(),
      'references': <ChatReference>[],
    });

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _chatRepository.sendMessage(message);

      // Add bot response with references
      _messages.add({
        'text': response.response,
        'isUser': false,
        'timestamp': DateTime.now(),
        'references': response.references,
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear messages
  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
