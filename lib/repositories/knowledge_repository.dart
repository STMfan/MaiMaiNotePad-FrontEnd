import '../models/delete_knowledge_file_result.dart';
import '../models/knowledge.dart';
import '../services/api/knowledge_api.dart';

class KnowledgeDetailResult {
  final Knowledge knowledge;
  final bool isStarred;

  const KnowledgeDetailResult({
    required this.knowledge,
    required this.isStarred,
  });
}

class KnowledgeRepository {
  KnowledgeRepository({KnowledgeApi? knowledgeApi})
      : _knowledgeApi = knowledgeApi ?? KnowledgeApi();

  final KnowledgeApi _knowledgeApi;

  Future<KnowledgeDetailResult> loadDetail(String knowledgeId) async {
    final knowledge = await _knowledgeApi.fetchDetail(knowledgeId);
    final isStarred = await _knowledgeApi.isStarred(knowledgeId);
    return KnowledgeDetailResult(knowledge: knowledge, isStarred: isStarred);
  }

  Future<bool> toggleStar({
    required String knowledgeId,
    required bool isStarred,
  }) async {
    if (isStarred) {
      await _knowledgeApi.unstar(knowledgeId);
      return false;
    } else {
      await _knowledgeApi.star(knowledgeId);
      return true;
    }
  }

  Future<DeleteKnowledgeFileResult> deleteFile({
    required String knowledgeId,
    required String fileId,
  }) {
    return _knowledgeApi.deleteFile(knowledgeId, fileId);
  }

  Future<void> deleteKnowledge(String knowledgeId) {
    return _knowledgeApi.deleteKnowledge(knowledgeId);
  }
}

