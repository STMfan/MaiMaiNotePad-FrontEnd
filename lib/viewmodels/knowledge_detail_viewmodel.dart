import 'package:flutter/foundation.dart';

import '../models/delete_knowledge_file_result.dart';
import '../models/knowledge.dart';
import '../repositories/knowledge_repository.dart';
import '../services/core/api_error.dart';

class KnowledgeDetailViewModel extends ChangeNotifier {
  KnowledgeDetailViewModel({
    required String knowledgeId,
    KnowledgeRepository? repository,
  })  : _knowledgeId = knowledgeId,
        _repository = repository ?? KnowledgeRepository();

  final String _knowledgeId;
  final KnowledgeRepository _repository;

  Knowledge? _knowledge;
  bool _isStarred = false;
  bool _isLoading = false;
  bool _isStarring = false;
  bool _deleting = false;
  String? _deletingFileId;
  String? _errorMessage;
  bool _isDeletingKnowledge = false;

  Knowledge? get knowledge => _knowledge;
  bool get isStarred => _isStarred;
  bool get isLoading => _isLoading;
  bool get isStarring => _isStarring;
  bool get isDeleting => _deleting;
  String? get deletingFileId => _deletingFileId;
  String? get errorMessage => _errorMessage;
  bool get isDeletingKnowledge => _isDeletingKnowledge;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await _repository.loadDetail(_knowledgeId);
      _knowledge = result.knowledge;
      _isStarred = result.isStarred;
      _errorMessage = null;
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> toggleStar() async {
    if (_knowledge == null || _isStarring) {
      return;
    }
    _isStarring = true;
    notifyListeners();

    try {
      final nextStarState = await _repository.toggleStar(
        knowledgeId: _knowledgeId,
        isStarred: _isStarred,
      );
      _isStarred = nextStarState;
      if (_knowledge != null) {
        final delta = nextStarState ? 1 : -1;
        final nextStarCount =
            (_knowledge!.starCount + delta).clamp(0, 1 << 30).toInt();
        _knowledge = _knowledge!.copyWith(starCount: nextStarCount);
      }
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isStarring = false;
      notifyListeners();
    }
  }

  Future<DeleteKnowledgeFileResult?> deleteFile(String fileId) async {
    if (_knowledge == null || _deleting) {
      return null;
    }
    _deleting = true;
    _deletingFileId = fileId;
    notifyListeners();

    try {
      final result = await _repository.deleteFile(
        knowledgeId: _knowledgeId,
        fileId: fileId,
      );
      await load(silent: true);
      return result;
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (error) {
      _errorMessage = error.toString();
      return null;
    } finally {
      _deleting = false;
      _deletingFileId = null;
      notifyListeners();
    }
  }

  Future<void> deleteKnowledge() async {
    if (_knowledge == null || _isDeletingKnowledge) {
      return;
    }
    _isDeletingKnowledge = true;
    notifyListeners();

    try {
      await _repository.deleteKnowledge(_knowledgeId);
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
      rethrow;
    } catch (error) {
      _errorMessage = error.toString();
      rethrow;
    } finally {
      _isDeletingKnowledge = false;
      notifyListeners();
    }
  }
}

