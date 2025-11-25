import '../models/message.dart';
import '../services/api/message_api.dart';

class MessageRepository {
  MessageRepository({MessageApi? api}) : _api = api ?? MessageApi();

  final MessageApi _api;

  Future<Message> fetchDetail(String messageId) {
    return _api.fetchDetail(messageId);
  }

  Future<void> markAsRead(String messageId) {
    return _api.markAsRead(messageId);
  }

  Future<void> deleteMessage(String messageId) {
    return _api.deleteMessage(messageId);
  }
}

