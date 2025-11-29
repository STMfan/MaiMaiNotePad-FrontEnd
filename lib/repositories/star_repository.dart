import '../models/knowledge.dart';
import '../models/persona.dart';
import '../services/api/knowledge_api.dart';
import '../services/api/persona_api.dart';
import '../services/api/star_api.dart';

class StarredContent {
  final List<Knowledge> knowledge;
  final List<Persona> personas;
  final int total;
  final int page;
  final int pageSize;

  const StarredContent({
    required this.knowledge,
    required this.personas,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get isEmpty => knowledge.isEmpty && personas.isEmpty;
  bool get hasMore => knowledge.length + personas.length < total;
}

class StarRepository {
  StarRepository({
    StarApi? starApi,
    KnowledgeApi? knowledgeApi,
    PersonaApi? personaApi,
  })  : _starApi = starApi ?? StarApi(),
        _knowledgeApi = knowledgeApi ?? KnowledgeApi(),
        _personaApi = personaApi ?? PersonaApi();

  final StarApi _starApi;
  final KnowledgeApi _knowledgeApi;
  final PersonaApi _personaApi;

  Future<StarredContent> fetchStars({
    bool includeDetails = true,
    int page = 1,
    int pageSize = 20,
    String type = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final response = await _starApi.fetchUserStars(
      includeDetails: includeDetails,
      page: page,
      pageSize: pageSize,
      type: type,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );

    final stars = response['items'] as List<dynamic>? ?? const [];
    final total = response['total'] as int? ?? stars.length;
    final currentPage = response['page'] as int? ?? page;
    final currentPageSize = response['page_size'] as int? ?? pageSize;

    final knowledgeIds = <String>[];
    final personaIds = <String>[];
    final knowledgeItems = <Knowledge>[];
    final personaItems = <Persona>[];

    for (final star in stars) {
      if (star is! Map<String, dynamic>) {
        continue;
      }
      final type = star['type']?.toString();
      final targetId = star['target_id']?.toString();

      if (targetId == null) {
        continue;
      }

      if (type == 'knowledge') {
        knowledgeIds.add(targetId);
        if (includeDetails) {
          try {
            knowledgeItems.add(Knowledge.fromJson(star));
          } catch (_) {}
        }
      } else if (type == 'persona') {
        personaIds.add(targetId);
        if (includeDetails) {
          try {
            personaItems.add(Persona.fromJson(star));
          } catch (_) {}
        }
      }
    }

    if (!includeDetails) {
      for (final id in knowledgeIds) {
        try {
          final detail = await _knowledgeApi.fetchDetail(id);
          knowledgeItems.add(detail);
        } catch (_) {}
      }
      for (final id in personaIds) {
        try {
          final detail = await _personaApi.fetchDetail(id);
          personaItems.add(detail);
        } catch (_) {}
      }
    }

    return StarredContent(
      knowledge: knowledgeItems,
      personas: personaItems,
      total: total,
      page: currentPage,
      pageSize: currentPageSize,
    );
  }
}


