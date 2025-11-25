import 'package:flutter/material.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final int pageSize;
  final Function(int) onPageChanged;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
            tooltip: '上一页',
          ),
          
          // 页码显示
          Text(
            '第 $currentPage / $totalPages 页 (共 $total 条)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          
          // 下一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () => onPageChanged(currentPage + 1)
                : null,
            tooltip: '下一页',
          ),
        ],
      ),
    );
  }
}















