import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/message.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/message_detail_viewmodel.dart';
import '../../widgets/async_state_view.dart';

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({super.key, required this.messageId});

  final String messageId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          MessageDetailViewModel(messageId: messageId)..load(),
      child: const _MessageDetailView(),
    );
  }
}

class _MessageDetailView extends StatelessWidget {
  const _MessageDetailView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MessageDetailViewModel>();
    final message = viewModel.message;
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息详情'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (message != null && !message.isRead)
            IconButton(
              icon: const Icon(Icons.mark_email_read, color: Colors.white),
              onPressed: () => _markAsRead(context),
              tooltip: '标记已读',
            ),
          if (message != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _deleteMessage(context),
              tooltip: '删除',
            ),
        ],
      ),
      body: AsyncStateView(
        isLoading: viewModel.isLoading,
        errorMessage: viewModel.errorMessage,
        isEmpty: message == null,
        emptyWidget: const Center(child: Text('消息不存在')),
        onRetry: () => context.read<MessageDetailViewModel>().load(),
        builder: (_) => _MessageDetailBody(
          message: message!,
          isLargeScreen: isLargeScreen,
        ),
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context) async {
    final viewModel = context.read<MessageDetailViewModel>();
    try {
      await viewModel.markAsRead();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('消息已标记为已读'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('标记已读失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMessage(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条消息吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }

    final viewModel = context.read<MessageDetailViewModel>();
    try {
      await viewModel.deleteMessage();
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('消息已删除'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _MessageDetailBody extends StatelessWidget {
  const _MessageDetailBody({
    required this.message,
    required this.isLargeScreen,
  });

  final Message message;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.title,
            style: TextStyle(
              fontSize: isLargeScreen ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
            decoration: BoxDecoration(
              color: AppColors.onSurfaceWithOpacity01(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: isLargeScreen ? 20 : 18,
                      color: AppColors.onSurfaceWithOpacity07(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '类型：${_getMessageTypeText(message.type)}',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: AppColors.onSurfaceWithOpacity07(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: isLargeScreen ? 20 : 18,
                      color: AppColors.onSurfaceWithOpacity07(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '发送时间：${_formatDate(message.createdAt)}',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: AppColors.onSurfaceWithOpacity07(context),
                      ),
                    ),
                  ],
                ),
                if (message.readAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: isLargeScreen ? 20 : 18,
                        color: AppColors.onSurfaceWithOpacity07(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '阅读时间：${_formatDate(message.readAt!)}',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 14 : 12,
                          color: AppColors.onSurfaceWithOpacity07(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (message.summary != null && message.summary!.isNotEmpty) ...[
            _SectionTitle(
              title: '简介',
              isLargeScreen: isLargeScreen,
            ),
            Container(
              padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
              decoration: BoxDecoration(
                color: AppColors.onSurfaceWithOpacity01(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.summary!,
                style: TextStyle(
                  fontSize: isLargeScreen ? 14 : 12,
                  color: AppColors.onSurfaceWithOpacity07(context),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _SectionTitle(
            title: '详细内容',
            isLargeScreen: isLargeScreen,
          ),
          Container(
            padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
            decoration: BoxDecoration(
              color: AppColors.onSurfaceWithOpacity01(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: MarkdownBody(
              data: message.content,
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  fontSize: isLargeScreen ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                h2: TextStyle(
                  fontSize: isLargeScreen ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                h3: TextStyle(
                  fontSize: isLargeScreen ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                p: TextStyle(
                  fontSize: isLargeScreen ? 14 : 12,
                  color: AppColors.onSurfaceWithOpacity07(context),
                  height: 1.6,
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.onSurfaceWithOpacity01(context),
                  borderRadius: BorderRadius.circular(4),
                ),
                code: TextStyle(
                  fontSize: isLargeScreen ? 13 : 11,
                  fontFamily: 'monospace',
                  backgroundColor: AppColors.onSurfaceWithOpacity01(context),
                ),
                a: TextStyle(
                  color: AppTheme.primaryOrange,
                  decoration: TextDecoration.underline,
                ),
                listBullet: TextStyle(
                  color: AppTheme.primaryOrange,
                ),
              ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('链接: $href')),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    }
  }

  static String _getMessageTypeText(String type) {
    switch (type) {
      case 'announcement':
        return '公告';
      case 'direct':
        return '私信';
      case 'system':
        return '系统消息';
      case 'notification':
        return '通知';
      case 'review_result':
        return '审核结果';
      default:
        return type;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.isLargeScreen,
  });

  final String title;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isLargeScreen ? 18 : 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

