import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/knowledge.dart';
import '../models/persona.dart';

class ApiService {
  late Dio _dio;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _initDio();
  }

  void _initDio() async {
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
        validateStatus: (status) =>
            status != null && status < 500, // 接受所有非500错误
      ),
    );

    // 添加拦截器，自动添加token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
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
          }
          handler.next(error);
        },
      ),
    );
  }

  // 更新API基础URL
  Future<void> updateBaseUrl(String newBaseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.apiBaseUrlKey, newBaseUrl);
    _initDio(); // 重新初始化Dio
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
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      // 处理响应格式不匹配问题
      // 如果后端直接返回数据（没有success/data包装），则包装成统一格式
      if (response.data is List ||
          (response.data is Map && !response.data.containsKey('success'))) {
        response.data = {'success': true, 'data': response.data};
      }

      return response;
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
    try {
      final options = Options(
        responseType: responseType,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json, text/plain, */*', // 接受多种响应类型
        },
      );
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      // 处理响应格式不匹配问题
      // 如果后端直接返回数据（没有success/data包装），则包装成统一格式
      if (response.data is List ||
          (response.data is Map && !response.data.containsKey('success'))) {
        response.data = {'success': true, 'data': response.data};
      }

      return response;
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
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      // 处理响应格式不匹配问题
      // 如果后端直接返回数据（没有success/data包装），则包装成统一格式
      if (response.data is List ||
          (response.data is Map && !response.data.containsKey('success'))) {
        response.data = {'success': true, 'data': response.data};
      }

      return response;
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
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
      );

      // 处理响应格式不匹配问题
      // 如果后端直接返回数据（没有success/data包装），则包装成统一格式
      if (response.data is List ||
          (response.data is Map && !response.data.containsKey('success'))) {
        response.data = {'success': true, 'data': response.data};
      }

      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 文件上传
  Future<Response> upload(String path, FormData formData) async {
    try {
      return await _dio.post(path, data: formData);
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

      final response = await _dio.post(path, data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 错误处理
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (error.response?.data is Map<String, dynamic>) {
          final data = error.response!.data as Map<String, dynamic>;
          final message = data['message'] ?? data['error'] ?? '服务器错误';
          return '错误码: $statusCode - $message';
        }
        return '错误码: $statusCode - 服务器错误';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.connectionError:
        return '网络连接错误';
      case DioExceptionType.badCertificate:
        return '证书错误';
      case DioExceptionType.unknown:
        return '未知错误: ${error.message}';
    }
  }

  // 获取用户Star的知识库和人设卡
  Future<Map<String, dynamic>> getUserStars(String token) async {
    try {
      final response = await get('/user/stars');
      final data = response.data;

      // 解析知识库列表
      final List<dynamic> knowledgeList = data['knowledge'] ?? [];
      final List<Knowledge> knowledgeItems = knowledgeList
          .map((item) => Knowledge.fromJson(item))
          .toList();

      // 解析人设卡列表
      final List<dynamic> personaList = data['personas'] ?? [];
      final List<Persona> personaItems = personaList
          .map((item) => Persona.fromJson(item))
          .toList();

      return {'knowledge': knowledgeItems, 'personas': personaItems};
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
      final response = await get('/knowledge/$knowledgeId');
      return Knowledge.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取人设卡详情
  Future<Persona> getPersonaDetail(String personaId, String? token) async {
    try {
      final response = await get('/persona/$personaId');
      return Persona.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 检查知识库是否已Star
  Future<bool> isKnowledgeStarred(String knowledgeId, String? token) async {
    try {
      // 注意：这里假设后端有一个检查是否已star的接口
      // 如果没有，可能需要通过获取用户Star列表来判断
      final response = await get('/knowledge/$knowledgeId/starred');
      return response.data['starred'] ?? false;
    } on DioException catch (e) {
      // 如果接口不存在，假设未star
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _handleError(e);
    }
  }

  // 检查人设卡是否已Star
  Future<bool> isPersonaStarred(String personaId, String? token) async {
    try {
      // 注意：这里假设后端有一个检查是否已star的接口
      // 如果没有，可能需要通过获取用户Star列表来判断
      final response = await get('/persona/$personaId/starred');
      return response.data['starred'] ?? false;
    } on DioException catch (e) {
      // 如果接口不存在，假设未star
      if (e.response?.statusCode == 404) {
        return false;
      }
      throw _handleError(e);
    }
  }

  // Star知识库
  Future<void> starKnowledge(String knowledgeId, String? token) async {
    try {
      await post('/knowledge/$knowledgeId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 取消Star知识库
  Future<void> unstarKnowledge(String knowledgeId, String? token) async {
    try {
      await delete('/knowledge/$knowledgeId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Star人设卡
  Future<void> starPersona(String personaId, String? token) async {
    try {
      await post('/persona/$personaId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 取消Star人设卡
  Future<void> unstarPersona(String personaId, String? token) async {
    try {
      await delete('/persona/$personaId/star');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取公开知识库列表
  Future<List<Knowledge>> getPublicKnowledge({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await get(
        '/knowledge/public',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> dataList = response.data;
      return dataList.map((item) => Knowledge.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取公开人设卡列表
  Future<List<Persona>> getPublicPersonas({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await get(
        '/persona/public',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> dataList = response.data;
      return dataList.map((item) => Persona.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取用户知识库列表
  Future<List<Knowledge>> getUserKnowledge(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await get(
        '/knowledge/user/$userId',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> dataList = response.data;
      return dataList.map((item) => Knowledge.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取用户人设卡列表
  Future<List<Persona>> getUserPersonas(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await get(
        '/persona/user/$userId',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> dataList = response.data;
      return dataList.map((item) => Persona.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取当前用户信息
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await get('/users/me');
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
        '/knowledge/upload',
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
        '/persona/upload',
        filePaths,
        metadata: metadata,
      );
      return Persona.fromJson(responseData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取待审核知识库
  Future<List<Knowledge>> getPendingKnowledge({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await get(
        '/review/knowledge/pending',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> dataList = response.data;
      return dataList.map((item) => Knowledge.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取待审核人设卡
  Future<List<Persona>> getPendingPersonas({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await get(
        '/review/persona/pending',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List<dynamic> dataList = response.data;
      return dataList.map((item) => Persona.fromJson(item)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核通过知识库
  Future<void> approveKnowledge(String knowledgeId) async {
    try {
      await post('/review/knowledge/$knowledgeId/approve');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核拒绝知识库
  Future<void> rejectKnowledge(String knowledgeId, {String? reason}) async {
    try {
      await post(
        '/review/knowledge/$knowledgeId/reject',
        data: {'reason': reason ?? ''},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核通过人设卡
  Future<void> approvePersona(String personaId) async {
    try {
      await post('/review/persona/$personaId/approve');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 审核拒绝人设卡
  Future<void> rejectPersona(String personaId, {String? reason}) async {
    try {
      await post(
        '/review/persona/$personaId/reject',
        data: {'reason': reason ?? ''},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 发送消息
  Future<void> sendMessage({
    required String recipientId,
    required String content,
    String? subject,
  }) async {
    try {
      await post(
        '/messages/send',
        data: {
          'recipientId': recipientId,
          'content': content,
          'subject': subject ?? '',
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 获取用户消息
  Future<List<dynamic>> getUserMessages({int page = 1, int limit = 20}) async {
    try {
      final response = await get(
        '/messages',
        queryParameters: {'page': page, 'limit': limit},
      );

      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // 标记消息为已读
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await post('/messages/$messageId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
