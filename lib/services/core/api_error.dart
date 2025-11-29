import 'dart:convert';

class ApiServiceError implements Exception {
  final int? statusCode;
  final String message;
  final String? type;
  final String? requestId;
  final String? errorCode;
  final dynamic details;
  final Map<String, dynamic>? raw;

  const ApiServiceError({
    this.statusCode,
    required this.message,
    this.type,
    this.requestId,
    this.errorCode,
    this.details,
    this.raw,
  });

  String toDisplayString({bool includeDetails = true}) {
    final buffer = StringBuffer();
    final statusLabel =
        statusCode != null ? '错误码: $statusCode' : '请求失败';
    final typeLabel = type != null ? ' [$type]' : '';
    buffer.writeln('$statusLabel$typeLabel - $message');

    if (errorCode != null && errorCode!.isNotEmpty) {
      buffer.writeln('错误标识: $errorCode');
    }
    if (requestId != null && requestId!.isNotEmpty) {
      buffer.writeln('请求ID: $requestId');
    }
    if (includeDetails && details != null) {
      buffer.writeln('详情: ${_stringify(details)}');
    }
    return buffer.toString().trim();
  }

  String _stringify(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is String) {
      return value;
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  String toString() => toDisplayString();
}

