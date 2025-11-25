import 'package:dio/dio.dart';

import '../core/api_error.dart';
import '../core/http_client_factory.dart';

class StarApi {
  StarApi({HttpClientFactory? clientFactory})
      : _clientFactory = clientFactory ?? HttpClientFactory();

  final HttpClientFactory _clientFactory;

  Future<Map<String, dynamic>> fetchUserStars({
    bool includeDetails = true,
    int page = 1,
    int pageSize = 20,
    String type = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    final dio = await _clientFactory.getClient();
    try {
      final response = await dio.get(
        '/api/user/stars',
        queryParameters: {
          'include_details': includeDetails,
          'page': page,
          'page_size': pageSize,
          'type': type,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );
      final data = response.data;
      // 兼容旧返回（列表）与新返回（带分页信息的Map）
      if (data is List) {
        return {
          'items': data,
          'total': data.length,
          'page': page,
          'page_size': pageSize,
        };
      }
      if (data is Map<String, dynamic>) {
        if (data.containsKey('items')) {
          return data;
        }
        if (data.containsKey('data') && data['data'] is List) {
          final items = data['data'] as List<dynamic>;
          return {
            'items': items,
            'total': items.length,
            'page': page,
            'page_size': pageSize,
          };
        }
      }
      return {
        'items': const [],
        'total': 0,
        'page': page,
        'page_size': pageSize,
      };
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
}


