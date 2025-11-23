// Web 环境下的下载实现
// 使用条件导入，仅在 web 环境下编译

import 'dart:html' as html;
import 'dart:typed_data';

/// Web 环境下的下载实现
/// 使用 Blob URL 触发浏览器下载
Future<bool> downloadFileWeb(List<int> bytes, String filename) async {
  try {
    // 创建 Blob
    final blob = html.Blob([Uint8List.fromList(bytes)]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // 创建 <a> 标签并触发下载
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    // 清理 URL（延迟清理，确保下载已开始）
    Future.delayed(const Duration(seconds: 1), () {
      html.Url.revokeObjectUrl(url);
    });

    return true;
  } catch (e) {
    // 注意：在 web 环境下不能使用 debugPrint，使用 print
    print('Web 下载失败: $e');
    return false;
  }
}

