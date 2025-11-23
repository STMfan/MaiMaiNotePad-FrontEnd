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
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => fromJsonT(item as Map<String, dynamic>))
            .toList() ??
        [];
    
    final total = json['total'] as int? ?? 0;
    final page = json['page'] as int? ?? 1;
    final pageSize = json['page_size'] as int? ?? json['pageSize'] as int? ?? 20;
    final totalPages = json['total_pages'] as int? ?? 
        json['totalPages'] as int? ?? 
        (total / pageSize).ceil();

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
