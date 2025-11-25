import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/delete_knowledge_file_result.dart';
import '../models/knowledge.dart';
import '../models/persona.dart';
import '../models/paginated_response.dart';
import 'core/api_error.dart';
import 'core/session_store.dart';

class ApiService {
  Dio? _dio;
  Completer<void>? _initCompleter;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _initDio();
  }

  Future<void> _initDio() async {
    // 如果已经在初始化中，等待完成
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    // 如果已经初始化完成，直接返回
    if (_dio != null) {
      return;
    }

    // 创建新的 Completer
    _initCompleter = Completer<void>();

    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl =
          prefs.getString(AppConstants.apiBaseUrlKey) ?? AppConstants.apiBaseUrl;

      _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json', // 明确指定接受JSON响应
          },
          responseType: ResponseType.json, // 尝试自动解析JSON
          // 让 4xx 直接抛出 DioException，避免被误当作成功
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      // 添加拦截器，自动添加token
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // 每次请求时重新获取 SharedPreferences 实例，确保读取到最新的 token
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString(AppConstants.tokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (error, handler) async {
            // 如果是401错误，清除本地存储的token
            if (error.response?.statusCode == 401) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(AppConstants.tokenKey);
              await prefs.remove(AppConstants.userIdKey);
              await prefs.remove(AppConstants.userNameKey);
              await prefs.remove(AppConstants.userRoleKey);
              SessionStore.onUnauthorized?.call();
            }
            handler.next(error);
          },
        ),
      );

      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  // 确保 Dio 已初始化
  Future<void> _ensureInitialized() async {
    if (_dio == null) {
      await _initDio();
    }
  }

  // 统一处理响应格式：如果后端直接返回数据（没有success/data包装），则包装成统一格式
  Response _normalizeResponse(Response response) {
    if (response.data is List ||
        (response.data is Map && !response.data.containsKey('success'))) {
      response.data = {'success': true, 'data': response.data};
    }
    return response;
  }

  // 更新API基础URL
  Future<void> updateBaseUrl(String newBaseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.apiBaseUrlKey, newBaseUrl);
    _dio = null;
    _initCompleter = null;
    await _initDio(); // 重新初始化Dio
  }

  // 获取当前API基础URL
  Future<String> getCurrentBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.apiBaseUrlKey) ??
        AppConstants.apiBaseUrl;
  }

  // GET请求
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _dio!.get(path, queryParameters: queryParameters);
      return _normalizeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST请求
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    ResponseType? responseType,
  }) async {
    await _ensureInitialized();
    try {
      final options = Options(
        responseType: responseType,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*', // 接受多种响应类型
        },
      );
      final response = await _dio!.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return _normalizeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT请求
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _dio!.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _normalizeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE请求
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _ensureInitialized();
    try {
      final response = await _dio!.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _normalizeResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 文件上传
  Future<Response> upload(String path, FormData formData) async {
    await _ensureInitialized();
    try {
      return await _dio!.post(path, data: formData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 多文件上传
  Future<Map<String, dynamic>> uploadFiles(
    String path,
    List<String> filePaths, {
    Map<String, dynamic>? metadata,
  }) async {
    await _ensureInitialized();
    try {
      FormData formData = FormData();

      // 添加文件
      for (int i = 0; i < filePaths.length; i++) {
        String filePath = filePaths[i];
        String fileName = filePath.split('/').last;
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(filePath, filename: fileName),
          ),
        );
      }

      // 添加元数据
      if (metadata != null) {
        metadata.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _dio!.post(path, data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 辅助方法：从响应中提取列表数据
  // 处理响应格式：可能是直接列表，也可能是包装后的格式
  List<dynamic> _extractListFromResponse(Response response) {
    if (response.data is List) {
      return response.data;
    } else if (response.data is Map && response.data.containsKey('data')) {
      final data = response.data['data'];
      if (data is List) {
        return data;
      }
    }
    return [];
  }

  // 错误处理
  ApiServiceError _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiServiceError(
          type: 'CONNECTION_TIMEOUT',
          message: '连接超时，请检查网络后重试',
        );
      case DioExceptionType.sendTimeout:
        return ApiServiceError(
          type: 'SEND_TIMEOUT',
          message: '请求发送超时，请稍后重试',
        );
      case DioExceptionType.receiveTimeout:
        return ApiServiceError(
          type: 'RECEIVE_TIMEOUT',
          message: '服务器响应超时，请稍后重试',
        );
      case DioExceptionType.badResponse:
        return _buildResponseError(error);
      case DioExceptionType.cancel:
        return ApiServiceError(
          type: 'CANCELLED',
          message: '请求已取消',
        );
      case DioExceptionType.connectionError:
        return ApiServiceError(
          type: 'NETWORK_ERROR',
          message: '网络连接异常，请检查网络状态',
        );
      case DioExceptionType.badCertificate:
        return ApiServiceError(
          type: 'BAD_CERTIFICATE',
          message: '证书校验失败，请联系管理员',
        );
      case DioExceptionType.unknown:
        return ApiServiceError(
          type: 'UNKNOWN',
          message: '未知错误: ${error.message ?? '请稍后再试'}',
        );
    }
  }

  ApiServiceError _buildResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final payload = _normalizeErrorPayload(error.response?.data);

    String message = _fallbackMessageForStatus(statusCode);
    String? errorType;
    String? requestId;
    String? errorCode;
    dynamic details;

    if (payload != null) {
      final embeddedError = payload['error'];

      if (embeddedError is Map<String, dynamic>) {
        message = _pickFirstNonEmpty([
              embeddedError['message'],
              embeddedError['detail'],
              payload['message'],
              payload['detail'],
              payload['error_description'],
            ]) ??
            message;
        errorType =
            (embeddedError['type'] ?? payload['error_type'])?.toString();
        requestId = (embeddedError['request_id'] ??
                embeddedError['requestId'] ??
                payload['request_id'] ??
                payload['requestId'])
            ?.toString();
        errorCode = (embeddedError['code'] ??
                embeddedError['error_code'] ??
                payload['code'] ??
                payload['error_code'])
            ?.toString();
        details = embeddedError['details'] ?? payload['details'];
      } else if (embeddedError is String && embeddedError.trim().isNotEmpty) {
        message = embeddedError;
      } else {
        message = _pickFirstNonEmpty([
              payload['message'],
              payload['detail'],
              payload['error'],
              payload['error_description'],
            ]) ??
            message;
        errorType = payload['error_type']?.toString();
        requestId =
            (payload['request_id'] ?? payload['requestId'])?.toString();
        errorCode = (payload['code'] ?? payload['error_code'])?.toString();
        details = payload['details'];
      }
    }

    return ApiServiceError(
      statusCode: statusCode,
      message: message,
      type: errorType,
      requestId: requestId,
      errorCode: errorCode,
      details: details,
      raw: payload,
    );
  }

  Map<String, dynamic>? _normalizeErrorPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = json.decode(data);
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        // 忽略解析失败，回退到默认文案
      }
    }
    return null;
  }

  String? _pickFirstNonEmpty(List<dynamic> candidates) {
    for (final candidate in candidates) {
      if (candidate == null) continue;
      final text = candidate.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _fallbackMessageForStatus(int? statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数有误，请检查输入';
      case 401:
        return '未授权或登录已过期，请重新登录';
      case 403:
        return '无访问权限，请联系管理员';
      case 404:
        return '请求的资源不存在';
      case 409:
        return '当前操作与现有数据冲突';
      case 422:
        return '请求数据校验失败，请检查后重试';
      case 429:
        return '请求过于频繁，请稍后再试';
      default:
        return '服务器错误，请稍后再试';
    }
  }

  // 获取用户Star的知识库和人设卡
  // 注意：后端返回的是一个列表，每个元素包含 type 和 target_id
  Future<Map<String, dynamic>> getUserStars(String token, {bool includeDetails = false}) async {
    try {
      // 使用include_details参数获取完整信息
      final response = await get('/api/user/stars?include_details=$includeDetails');
      // 使用统一的列表提取方法
      final List<dynamic> starsList = _extractListFromResponse(response);

      final List<String> knowledgeIds = [];
      final List<String> personaIds = [];
      final List<Knowledge> knowledgeItems = [];
      final List<Persona> personaItems = [];

      for (var star in starsList) {
        if (star is Map<String, dynamic>) {
          final type = star['type'] as String?;
          final targetId = star['target_id'] as String?;
          if (targetId != null) {
            if (type == 'knowledge') {
              knowledgeIds.add(targetId);
              // 如果包含详情，直接解析
              if (includeDetails) {
                try {
                  final kb = Knowledge.fromJson(star);
                  knowledgeItems.add(kb);
                } catch (e) {
                  debugPrint('Failed to parse knowledge: $e');
                }
              }
            } else if (type == 'persona') {
              personaIds.add(targetId);
              // 如果包含详情，直接解析
              if (includeDetails) {
                try {
                  final pc = Persona.fromJson(star);
                  personaItems.add(pc);
                } catch (e) {
                  debugPrint('Failed to parse persona: $e');
                }
              }
            }
          }
        }
      }

      // 如果不包含详情，需要单独获取（保持向后兼容）
      if (!includeDetails) {
      for (var id in knowledgeIds) {
        try {
          final kb = await getKnowledgeDetail(id, token);
          knowledgeItems.add(kb);
        } catch (e) {
          debugPrint('Failed to get knowledge detail for $id: $e');
        }
      }

      for (var id in personaIds) {
        try {
          final pc = await getPersonaDetail(id, token);
          personaItems.add(pc);
        } catch (e) {
          debugPrint('Failed to get persona detail for $id: $e');
          }
        }
      }

      return {
        'knowledge': knowledgeItems,
        'personas': personaItems,
        'knowledgeIds': knowledgeIds,
        'personaIds': personaIds,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取知识库详情
  Future<Knowledge> getKnowledgeDetail(
    String knowledgeId,
    String? token,
  ) async {
    try {
      final response = await get('/api/knowledge/$knowledgeId');
      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      // 调试信息
      if (kDebugMode) {
        debugPrint('Knowledge detail response data: $data');
      }
      
      return Knowledge.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting knowledge detail: $e');
        debugPrint('Response: ${e.response?.data}');
      }
      throw _handleError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error getting knowledge detail: $e');
      }
      rethrow;
    }
  }

  // 获取人设卡详情
  Future<Persona> getPersonaDetail(String personaId, String? token) async {
    try {
      final response = await get('/api/persona/$personaId');
      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      // 调试信息
      if (kDebugMode) {
        debugPrint('Persona detail response data: $data');
      }
      
      return Persona.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting persona detail: $e');
        debugPrint('Response: ${e.response?.data}');
      }
      throw _handleError(e);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected error getting persona detail: $e');
      }
      rethrow;
    }
  }

  // 检查知识库是否已Star
  Future<bool> isKnowledgeStarred(String knowledgeId, String? token) async {
    try {
      // 如果没有token，返回false
      if (token == null) {
        return false;
      }
      // 使用新的专门接口
      final response = await get('/api/knowledge/$knowledgeId/starred');
      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      if (responseData is Map<String, dynamic>) {
        return responseData['starred'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      // 如果获取失败，假设未star
      if (kDebugMode) {
        debugPrint('检查知识库收藏状态失败: $e');
      }
      return false;
    }
  }

  // 检查人设卡是否已Star
  Future<bool> isPersonaStarred(String personaId, String? token) async {
    try {
      // 如果没有token，返回false
      if (token == null) {
        return false;
      }
      // 使用新的专门接口
      final response = await get('/api/persona/$personaId/starred');
      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      if (responseData is Map<String, dynamic>) {
        return responseData['starred'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      // 如果获取失败，假设未star
      if (kDebugMode) {
        debugPrint('检查人设卡收藏状态失败: $e');
      }
      return false;
    }
  }

  // Star知识库
  Future<void> starKnowledge(String knowledgeId, String? token) async {
    try {
      await post('/api/knowledge/$knowledgeId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 取消Star知识库
  Future<void> unstarKnowledge(String knowledgeId, String? token) async {
    try {
      await delete('/api/knowledge/$knowledgeId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Star人设卡
  Future<void> starPersona(String personaId, String? token) async {
    try {
      await post('/api/persona/$personaId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 取消Star人设卡
  Future<void> unstarPersona(String personaId, String? token) async {
    try {
      await delete('/api/persona/$personaId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取公开知识库列表
  Future<PaginatedResponse<Knowledge>> getPublicKnowledge({
    int page = 1,
    int pageSize = 20,
    String? name,
    String? uploaderId,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await get(
        '/api/knowledge/public',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (name != null) 'name': name,
          if (uploaderId != null) 'uploader_id': uploaderId,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );

      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final Map<String, dynamic> responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      // 调试：打印原始响应数据
      if (kDebugMode) {
        debugPrint('=== getPublicKnowledge 响应数据 ===');
        debugPrint('Raw response data: ${response.data}');
        debugPrint('Extracted data: $responseData');
        debugPrint('Items count: ${(responseData['items'] as List?)?.length ?? 0}');
        debugPrint('Total: ${responseData['total']}');
        debugPrint('Page: ${responseData['page']}');
        debugPrint('Page size: ${responseData['page_size']}');
        debugPrint('=====================================');
      }
      
      return PaginatedResponse.fromJson(
        responseData,
        (json) => Knowledge.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取公开人设卡列表
  Future<PaginatedResponse<Persona>> getPublicPersonas({
    int page = 1,
    int pageSize = 20,
    String? name,
    String? uploaderId,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await get(
        '/api/persona/public',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (name != null) 'name': name,
          if (uploaderId != null) 'uploader_id': uploaderId,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );

      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final Map<String, dynamic> responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      // 调试：打印原始响应数据
      if (kDebugMode) {
        debugPrint('=== getPublicPersonas 响应数据 ===');
        debugPrint('Raw response data: ${response.data}');
        debugPrint('Extracted data: $responseData');
        debugPrint('Items count: ${(responseData['items'] as List?)?.length ?? 0}');
        debugPrint('Total: ${responseData['total']}');
        debugPrint('Page: ${responseData['page']}');
        debugPrint('Page size: ${responseData['page_size']}');
        debugPrint('=====================================');
      }
      
      return PaginatedResponse.fromJson(
        responseData,
        (json) => Persona.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取用户知识库列表
  Future<PaginatedResponse<Knowledge>> getUserKnowledge(
    String userId, {
    int page = 1,
    int pageSize = 20,
    String? name,
    String? tag,
    String status = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await get(
        '/api/knowledge/user/$userId',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (name != null && name.isNotEmpty) 'name': name,
          if (tag != null && tag.isNotEmpty) 'tag': tag,
          'status': status,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );
      final Map<String, dynamic> data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return PaginatedResponse.fromJson(
        data,
        (json) => Knowledge.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取用户人设卡列表
  Future<PaginatedResponse<Persona>> getUserPersonas(
    String userId, {
    int page = 1,
    int pageSize = 20,
    String? name,
    String? tag,
    String status = 'all',
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await get(
        '/api/persona/user/$userId',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (name != null && name.isNotEmpty) 'name': name,
          if (tag != null && tag.isNotEmpty) 'tag': tag,
          'status': status,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );

      final Map<String, dynamic> data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return PaginatedResponse.fromJson(
        data,
        (json) => Persona.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await get('/api/users/me');
      // 处理响应数据：如果被包装在 data 字段中，则提取 data 字段
      if (response.data is Map<String, dynamic> && 
          response.data.containsKey('data') && 
          response.data.containsKey('success')) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 修改密码
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await put(
        '/api/users/me/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 上传头像
  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    try {
      await _ensureInitialized();
      FormData formData = FormData();
      
      // 根据平台选择文件处理方式
      if (kIsWeb) {
        // Web平台需要先读取文件为bytes
        // 注意：这里假设filePath在Web平台实际上是文件对象
        // 实际使用时可能需要调整
        throw UnimplementedError('Web平台头像上传需要特殊处理');
      } else {
        // 其他平台使用文件路径
        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(filePath, filename: filePath.split('/').last),
          ),
        );
      }
      
      final response = await _dio!.post('/api/users/me/avatar', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 上传头像（使用MultipartFile，支持Web平台）
  Future<Map<String, dynamic>> uploadAvatarFile(MultipartFile file) async {
    try {
      await _ensureInitialized();
      FormData formData = FormData();
      formData.files.add(MapEntry('avatar', file));
      
      final response = await _dio!.post('/api/users/me/avatar', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 删除头像
  Future<Map<String, dynamic>> deleteAvatar() async {
    try {
      final response = await delete('/api/users/me/avatar');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 上传知识库
  Future<Knowledge> uploadKnowledge({
    required String name,
    required String description,
    required List<String> filePaths,
    String? content,
    List<String>? tags,
    bool isPublic = false,
  }) async {
    try {
      final metadata = {
        'name': name,
        'description': description,
        'content': content ?? '',
        'tags': tags?.join(',') ?? '',
        'isPublic': isPublic.toString(),
      };

      final responseData = await uploadFiles(
        '/api/knowledge/upload',
        filePaths,
        metadata: metadata,
      );
      return Knowledge.fromJson(responseData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 上传人设卡
  Future<Persona> uploadPersona({
    required String name,
    required String description,
    required String content,
    required List<String> filePaths,
    List<String>? tags,
    bool isPublic = false,
  }) async {
    try {
      final metadata = {
        'name': name,
        'description': description,
        'content': content,
        'tags': tags?.join(',') ?? '',
        'isPublic': isPublic.toString(),
      };

      final responseData = await uploadFiles(
        '/api/persona/upload',
        filePaths,
        metadata: metadata,
      );
      return Persona.fromJson(responseData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取待审核知识库
  Future<PaginatedResponse<Knowledge>> getPendingKnowledge({
    int page = 1,
    int pageSize = 20,
    String? name,
    String? uploaderId,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await get(
        '/api/review/knowledge/pending',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (name != null) 'name': name,
          if (uploaderId != null) 'uploader_id': uploaderId,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );

      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final Map<String, dynamic> responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      // 调试：打印原始响应数据
      if (kDebugMode) {
        debugPrint('=== getPendingKnowledge 响应数据 ===');
        debugPrint('Raw response data: ${response.data}');
        debugPrint('Extracted data: $responseData');
        debugPrint('Items count: ${(responseData['items'] as List?)?.length ?? 0}');
        debugPrint('Total: ${responseData['total']}');
        debugPrint('Page: ${responseData['page']}');
        debugPrint('Page size: ${responseData['page_size']}');
        
        // 检查 items 数组中每个对象的 created_at 字段格式
        final List<dynamic>? itemsList = responseData['items'] as List<dynamic>?;
        if (itemsList != null && itemsList.isNotEmpty) {
          debugPrint('--- 检查第一个 item 的字段格式 ---');
          final firstItem = itemsList[0] as Map<String, dynamic>?;
          if (firstItem != null) {
            debugPrint('First item keys: ${firstItem.keys.toList()}');
            debugPrint('First item id: ${firstItem['id']}');
            debugPrint('First item name: ${firstItem['name']}');
            debugPrint('First item created_at: ${firstItem['created_at']} (type: ${firstItem['created_at']?.runtimeType})');
            debugPrint('First item updated_at: ${firstItem['updated_at']} (type: ${firstItem['updated_at']?.runtimeType})');
            debugPrint('First item file_names: ${firstItem['file_names']} (type: ${firstItem['file_names']?.runtimeType})');
          }
        }
        debugPrint('=====================================');
      }
      
      return PaginatedResponse.fromJson(
        responseData,
        (json) => Knowledge.fromJson(json),
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('getPendingKnowledge DioException: $e');
        debugPrint('Response: ${e.response?.data}');
      }
      throw _handleError(e);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('getPendingKnowledge Unexpected error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  // 获取待审核人设卡
  Future<PaginatedResponse<Persona>> getPendingPersonas({
    int page = 1,
    int pageSize = 20,
    String? name,
    String? uploaderId,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      final response = await get(
        '/api/review/persona/pending',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (name != null) 'name': name,
          if (uploaderId != null) 'uploader_id': uploaderId,
          'sort_by': sortBy,
          'sort_order': sortOrder,
        },
      );

      // 处理响应格式：可能是 {'success': true, 'data': {...}} 或直接 {...}
      final Map<String, dynamic> responseData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      
      // 调试：打印原始响应数据
      if (kDebugMode) {
        debugPrint('=== getPendingPersonas 响应数据 ===');
        debugPrint('Raw response data: ${response.data}');
        debugPrint('Extracted data: $responseData');
        debugPrint('Items count: ${(responseData['items'] as List?)?.length ?? 0}');
        debugPrint('Total: ${responseData['total']}');
        debugPrint('Page: ${responseData['page']}');
        debugPrint('Page size: ${responseData['page_size']}');
        debugPrint('=====================================');
      }
      
      return PaginatedResponse.fromJson(
        responseData,
        (json) => Persona.fromJson(json),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核通过知识库
  Future<void> approveKnowledge(String knowledgeId) async {
    try {
      await post('/api/review/knowledge/$knowledgeId/approve');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核拒绝知识库
  Future<void> rejectKnowledge(String knowledgeId, {String? reason}) async {
    try {
      await post(
        '/api/review/knowledge/$knowledgeId/reject',
        data: {'reason': reason ?? ''},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核通过人设卡
  Future<void> approvePersona(String personaId) async {
    try {
      await post('/api/review/persona/$personaId/approve');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核拒绝人设卡
  Future<void> rejectPersona(String personaId, {String? reason}) async {
    try {
      await post(
        '/api/review/persona/$personaId/reject',
        data: {'reason': reason ?? ''},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 发送消息
  Future<void> sendMessage({
    required String title,
    required String content,
    String? summary,
    String? recipientId,
    List<String>? recipientIds,
    bool asAnnouncement = false,
    bool broadcastAll = false,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'title': title,
        'content': content,
        'message_type': asAnnouncement ? 'announcement' : 'direct',
      };

      if (summary != null && summary.isNotEmpty) {
        payload['summary'] = summary;
      }

      if (recipientId != null) {
        payload['recipient_id'] = recipientId;
      }

      if (recipientIds != null && recipientIds.isNotEmpty) {
        payload['recipient_ids'] = recipientIds;
      }

      if (broadcastAll) {
        payload['broadcast_scope'] = 'all_users';
      }

      await post(
        '/api/messages/send',
        data: payload,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取广播消息历史（管理员和审核员）
  Future<Map<String, dynamic>> getBroadcastMessages({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final offset = (page - 1) * limit;
      final queryParameters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };

      final response = await get(
        '/api/admin/broadcast-messages',
        queryParameters: queryParameters,
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取消息详情
  Future<Map<String, dynamic>> getMessageDetail(String messageId) async {
    try {
      final response = await get('/api/messages/$messageId');
      if (response.data is Map && response.data.containsKey('data')) {
        return response.data['data'];
      }
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取用户消息
  // 注意：后端使用 offset 和 limit，而不是 page
  Future<List<dynamic>> getUserMessages({
    int page = 1,
    int limit = 50,
    String? otherUserId,
  }) async {
    try {
      final offset = (page - 1) * limit;
      final queryParameters = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (otherUserId != null) {
        queryParameters['other_user_id'] = otherUserId;
      }

      final response = await get(
        '/api/messages',
        queryParameters: queryParameters,
      );

      return _extractListFromResponse(response);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 标记消息为已读
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await post('/api/messages/$messageId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 删除消息
  Future<void> deleteMessage(String messageId) async {
    try {
      await delete('/api/messages/$messageId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 批量删除消息
  Future<Map<String, dynamic>> deleteMessages(List<String> messageIds) async {
    try {
      final response = await post(
        '/api/messages/batch-delete',
        data: messageIds,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 删除知识库
  Future<void> deleteKnowledge(String knowledgeId) async {
    try {
      await delete('/api/knowledge/$knowledgeId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 删除知识库中的单个文件
  Future<DeleteKnowledgeFileResult> deleteKnowledgeFile(
    String knowledgeId,
    String fileId,
  ) async {
    try {
      final response = await delete('/api/knowledge/$knowledgeId/$fileId');
      final payload = response.data;
      final data = payload is Map<String, dynamic>
          ? payload['data'] as Map<String, dynamic>? ?? {}
          : <String, dynamic>{};
      final message = data['message']?.toString() ?? '文件删除成功';
      final knowledgeDeleted = data['knowledge_deleted'] == true;
      return DeleteKnowledgeFileResult(
        message: message,
        knowledgeDeleted: knowledgeDeleted,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 删除人设卡
  Future<void> deletePersona(String personaId) async {
    try {
      await delete('/api/persona/$personaId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 更新知识库
  // 根据API文档：PUT /api/knowledge/{kb_id} 支持 name, description, copyright_owner
  Future<Knowledge> updateKnowledge({
    required String knowledgeId,
    String? name,
    String? description,
    String? copyrightOwner,
    bool? isPublic,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (copyrightOwner != null) data['copyright_owner'] = copyrightOwner;
      if (isPublic != null) data['is_public'] = isPublic;

      final response = await put('/api/knowledge/$knowledgeId', data: data);
      final payload = _unwrapDataPayload(response.data);
      return Knowledge.fromJson(payload);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 更新人设卡
  Future<Persona> updatePersona({
    required String personaId,
    required String name,
    required String description,
    String? copyrightOwner,
  }) async {
    try {
      await _ensureInitialized();
      final formData = FormData.fromMap({
        'name': name,
        'description': description,
        if (copyrightOwner != null) 'copyright_owner': copyrightOwner,
      });
      final response = _normalizeResponse(
        await _dio!.put(
          '/api/persona/$personaId',
          data: formData,
        ),
      );
      final payload = _unwrapDataPayload(response.data);
      return Persona.fromJson(payload);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 提取 data 字段，确保返回 Map 便于反序列化
  Map<String, dynamic> _unwrapDataPayload(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final inner = payload['data'];
      if (inner is Map<String, dynamic>) return inner;
      return payload;
    }
    if (payload is Map) {
      final map = payload.map((key, value) => MapEntry(key.toString(), value));
      final inner = map['data'];
      if (inner is Map<String, dynamic>) return Map<String, dynamic>.from(inner);
      if (inner is Map) {
        return inner.map((key, value) => MapEntry(key.toString(), value));
      }
      return map;
    }
    throw const ApiServiceError(message: '响应格式不正确，未找到可用的数据字段');
  }

  // ========== 用户管理API（仅限admin） ==========

  // 获取所有用户列表
  Future<Response> getAllUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (role != null && role.isNotEmpty) {
        queryParameters['role'] = role;
      }

      return await get('/api/admin/users', queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 更新用户角色
  Future<Response> updateUserRole(String userId, String role) async {
    try {
      return await put(
        '/api/admin/users/$userId/role',
        data: {'role': role},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 删除用户
  Future<Response> deleteUser(String userId) async {
    try {
      return await delete('/api/admin/users/$userId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 创建新用户
  Future<Response> createUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      return await post(
        '/api/admin/users',
        data: {
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ========== 内容管理API（仅限admin） ==========

  // 获取所有知识库（管理员视图）
  Future<Response> getAllKnowledgeBases({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    String? uploader,
    String orderBy = 'created_at',
    String orderDir = 'desc',
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'order_by': orderBy,
        'order_dir': orderDir,
      };
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (uploader != null && uploader.trim().isNotEmpty) {
        queryParameters['uploader'] = uploader.trim();
      }

      return await get('/api/admin/knowledge/all', queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取所有人设卡（管理员视图）
  Future<Response> getAllPersonas({
    int page = 1,
    int limit = 20,
    String? status,
    String? search,
    String? uploader,
    String orderBy = 'created_at',
    String orderDir = 'desc',
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        'order_by': orderBy,
        'order_dir': orderDir,
      };
      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (uploader != null && uploader.trim().isNotEmpty) {
        queryParameters['uploader'] = uploader.trim();
      }

      return await get('/api/admin/persona/all', queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 退回知识库
  Future<Response> revertKnowledgeBase(String kbId, {String? reason}) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        data['reason'] = reason;
      }
      return await post('/api/admin/knowledge/$kbId/revert', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 退回人设卡
  Future<Response> revertPersonaCard(String pcId, {String? reason}) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        data['reason'] = reason;
      }
      return await post('/api/admin/persona/$pcId/revert', data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
