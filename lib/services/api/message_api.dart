import 'package:dio/dio.dart';

import '../../models/message.dart';
import '../core/api_error.dart';
import '../core/http_client_factory.dart';

class MessageApi {
  MessageApi({HttpClientFactory? clientFactory})
      : _clientFactory = clientFactory ?? HttpClientFactory();

  final HttpClientFactory _clientFactory;

  Future<Message> fetchDetail(String messageId) async {
    final dio = await _clientFactory.getClient();
    try {
      final response = await dio.get('/api/messages/$messageId');
      final data = _unwrap(response.data);
      return Message.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> markAsRead(String messageId) async {
    final dio = await _clientFactory.getClient();
    try {
      await dio.post('/api/messages/$messageId/read');
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final dio = await _clientFactory.getClient();
    try {
      await dio.delete('/api/messages/$messageId');
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


