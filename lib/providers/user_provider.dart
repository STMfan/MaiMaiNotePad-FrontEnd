import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

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
          _user = User(
            id: userInfo['userId'] ?? '',
            name: userInfo['userName'] ?? '未知用户',
            role: userInfo['userRole'] ?? 'user',
          );
          _token = userInfo['token'];
          _isLoggedIn = true;
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
        _user = User.fromJson(result['user']);
        _token = result['token'];
        _isLoggedIn = true;
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
}
