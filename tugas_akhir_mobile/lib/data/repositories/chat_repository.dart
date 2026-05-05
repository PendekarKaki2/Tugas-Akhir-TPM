import '../sources/remote/chat_remote_data_source.dart';

/// Chat Repository
class ChatRepository {
  final ChatRemoteDataSource _remoteDataSource;

  ChatRepository(this._remoteDataSource);

  /// Send message and get response
  Future<String> sendMessage(String message) async {
    return await _remoteDataSource.sendMessage(message);
  }
}
