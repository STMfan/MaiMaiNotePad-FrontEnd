import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

// 条件导入：在 web 环境下导入 web 实现
import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart' as web_impl;

/// Web 环境下的下载辅助类
/// 使用 Dio 下载文件（携带 token），然后通过 Blob URL 触发浏览器下载
class DownloadHelper {
  /// 下载文件（支持 web 和移动端）
  /// 
  /// [downloadUrl] 下载链接（可以是相对路径或绝对路径）
  /// [filename] 文件名（可选，如果不提供则从响应头或 URL 中提取）
  /// 
  /// 返回下载是否成功
  static Future<bool> downloadFile({
    required String downloadUrl,
    String? filename,
  }) async {
    try {
      // 获取配置信息
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString(AppConstants.apiBaseUrlKey) ?? 
                     AppConstants.apiBaseUrl;
      final token = prefs.getString(AppConstants.tokenKey);

      // 获取完整的下载 URL
      String fullUrl = downloadUrl;
      if (downloadUrl.startsWith('/')) {
        final cleanBaseUrl = baseUrl.endsWith('/') 
            ? baseUrl.substring(0, baseUrl.length - 1) 
            : baseUrl;
        fullUrl = '$cleanBaseUrl$downloadUrl';
      }

      // 创建 Dio 实例并配置（复用 ApiService 的配置逻辑）

      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      // 添加 token 到请求头
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      // 使用 Dio 下载文件（自动携带 token）
      final response = await dio.get(
        fullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final bytes = response.data as List<int>;
      final extractedFilename = filename ?? _extractFilename(fullUrl, response);

      // 在 web 环境下使用 Blob URL 触发下载
      if (kIsWeb) {
        return await web_impl.downloadFileWeb(bytes, extractedFilename);
      } else {
        // 移动端：暂时不支持，可以后续扩展
        debugPrint('移动端下载功能待实现');
        return false;
      }
    } catch (e) {
      debugPrint('下载文件失败: $e');
      return false;
    }
  }

  /// 从 URL 或响应头中提取文件名
  static String _extractFilename(String url, Response response) {
    // 1. 尝试从响应头中获取文件名
    final contentDisposition = response.headers.value('content-disposition');
    if (contentDisposition != null) {
      // 匹配 filename="xxx" 或 filename='xxx' 或 filename=xxx
      // 使用普通字符串，转义反斜杠
      final filenameMatch = RegExp('filename[^;=\\n]*=(([\'"]).*?\\2|[^;\\n]*)')
          .firstMatch(contentDisposition);
      if (filenameMatch != null) {
        String filename = filenameMatch.group(1) ?? '';
        // 移除引号
        filename = filename.replaceAll('"', '').replaceAll("'", '');
        if (filename.isNotEmpty) {
          return filename;
        }
      }
    }

    // 2. 从 URL 中提取文件名
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
          return lastSegment;
        }
      }
    } catch (e) {
      debugPrint('解析 URL 失败: $e');
    }

    // 3. 默认文件名
    return 'download.zip';
  }
}

