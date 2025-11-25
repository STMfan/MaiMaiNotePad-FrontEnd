import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/app_constants.dart';

class SessionStore {
  SessionStore._();

  static final SessionStore _instance = SessionStore._();

  factory SessionStore() => _instance;

  /// 全局未授权回调（如 token 过期），由应用层注册
  static void Function()? onUnauthorized;

  SharedPreferences? _prefs;
  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();

  Future<void> _ensurePrefsLoaded() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getToken() async {
    await _ensurePrefsLoaded();
    return _prefs!.getString(AppConstants.tokenKey);
  }

  Future<void> saveToken(String? token) async {
    await _ensurePrefsLoaded();
    if (token == null) {
      await _prefs!.remove(AppConstants.tokenKey);
    } else {
      await _prefs!.setString(AppConstants.tokenKey, token);
    }
    _tokenController.add(token);
  }

  Stream<String?> watchToken() => _tokenController.stream.distinct();

  Future<String> getBaseUrl() async {
    await _ensurePrefsLoaded();
    return _prefs!.getString(AppConstants.apiBaseUrlKey) ??
        AppConstants.apiBaseUrl;
  }

  Future<void> setBaseUrl(String baseUrl) async {
    await _ensurePrefsLoaded();
    await _prefs!.setString(AppConstants.apiBaseUrlKey, baseUrl);
  }

  Future<void> saveUser({
    String? userId,
    String? username,
    String? role,
  }) async {
    await _ensurePrefsLoaded();
    if (userId != null) {
      await _prefs!.setString(AppConstants.userIdKey, userId);
    }
    if (username != null) {
      await _prefs!.setString(AppConstants.userNameKey, username);
    }
    if (role != null) {
      await _prefs!.setString(AppConstants.userRoleKey, role);
    }
  }

  Future<void> clearSession() async {
    await _ensurePrefsLoaded();
    await Future.wait([
      _prefs!.remove(AppConstants.tokenKey),
      _prefs!.remove(AppConstants.userIdKey),
      _prefs!.remove(AppConstants.userNameKey),
      _prefs!.remove(AppConstants.userRoleKey),
    ]);
    _tokenController.add(null);
    if (onUnauthorized != null) {
      onUnauthorized!.call();
    }
  }

  Future<void> dispose() async {
    await _tokenController.close();
  }
}


