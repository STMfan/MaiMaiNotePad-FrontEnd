import 'package:flutter/foundation.dart';

import '../models/message.dart';
import '../repositories/message_repository.dart';
import '../services/core/api_error.dart';

class MessageDetailViewModel extends ChangeNotifier {
  MessageDetailViewModel({
    required String messageId,
    MessageRepository? repository,
  })  : _messageId = messageId,
        _repository = repository ?? MessageRepository();

  final String _messageId;
  final MessageRepository _repository;

  Message? _message;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDeleting = false;

  Message? get message => _message;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDeleting => _isDeleting;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _message = await _repository.fetchDetail(_messageId);
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead() async {
    if (_message == null || _message!.isRead) {
      return;
    }

    try {
      await _repository.markAsRead(_messageId);
      _message = _message!.copyWith(isRead: true);
      notifyListeners();
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      rethrow;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMessage() async {
    if (_message == null || _isDeleting) {
      return;
    }

    _isDeleting = true;
    notifyListeners();

    try {
      await _repository.deleteMessage(_messageId);
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}


