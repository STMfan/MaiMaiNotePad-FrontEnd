import 'dart:async';

import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import 'session_store.dart';

class HttpClientFactory {
  HttpClientFactory._();

  static final HttpClientFactory _instance = HttpClientFactory._();

  factory HttpClientFactory() => _instance;

  final SessionStore _sessionStore = SessionStore();
  Dio? _dio;
  Completer<void>? _initCompleter;

  Future<Dio> getClient() async {
    if (_dio != null) {
      return _dio!;
    }

    if (_initCompleter != null) {
      await _initCompleter!.future;
      return _dio!;
    }

    _initCompleter = Completer<void>();

    try {
      final baseUrl = await _sessionStore.getBaseUrl();
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final token = await _sessionStore.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              await _sessionStore.clearSession();
            }
            handler.next(error);
          },
        ),
      );

      _dio = dio;
      _initCompleter!.complete();
    } catch (error) {
      _initCompleter!.completeError(error);
      _initCompleter = null;
      rethrow;
    }

    return _dio!;
  }

  Future<void> updateBaseUrl(String newBaseUrl) async {
    await _sessionStore.setBaseUrl(newBaseUrl);
    _dio = null;
    _initCompleter = null;
  }

  Future<String> currentBaseUrl() async {
    if (_dio != null) {
      return _dio!.options.baseUrl;
    }
    return _sessionStore.getBaseUrl();
  }
}


