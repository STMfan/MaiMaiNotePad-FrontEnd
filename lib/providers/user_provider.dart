import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../constants/app_constants.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  User? get user => _user;
  User? get currentUser => _user; // 添加currentUser getter作为user的别名
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  // 初始化，检查本地存储的登录状态
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      final isLoggedIn = await authService.isLoggedIn();

      if (isLoggedIn) {
        // 从本地存储获取用户信息
        final userInfo = await authService.getLocalUserInfo();
        if (userInfo != null) {
          _token = userInfo['token'];
          _isLoggedIn = true;
          
          // 刷新用户信息以获取完整信息（包括头像）
          await refreshUserInfo();
          
          // 如果刷新失败，使用本地存储的信息作为后备
          if (_user == null) {
            var userEmail = userInfo['userEmail'];
            
            // 如果本地存储中没有 email，尝试从服务器获取
            if (userEmail == null || userEmail.isEmpty) {
              try {
                final currentUser = await authService.getCurrentUser();
                if (currentUser != null && currentUser['email'] != null) {
                  userEmail = currentUser['email'].toString();
                  // 更新本地存储
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString(AppConstants.userEmailKey, userEmail);
                }
              } catch (e) {
                // 如果获取失败，继续使用本地存储的信息
                print('获取用户邮箱失败: $e');
              }
            }
            
            _user = User(
              id: userInfo['userId'] ?? '',
              name: userInfo['userName'] ?? '未知用户',
              email: userEmail,
              role: userInfo['userRole'] ?? 'user',
            );
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // 用户登录
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final result = await authService.login(username, password);

      if (result['success']) {
        _token = result['token'];
        _isLoggedIn = true;
        
        // 刷新用户信息以获取完整信息（包括头像）
        await refreshUserInfo();
        
        // 如果刷新失败，使用登录返回的用户信息作为后备
        if (_user == null) {
          final userInfo = await authService.getLocalUserInfo();
          if (userInfo != null) {
            _user = User(
              id: userInfo['userId'] ?? '',
              name: userInfo['userName'] ?? '未知用户',
              email: userInfo['userEmail'],
              role: userInfo['userRole'] ?? 'user',
            );
          } else if (result['user'] != null) {
            _user = User.fromJson(result['user']);
          }
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 用户登出
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      await authService.logout();
      _user = null;
      _isLoggedIn = false;
      _token = null;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // 清除错误信息
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // 更新用户信息
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  // 刷新用户信息（从服务器获取最新信息）
  Future<void> refreshUserInfo() async {
    if (!_isLoggedIn) return;

    try {
      final authService = AuthService();
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        // 更新本地存储
        final prefs = await SharedPreferences.getInstance();
        if (currentUser['email'] != null) {
          await prefs.setString(AppConstants.userEmailKey, currentUser['email'].toString());
        }
        
        // 更新用户对象（包含头像信息）
        if (_user != null) {
          _user = User(
            id: _user!.id,
            name: currentUser['username']?.toString() ?? _user!.name,
            email: currentUser['email']?.toString() ?? _user!.email,
            role: currentUser['role']?.toString() ?? _user!.role,
            avatarUrl: currentUser['avatar_url']?.toString(),
            avatarUpdatedAt: currentUser['avatar_updated_at'] != null
                ? DateTime.tryParse(currentUser['avatar_updated_at'].toString())
                : null,
          );
          notifyListeners();
        } else {
          // 如果用户对象不存在，创建新的用户对象
          _user = User.fromJson(currentUser);
          notifyListeners();
        }
      }
    } catch (e) {
      print('刷新用户信息失败: $e');
    }
  }

  // 发送验证码
  Future<bool> sendVerificationCode(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final result = await authService.sendVerificationCode(email);

      if (result['success']) {
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 用户注册
  Future<bool> register({
    required String username,
    required String password,
    required String email,
    required String verificationCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final result = await authService.register(
        username: username,
        password: password,
        email: email,
        verificationCode: verificationCode,
      );

      if (result['success']) {
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
