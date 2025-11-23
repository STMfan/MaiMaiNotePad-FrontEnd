import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MessageManagementTabContent extends StatefulWidget {
  const MessageManagementTabContent({super.key});

  @override
  State<MessageManagementTabContent> createState() =>
      _MessageManagementTabContentState();
}

class _MessageManagementTabContentState
    extends State<MessageManagementTabContent> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _broadcastMessages = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _total = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadBroadcastMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBroadcastMessages({bool resetPage = false}) async {
    if (!mounted) return;

    if (resetPage) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getBroadcastMessages(
        page: _currentPage,
        limit: 20,
      );

      if (!mounted) return;

      final data = response['data'];
      final messages = List<Map<String, dynamic>>.from(data ?? []);

      if (mounted) {
        setState(() {
          if (resetPage) {
            _broadcastMessages = messages;
          } else {
            _broadcastMessages.addAll(messages);
          }
          _total = response['total'] ?? messages.length;
          _hasMore = messages.length >= 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSendBroadcastDialog() async {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发送系统公告'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '标题 *',
                    border: OutlineInputBorder(),
                    hintText: '请输入公告标题',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '标题不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: summaryController,
                  decoration: const InputDecoration(
                    labelText: '简介（可选）',
                    border: OutlineInputBorder(),
                    hintText: '请输入消息简介，用于列表预览',
                    helperText: '如果不填写，将自动从内容生成',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '详细内容 *',
                    border: OutlineInputBorder(),
                    hintText: '请输入公告详细内容（支持Markdown格式）',
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '内容不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '此公告将发送给所有用户',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _apiService.sendMessage(
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          summary: summaryController.text.trim().isNotEmpty
              ? summaryController.text.trim()
              : null,
          asAnnouncement: true,
          broadcastAll: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('系统公告发送成功'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          // 刷新列表
          _loadBroadcastMessages(resetPage: true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('发送失败: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '未知时间';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '未知时间';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // 顶部操作栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '广播消息管理',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showSendBroadcastDialog,
                  icon: const Icon(Icons.campaign),
                  label: const Text('发送系统公告'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          // 消息列表
          Expanded(
            child: _isLoading && _broadcastMessages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _broadcastMessages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '加载失败: $_error',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadBroadcastMessages(
                                resetPage: true,
                              ),
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _broadcastMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.campaign_outlined,
                                  size: 48,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无广播消息',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadBroadcastMessages(
                              resetPage: true,
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _broadcastMessages.length +
                                  (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _broadcastMessages.length) {
                                  // 加载更多
                                  if (!_isLoading && _hasMore) {
                                    _currentPage++;
                                    _loadBroadcastMessages();
                                  }
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final message = _broadcastMessages[index];
                                final stats = message['stats'] as Map<String, dynamic>? ?? {};
                                final sender = message['sender'] as Map<String, dynamic>? ?? {};

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 标题和发送者
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    message['title'] ?? '无标题',
                                                    style: theme
                                                        .textTheme.titleLarge
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        size: 16,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        sender['username'] ??
                                                            '未知用户',
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          color: colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.6,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 16,
                                                        color: colorScheme
                                                            .onSurface
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatDate(
                                                          message['created_at'],
                                                        ),
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                          color: colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.6,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '系统公告',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // 内容
                                        Text(
                                          message['content'] ?? '无内容',
                                          style: theme.textTheme.bodyMedium,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        // 统计信息
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: colorScheme.surfaceVariant
                                                .withValues(alpha: 0.3),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              _buildStatItem(
                                                '发送数量',
                                                '${stats['total_count'] ?? 0}',
                                                Icons.send,
                                                colorScheme.primary,
                                              ),
                                              _buildStatItem(
                                                '已读数量',
                                                '${stats['read_count'] ?? 0}',
                                                Icons.mark_email_read,
                                                colorScheme.secondary,
                                              ),
                                              _buildStatItem(
                                                '未读数量',
                                                '${stats['unread_count'] ?? 0}',
                                                Icons.mark_email_unread,
                                                colorScheme.tertiary,
                                              ),
                                              _buildStatItem(
                                                '阅读率',
                                                '${(stats['read_rate'] ?? 0.0).toStringAsFixed(1)}%',
                                                Icons.trending_up,
                                                colorScheme.error,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

