import 'package:dio/dio.dart';

import '../../models/persona.dart';
import '../core/api_error.dart';
import '../core/http_client_factory.dart';

class PersonaApi {
  PersonaApi({HttpClientFactory? clientFactory})
      : _clientFactory = clientFactory ?? HttpClientFactory();

  final HttpClientFactory _clientFactory;

  Future<Persona> fetchDetail(String personaId) async {
    final dio = await _clientFactory.getClient();
    try {
      final response = await dio.get('/api/persona/$personaId');
      final data = _unwrap(response.data);
      return Persona.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<bool> isStarred(String personaId) async {
    final dio = await _clientFactory.getClient();
    try {
      final response = await dio.get('/api/persona/$personaId/starred');
      final payload = _unwrap(response.data);
      if (payload is Map<String, dynamic>) {
        return payload['starred'] as bool? ?? false;
      }
      return false;
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> star(String personaId) async {
    final dio = await _clientFactory.getClient();
    try {
      await dio.post('/api/persona/$personaId/star');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> unstar(String personaId) async {
    final dio = await _clientFactory.getClient();
    try {
      await dio.delete('/api/persona/$personaId/star');
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


