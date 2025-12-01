// Web 环境下的下载实现
// 使用条件导入，仅在 web 环境下编译

import 'dart:convert';
import 'package:web/web.dart' as web;

/// Web 环境下的下载实现
/// 使用 Blob URL 触发浏览器下载
Future<bool> downloadFileWeb(List<int> bytes, String filename) async {
  try {
    // 创建临时HTML元素触发下载
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;

    // 将字节数据转换为base64字符串
    final base64Data = base64Encode(bytes);

    anchor.href = 'data:application/octet-stream;base64,$base64Data';
    anchor.download = filename;

    web.document.body!.appendChild(anchor);
    anchor.click();
    web.document.body!.removeChild(anchor);

    return true;
  } catch (e) {
    // 注意：在 web 环境下不能使用 debugPrint，使用 print
    print('Web 下载失败: $e');
    return false;
  }
}
