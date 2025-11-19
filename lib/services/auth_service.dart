import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart';
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
        '/token',
        data: {'username': username, 'password': password},
        responseType: ResponseType.json,
      );

      if (response.statusCode == 200) {
        var data = response.data;

        // 如果JSON解析失败，尝试纯文本响应
        if (data == null || data.toString().isEmpty) {
          print('JSON响应为空，尝试纯文本响应');
          try {
            final plainResponse = await _apiService.post(
              '/token',
              data: {'username': username, 'password': password},
              responseType: ResponseType.plain,
            );
            data = plainResponse.data;
            print('纯文本响应数据: $data');
          } catch (e) {
            print('纯文本响应也失败: $e');
          }
        }

        // 添加详细的调试信息
        print('=== 登录响应详细信息 ===');
        print('登录响应数据: $data');
        print('响应数据类型: ${data.runtimeType}');
        print('响应状态码: ${response.statusCode}');
        print('响应headers: ${response.headers}');
        print('响应请求URL: ${response.requestOptions.uri}');
        print('响应请求方法: ${response.requestOptions.method}');
        print('原始响应数据: ${response.data}');
        print('响应数据toString(): ${data.toString()}');
        print('=== 登录响应信息结束 ===');

        // 检查所有可用的字段名
        if (data is Map) {
          print('可用字段: ${data.keys.toList()}');
          print('查找access_token: ${data.containsKey('access_token')}');
          print('查找token: ${data.containsKey('token')}');
          print('查找user: ${data.containsKey('user')}');
          print('查找data: ${data.containsKey('data')}');
          print('查找message: ${data.containsKey('message')}');

          // 打印每个字段的具体值（敏感信息会做部分隐藏）
          data.forEach((key, value) {
            if (key.toString().toLowerCase().contains('token') ||
                key.toString().toLowerCase().contains('password')) {
              print(
                '字段 $key: ${value.toString().substring(0, min(10, value.toString().length))}...',
              );
            } else {
              print('字段 $key: $value (类型: ${value.runtimeType})');
            }
          });
        } else if (data is String) {
          print('响应数据是字符串: $data');
        } else {
          print('响应数据是其他类型: ${data.runtimeType}');
        }

        // 检查必要的字段是否存在
        if (data == null) {
          print('响应数据为null');
          return {'success': false, 'message': '服务器返回空数据'};
        }

        // 检查响应是否为空
        if (data.toString().isEmpty) {
          print('响应数据为空字符串');
          return {'success': false, 'message': '服务器返回空响应'};
        }

        // 如果响应是字符串，检查是否是成功消息
        if (data is String) {
          print('处理字符串响应: "$data"');
          if (data.toLowerCase().contains('successful') ||
              data.toLowerCase().contains('success') ||
              data.toLowerCase().contains('登录成功')) {
            print('检测到成功消息，但缺少必要的JSON数据');
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
          if (token != null) {
            print('使用token字段获取到token: $token');
          }
        } else {
          print('使用access_token字段获取到token: $token');
        }

        if (token == null) {
          return {
            'success': false,
            'message': '登录失败：未获取到访问令牌（支持的字段名：access_token, token）',
          };
        }

        // 尝试不同的用户字段名
        var user = data['user'];
        if (user == null) {
          user = data['data'];
          if (user != null) {
            print('使用data字段获取到user: $user');
          }
        } else {
          print('使用user字段获取到user: $user');
        }

        // 如果没有找到user字段，尝试从JWT token中解码用户信息
        if (user == null && token != null) {
          print('未找到user字段，尝试从JWT token解码用户信息');
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

              print('JWT payload: $jwtPayload');

              // 从JWT payload中提取用户信息
              if (jwtPayload is Map) {
                user = {
                  'id': jwtPayload['sub'], // JWT标准字段：subject
                  'username': jwtPayload['username'], // 你的JWT中的字段
                  'role': jwtPayload['role'], // 你的JWT中的字段
                };
                print('从JWT解码的用户信息: $user');
              }
            }
          } catch (e) {
            print('JWT解码失败: $e');
          }
        }

        // 如果仍然没有用户信息，尝试调用单独的用户信息接口
        if (user == null && token != null) {
          print('JWT解码失败，尝试调用单独的用户信息接口');
          try {
            final userResponse = await _apiService.get('/users/me');
            if (userResponse.statusCode == 200) {
              user = userResponse.data;
              print('从用户信息接口获取的用户信息: $user');
            } else {
              print('用户信息接口返回状态码: ${userResponse.statusCode}');
            }
          } catch (e) {
            print('获取用户信息接口失败: $e');
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
          if (userId != null) {
            print('使用user_id字段获取到用户ID: $userId');
          }
        } else {
          print('使用id字段获取到用户ID: $userId');
        }

        if (userId == null) {
          return {
            'success': false,
            'message': '登录失败：用户ID为空（支持的字段名：id, user_id）',
          };
        }

        // 保存到本地存储
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token.toString());
        await prefs.setString(AppConstants.userIdKey, userId.toString());

        // 尝试不同的用户名字段
        var userName =
            user['name'] ?? user['username'] ?? user['user_name'] ?? username;
        await prefs.setString(AppConstants.userNameKey, userName.toString());

        // 尝试不同的角色字段
        var userRole =
            user['role'] ?? user['role_name'] ?? user['user_role'] ?? 'user';
        await prefs.setString(AppConstants.userRoleKey, userRole.toString());

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
      final response = await _apiService.get('/users/me');

      if (response.statusCode == 200) {
        return response.data;
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

    if (token != null && userId != null) {
      return {
        'token': token,
        'userId': userId,
        'userName': userName ?? '',
        'userRole': userRole ?? 'user',
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
  }
}
