class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // 逐个解析 items，避免单个元素解析失败导致整个列表为空
    final List<dynamic>? itemsList = json['items'] as List<dynamic>?;
    final List<T> items = [];
    
    if (itemsList != null) {
      for (int i = 0; i < itemsList.length; i++) {
        try {
          final item = itemsList[i] as Map<String, dynamic>;
          final parsedItem = fromJsonT(item);
          items.add(parsedItem);
        } catch (e, stackTrace) {
          // 导入 debugPrint 用于调试
          // ignore: avoid_print
          print('⚠️ PaginatedResponse.fromJson: 解析第 $i 个元素失败');
          // ignore: avoid_print
          print('错误: $e');
          // ignore: avoid_print
          print('元素数据: ${itemsList[i]}');
          // ignore: avoid_print
          print('堆栈跟踪: $stackTrace');
          // 跳过该元素，继续解析其他元素，而不是让整个解析失败
        }
      }
    }
    
    final total = json['total'] as int? ?? 0;
    final page = json['page'] as int? ?? 1;
    final pageSize = json['page_size'] as int? ?? json['pageSize'] as int? ?? 20;
    final totalPages = json['total_pages'] as int? ?? 
        json['totalPages'] as int? ?? 
        (total / pageSize).ceil();

    // 如果解析后的 items 数量与原始数量不一致，打印警告
    if (itemsList != null && items.length != itemsList.length) {
      // ignore: avoid_print
      print('⚠️ PaginatedResponse.fromJson: 解析结果数量不一致');
      // ignore: avoid_print
      print('原始数量: ${itemsList.length}, 成功解析: ${items.length}');
    }

    return PaginatedResponse<T>(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'items': items.map((item) => toJsonT(item)).toList(),
      'total': total,
      'page': page,
      'page_size': pageSize,
      'total_pages': totalPages,
    };
  }
}
