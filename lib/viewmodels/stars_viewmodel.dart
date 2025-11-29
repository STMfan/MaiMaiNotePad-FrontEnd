import 'package:flutter/foundation.dart';

import '../models/knowledge.dart';
import '../models/persona.dart';
import '../repositories/star_repository.dart';
import '../services/core/api_error.dart';
import '../services/api/knowledge_api.dart';
import '../services/api/persona_api.dart';

class StarsViewModel extends ChangeNotifier {
  StarsViewModel({StarRepository? repository})
      : _repository = repository ?? StarRepository();

  final StarRepository _repository;

  // 按类型分开存储，便于分页
  List<Knowledge> _knowledge = const [];
  List<Persona> _personas = const [];
  int _knowledgePage = 1;
  int _personaPage = 1;
  bool _knowledgeHasMore = true;
  bool _personaHasMore = true;
  final int _pageSize = 20;

  bool _isLoading = false;
  String? _errorMessage;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  List<Knowledge> get knowledge => _knowledge;
  List<Persona> get personas => _personas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _knowledge.isEmpty && _personas.isEmpty;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  bool get knowledgeHasMore => _knowledgeHasMore;
  bool get personaHasMore => _personaHasMore;
  bool get isBusy => _isLoading;

  Future<void> refresh({String type = 'knowledge'}) async {
    if (type == 'knowledge') {
      _knowledgePage = 1;
      _knowledge = [];
      _knowledgeHasMore = true;
    } else {
      _personaPage = 1;
      _personas = [];
      _personaHasMore = true;
    }
    await _load(type: type, reset: true);
  }

  Future<void> loadMore({String type = 'knowledge'}) async {
    if (_isLoading) return;
    final hasMore = type == 'knowledge' ? _knowledgeHasMore : _personaHasMore;
    if (!hasMore) return;
    await _load(type: type, reset: false);
  }

  Future<void> changeSort({required String sortBy, required String sortOrder}) async {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _knowledgePage = 1;
    _personaPage = 1;
    _knowledge = [];
    _personas = [];
    _knowledgeHasMore = true;
    _personaHasMore = true;
    await _load(type: 'knowledge', reset: true);
    await _load(type: 'persona', reset: true);
  }

  Future<void> _load({required String type, bool reset = false}) async {
    _isLoading = true;
    if (reset) {
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final nextPage = type == 'knowledge' ? _knowledgePage : _personaPage;
      final result = await _repository.fetchStars(
        includeDetails: true,
        page: nextPage,
        pageSize: _pageSize,
        type: type,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (type == 'knowledge') {
        if (reset) _knowledge = [];
        _knowledge = [..._knowledge, ...result.knowledge];
        _knowledgePage = nextPage + 1;
        _knowledgeHasMore = _knowledge.length < result.total;
      } else {
        if (reset) _personas = [];
        _personas = [..._personas, ...result.personas];
        _personaPage = nextPage + 1;
        _personaHasMore = _personas.length < result.total;
      }
      _errorMessage = null;
    } on ApiServiceError catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> init() async {
    await _load(type: 'knowledge', reset: true);
    await _load(type: 'persona', reset: true);
  }

  Future<void> unstarKnowledge(String knowledgeId) async {
    try {
      await KnowledgeApi().unstar(knowledgeId);
      await refresh(type: 'knowledge');
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> unstarPersona(String personaId) async {
    try {
      await PersonaApi().unstar(personaId);
      await refresh(type: 'persona');
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }
}


