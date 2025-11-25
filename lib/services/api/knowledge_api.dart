import 'package:dio/dio.dart';

import '../../models/delete_knowledge_file_result.dart';
import '../../models/knowledge.dart';
import '../core/api_error.dart';
import '../core/http_client_factory.dart';

class KnowledgeApi {
  KnowledgeApi({HttpClientFactory? clientFactory})
      : _clientFactory = clientFactory ?? HttpClientFactory();

  final HttpClientFactory _clientFactory;

  Future<Knowledge> fetchDetail(String knowledgeId) async {
    final dio = await _clientFactory.getClient();
    try {
      final response = await dio.get('/api/knowledge/$knowledgeId');
      final data = _unwrap(response.data);
      return Knowledge.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<bool> isStarred(String knowledgeId) async {
    final dio = await _clientFactory.getClient();
    try {
      final response = await dio.get('/api/knowledge/$knowledgeId/starred');
      final payload = _unwrap(response.data);
      if (payload is Map<String, dynamic>) {
        return payload['starred'] as bool? ?? false;
      }
      return false;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> star(String knowledgeId) async {
    final dio = await _clientFactory.getClient();
    try {
      await dio.post('/api/knowledge/$knowledgeId/star');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> unstar(String knowledgeId) async {
    final dio = await _clientFactory.getClient();
    try {
      await dio.delete('/api/knowledge/$knowledgeId/star');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<DeleteKnowledgeFileResult> deleteFile(
    String knowledgeId,
    String fileId,
  ) async {
    final dio = await _clientFactory.getClient();
    try {
      final response = await dio.delete('/api/knowledge/$knowledgeId/$fileId');
      final data = _unwrap(response.data);
      if (data is Map<String, dynamic>) {
        return DeleteKnowledgeFileResult(
          message: data['message']?.toString() ?? '文件删除成功',
          knowledgeDeleted: data['knowledge_deleted'] == true,
        );
      }
      return const DeleteKnowledgeFileResult(
        message: '文件删除成功',
        knowledgeDeleted: false,
      );
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteKnowledge(String knowledgeId) async {
    final dio = await _clientFactory.getClient();
    try {
      await dio.delete('/api/knowledge/$knowledgeId');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  ApiServiceError _mapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = error.response?.data;
    String message = error.message ?? '请求失败，请稍后重试';
    Map<String, dynamic>? raw;

    if (payload is Map<String, dynamic>) {
      raw = payload;
      message = payload['message']?.toString() ??
          payload['error']?.toString() ??
          message;
    } else if (payload is Map) {
      raw = payload.map((key, value) => MapEntry(key.toString(), value));
      message = raw['message']?.toString() ?? message;
    }

    return ApiServiceError(
      statusCode: statusCode,
      message: message,
      raw: raw,
    );
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }
}

