import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // 用户登录
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // 首先尝试JSON响应
      var response = await _apiService.post(
        '/api/token',
        data: {'username': username, 'password': password},
        responseType: ResponseType.json,
      );

      if (response.statusCode == 200) {
        var data = response.data;

        // 如果JSON解析失败，尝试纯文本响应
        if (data == null || data.toString().isEmpty) {
          if (kDebugMode) {
            debugPrint('JSON响应为空，尝试纯文本响应');
          }
          try {
            final plainResponse = await _apiService.post(
              '/api/token',
              data: {'username': username, 'password': password},
              responseType: ResponseType.plain,
            );
            data = plainResponse.data;
            if (kDebugMode) {
              debugPrint('纯文本响应数据: $data');
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('纯文本响应也失败: $e');
            }
          }
        }

        // 添加详细的调试信息（仅在调试模式下）
        if (kDebugMode) {
          debugPrint('=== 登录响应详细信息 ===');
          debugPrint('登录响应数据: $data');
          debugPrint('响应数据类型: ${data.runtimeType}');
          debugPrint('响应状态码: ${response.statusCode}');
        }

        // 检查所有可用的字段名
        if (data is Map) {
          if (kDebugMode) {
            debugPrint('可用字段: ${data.keys.toList()}');
            debugPrint('查找access_token: ${data.containsKey('access_token')}');
            debugPrint('查找token: ${data.containsKey('token')}');
            debugPrint('查找user: ${data.containsKey('user')}');
            debugPrint('查找data: ${data.containsKey('data')}');
            debugPrint('查找message: ${data.containsKey('message')}');
          }
        } else if (data is String) {
          if (kDebugMode) {
            debugPrint('响应数据是字符串: $data');
          }
          // 如果是字符串，尝试作为JSON解析
          try {
            final parsedData = json.decode(data);
            if (kDebugMode) {
              debugPrint('字符串JSON解析成功: ${parsedData.runtimeType}');
            }
            if (parsedData is Map) {
              data = parsedData; // 使用解析后的数据
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('字符串JSON解析失败: $e');
            }
          }
        }

        // 检查必要的字段是否存在
        if (data == null) {
          if (kDebugMode) {
            debugPrint('响应数据为null');
          }
          return {'success': false, 'message': '服务器返回空数据'};
        }

        // 检查响应是否为空
        if (data.toString().isEmpty) {
          if (kDebugMode) {
            debugPrint('响应数据为空字符串');
          }
          return {'success': false, 'message': '服务器返回空响应'};
        }

        // 如果响应是字符串，检查是否是成功消息
        if (data is String) {
          if (kDebugMode) {
            debugPrint('处理字符串响应: "$data"');
          }
          if (data.toLowerCase().contains('successful') ||
              data.toLowerCase().contains('success') ||
              data.toLowerCase().contains('登录成功')) {
            if (kDebugMode) {
              debugPrint('检测到成功消息，但缺少必要的JSON数据');
            }
            return {
              'success': false,
              'message': '登录失败：服务器返回成功消息但缺少必要的用户信息（需要JSON格式数据）',
            };
          } else {
            return {'success': false, 'message': '登录失败：$data'};
          }
        }

        // 尝试不同的token字段名
        var token = data['access_token'];
        if (token == null) {
          token = data['token'];
        }

        // 如果根级别没有找到token，尝试从data对象中获取
        if (token == null && data['data'] != null) {
          final innerData = data['data'];
          if (innerData is Map) {
            token = innerData['access_token'];
            if (token == null) {
              token = innerData['token'];
            }
          }
        }

        if (token == null) {
          return {
            'success': false,
            'message': '登录失败：未获取到访问令牌（支持的字段名：access_token, token）',
          };
        }

        // 尝试不同的用户字段名
        var user = data['user'];

        // 如果没有找到user字段或者user字段是token数据，尝试从JWT token中解码用户信息
        if (user == null ||
            (user is Map &&
                user.keys.length <= 3 &&
                user.containsKey('access_token'))) {
          if (kDebugMode) {
            debugPrint('未找到user字段，尝试从JWT token解码用户信息');
          }
          try {
            // JWT token格式：header.payload.signature
            final parts = token.toString().split('.');
            if (parts.length == 3) {
              // 解码payload部分（第二部分）
              final payload = parts[1];
              // Base64解码
              final normalized = payload.padRight(
                payload.length + (4 - payload.length % 4) % 4,
                '=',
              );
              final decoded = Uri.decodeComponent(normalized);
              final decodedBytes = base64.decode(decoded);
              final decodedString = utf8.decode(decodedBytes);
              final jwtPayload = json.decode(decodedString);

              if (kDebugMode) {
                debugPrint('JWT payload解码成功');
              }

              // 从JWT payload中提取用户信息
              if (jwtPayload is Map) {
                // 尝试不同的用户ID字段
                var jwtUserId = jwtPayload['sub'];
                if (jwtUserId == null) {
                  jwtUserId = jwtPayload['id'];
                  if (jwtUserId == null) {
                    jwtUserId = jwtPayload['user_id'];
                  }
                }

                user = {
                  'id': jwtUserId,
                  'username':
                      jwtPayload['username'] ??
                      jwtPayload['name'], // 尝试不同的用户名字段
                  'role':
                      jwtPayload['role'] ??
                      jwtPayload['role_name'] ??
                      'user', // 尝试不同的角色字段
                };
                if (kDebugMode) {
                  debugPrint('从JWT解码的用户信息成功');
                }
              }
            } else {
              if (kDebugMode) {
                debugPrint('JWT token格式不正确，parts长度: ${parts.length}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('JWT解码失败: $e');
            }
          }
        }

        // 如果仍然没有用户信息，或者用户信息中没有email，尝试调用单独的用户信息接口
        if (token != null) {
          // 检查是否需要从服务器获取完整的用户信息
          bool needFetchFromServer = false;
          if (user == null) {
            if (kDebugMode) {
              debugPrint('JWT解码失败，尝试调用单独的用户信息接口');
            }
            needFetchFromServer = true;
          } else if (user is Map && (user['email'] == null || user['email'].toString().isEmpty)) {
            if (kDebugMode) {
              debugPrint('用户信息中没有email，尝试从服务器获取完整用户信息');
            }
            needFetchFromServer = true;
          }
          
          if (needFetchFromServer) {
            try {
              // 在调用 /api/users/me 之前，先保存 token 到本地存储
              // 这样拦截器才能读取到 token 并添加到请求头中
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(AppConstants.tokenKey, token.toString());
              if (kDebugMode) {
                debugPrint('已保存token到本地存储，准备调用用户信息接口');
              }
              
              final userResponse = await _apiService.get('/api/users/me');
              if (kDebugMode) {
                debugPrint('用户信息接口响应状态码: ${userResponse.statusCode}');
              }

              if (userResponse.statusCode == 200) {
                final serverUser = userResponse.data;

                // 如果响应是嵌套的格式，尝试提取用户信息
                Map<String, dynamic>? extractedUser;
                if (serverUser is Map) {
                  if (serverUser['data'] != null) {
                    extractedUser = serverUser['data'] as Map<String, dynamic>?;
                  } else {
                    extractedUser = serverUser as Map<String, dynamic>?;
                  }
                }

                if (extractedUser != null) {
                  // 如果之前有用户信息，合并服务器返回的完整信息
                  if (user != null && user is Map) {
                    user = {
                      ...user,
                      ...extractedUser, // 服务器返回的信息优先
                    };
                  } else {
                    user = extractedUser;
                  }
                }
              } else {
                if (kDebugMode) {
                  debugPrint('用户信息接口返回状态码: ${userResponse.statusCode}');
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('获取用户信息接口失败: $e');
              }
            }
          }
        }

        if (user == null) {
          return {
            'success': false,
            'message':
                '登录失败：未获取到用户信息（支持的字段名：user, data，或JWT token中无用户信息，或用户信息接口不可用）',
          };
        }

        // 检查用户对象的关键字段
        var userId = user['id'];
        if (userId == null) {
          userId = user['user_id'];
        }

        if (userId == null) {
          return {
            'success': false,
            'message': '登录失败：用户ID为空（支持的字段名：id, user_id）',
          };
        }

        // 保存到本地存储
        // 注意：如果之前已经保存了 token（在调用 /api/users/me 时），这里不需要重复保存
        final prefs = await SharedPreferences.getInstance();
        // 检查 token 是否已经保存（可能在调用 /api/users/me 时已保存）
        final existingToken = prefs.getString(AppConstants.tokenKey);
        if (existingToken == null || existingToken != token.toString()) {
          await prefs.setString(AppConstants.tokenKey, token.toString());
        }
        await prefs.setString(AppConstants.userIdKey, userId.toString());

        // 尝试不同的用户名字段
        var userName =
            user['name'] ?? user['username'] ?? user['user_name'] ?? username;
        await prefs.setString(AppConstants.userNameKey, userName.toString());

        // 尝试不同的角色字段
        var userRole =
            user['role'] ?? user['role_name'] ?? user['user_role'] ?? 'user';
        await prefs.setString(AppConstants.userRoleKey, userRole.toString());

        // 保存邮箱地址
        var userEmail = user['email'] ?? '';
        await prefs.setString(AppConstants.userEmailKey, userEmail.toString());

        return {'success': true, 'user': user, 'token': token};
      } else {
        return {'success': false, 'message': '登录失败：状态码 ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': '登录异常：${e.toString()}'};
    }
  }

  // 获取当前用户信息
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/api/users/me');

      if (response.statusCode == 200) {
        // 处理响应数据：如果被包装在 data 字段中，则提取 data 字段
        if (response.data is Map<String, dynamic> && 
            response.data.containsKey('data') && 
            response.data.containsKey('success')) {
          return response.data['data'] as Map<String, dynamic>;
        }
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 从本地存储获取用户信息
  Future<Map<String, String>?> getLocalUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userId = prefs.getString(AppConstants.userIdKey);
    final userName = prefs.getString(AppConstants.userNameKey);
    final userRole = prefs.getString(AppConstants.userRoleKey);
    final userEmail = prefs.getString(AppConstants.userEmailKey);

    if (token != null && userId != null) {
      return {
        'token': token,
        'userId': userId,
        'userName': userName ?? '',
        'userRole': userRole ?? 'user',
        'userEmail': userEmail ?? '',
      };
    }
    return null;
  }

  // 检查是否已登录
  Future<bool> isLoggedIn() async {
    final userInfo = await getLocalUserInfo();
    return userInfo != null;
  }

  // 检查是否是管理员或审核员
  Future<bool> isAdminOrModerator() async {
    final userInfo = await getLocalUserInfo();
    if (userInfo != null) {
      final role = userInfo['userRole'];
      return role == 'admin' || role == 'moderator';
    }
    return false;
  }

  // 用户登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userNameKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.userEmailKey);
  }

  // 发送注册验证码
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      // 获取 baseUrl
      final baseUrl = await _apiService.getCurrentBaseUrl();
      
      // 创建临时的 Dio 实例用于发送 form-urlencoded 请求
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ));

      final response = await dio.post(
        '/api/send_verification_code',
        data: {'email': email},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': '验证码已发送'};
      } else {
        final errorMessage = response.data is Map
            ? (response.data['detail'] ?? response.data['message'] ?? '发送验证码失败')
            : '发送验证码失败';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      String errorMessage = '发送验证码失败';
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          errorMessage = '邮箱格式无效';
        } else if (e.response?.statusCode == 429) {
          errorMessage = '请求过于频繁，请稍后再试';
        } else if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          errorMessage = data['detail'] ?? data['message'] ?? errorMessage;
        }
      }
      return {'success': false, 'message': errorMessage};
    }
  }

  // 用户注册
  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    required String verificationCode,
  }) async {
    try {
      // 获取 baseUrl
      final baseUrl = await _apiService.getCurrentBaseUrl();
      
      // 创建临时的 Dio 实例用于发送 form-urlencoded 请求
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ));

      final response = await dio.post(
        '/api/user/register',
        data: {
          'username': username,
          'password': password,
          'email': email,
          'verification_code': verificationCode,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return {'success': true, 'message': data['message'] ?? '注册成功'};
        } else {
          return {'success': true, 'message': '注册成功'};
        }
      } else {
        final errorMessage = response.data is Map
            ? (response.data['detail'] ?? response.data['message'] ?? '注册失败')
            : '注册失败';
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      String errorMessage = '注册失败';
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          final data = e.response?.data;
          if (data is Map) {
            final detail = data['detail'] ?? data['message'] ?? '';
            if (detail.toString().contains('用户名') || detail.toString().contains('username')) {
              errorMessage = '用户名已存在';
            } else if (detail.toString().contains('邮箱') || detail.toString().contains('email')) {
              errorMessage = '邮箱已被注册';
            } else if (detail.toString().contains('验证码') || detail.toString().contains('verification')) {
              errorMessage = '验证码错误或已失效';
            } else {
              errorMessage = detail.toString();
            }
          } else {
            errorMessage = '注册信息有误，请检查后重试';
          }
        } else if (e.response?.data is Map) {
          final data = e.response!.data as Map;
          errorMessage = data['detail'] ?? data['message'] ?? errorMessage;
        }
      }
      return {'success': false, 'message': errorMessage};
    }
  }
}
