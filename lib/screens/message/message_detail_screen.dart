import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../../models/message.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_router.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_colors.dart';
import 'package:intl/intl.dart';

class MessageDetailScreen extends StatefulWidget {
  final String messageId;

  const MessageDetailScreen({super.key, required this.messageId});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  Message? _message;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMessageDetail();
  }

  Future<void> _loadMessageDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final messageData = await apiService.getMessageDetail(widget.messageId);
      final message = Message.fromJson(messageData);

      setState(() {
        _message = message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载消息详情失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead() async {
    if (_message == null || _message!.isRead) return;

    try {
      await ApiService().markMessageAsRead(_message!.id);
      setState(() {
        _message = _message!.copyWith(isRead: true);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('消息已标记为已读'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('标记已读失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage() async {
    if (_message == null) return;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
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

    if (confirmed != true) return;

    try {
      await ApiService().deleteMessage(_message!.id);
      if (mounted) {
        Navigator.of(context).pop(true); // 返回并传递删除成功标志
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('消息已删除'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
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

  String _getMessageTypeText(String type) {
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

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息详情'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (_message != null && !_message!.isRead)
            IconButton(
              icon: const Icon(Icons.mark_email_read, color: Colors.white),
              onPressed: _markAsRead,
              tooltip: '标记已读',
            ),
          if (_message != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteMessage,
              tooltip: '删除',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMessageDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _message == null
                  ? const Center(child: Text('消息不存在'))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 标题
                          Text(
                            _message!.title,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 消息信息
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
                                      '类型：${_getMessageTypeText(_message!.type)}',
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
                                      '发送时间：${_formatDate(_message!.createdAt)}',
                                      style: TextStyle(
                                        fontSize: isLargeScreen ? 14 : 12,
                                        color: AppColors.onSurfaceWithOpacity07(context),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_message!.readAt != null) ...[
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
                                        '阅读时间：${_formatDate(_message!.readAt)}',
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

                          // 简介（如果有）
                          if (_message!.summary != null && _message!.summary!.isNotEmpty) ...[
                            Text(
                              '简介',
                              style: TextStyle(
                                fontSize: isLargeScreen ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                              decoration: BoxDecoration(
                                color: AppColors.onSurfaceWithOpacity01(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _message!.summary!,
                                style: TextStyle(
                                  fontSize: isLargeScreen ? 14 : 12,
                                  color: AppColors.onSurfaceWithOpacity07(context),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 详细内容
                          Text(
                            '详细内容',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                            decoration: BoxDecoration(
                              color: AppColors.onSurfaceWithOpacity01(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: MarkdownBody(
                              data: _message!.content,
                              styleSheet: MarkdownStyleSheet(
                                // 标题样式
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
                                // 段落样式
                                p: TextStyle(
                                  fontSize: isLargeScreen ? 14 : 12,
                                  color: AppColors.onSurfaceWithOpacity07(context),
                                  height: 1.6,
                                ),
                                // 代码块样式
                                codeblockDecoration: BoxDecoration(
                                  color: AppColors.onSurfaceWithOpacity01(context),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                code: TextStyle(
                                  fontSize: isLargeScreen ? 13 : 11,
                                  fontFamily: 'monospace',
                                  backgroundColor: AppColors.onSurfaceWithOpacity01(context),
                                ),
                                // 链接样式
                                a: TextStyle(
                                  color: AppTheme.primaryOrange,
                                  decoration: TextDecoration.underline,
                                ),
                                // 列表样式
                                listBullet: TextStyle(
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                              onTapLink: (text, href, title) {
                                // 处理链接点击
                                if (href != null) {
                                  // 可以使用url_launcher打开链接
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('链接: $href'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 操作按钮
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (!_message!.isRead)
                                ElevatedButton.icon(
                                  onPressed: _markAsRead,
                                  icon: const Icon(Icons.mark_email_read),
                                  label: const Text('标记已读'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryOrange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ElevatedButton.icon(
                                onPressed: _deleteMessage,
                                icon: const Icon(Icons.delete),
                                label: const Text('删除'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}



