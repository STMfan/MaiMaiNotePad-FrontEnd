import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message.dart';
import '../../utils/app_router.dart';
import '../../services/api_service.dart';
import '../../utils/app_colors.dart';

// 消息标签页内容组件
class MessageTabContent extends StatefulWidget {
  const MessageTabContent({super.key});

  @override
  State<MessageTabContent> createState() => _MessageTabContentState();
}

class _MessageTabContentState extends State<MessageTabContent> {
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _error;
 final Set<String> _selectedMessageIds = {}; // 选中的消息ID集合
  bool _isSelectionMode = false; // 是否处于选择模式

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isLoggedIn) {
        setState(() {
          _isLoading = false;
          _messages = [];
        });
        return;
      }

      final response = await ApiService().getUserMessages();
      final messages = response.map((item) => Message.fromJson(item)).toList();
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载消息失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMessage(String messageId) async {
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
      await ApiService().deleteMessage(messageId);
      setState(() {
        _messages.removeWhere((msg) => msg.id == messageId);
        _selectedMessageIds.remove(messageId);
      });
      if (mounted) {
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
            content: Text('删除消息失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelectedMessages() async {
    if (_selectedMessageIds.isEmpty) return;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认批量删除'),
        content: Text('确定要删除选中的 ${_selectedMessageIds.length} 条消息吗？此操作不可撤销。'),
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
      final messageIds = _selectedMessageIds.toList();
      await ApiService().deleteMessages(messageIds);
      setState(() {
        _messages.removeWhere((msg) => _selectedMessageIds.contains(msg.id));
        _selectedMessageIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('成功删除 ${messageIds.length} 条消息'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('批量删除失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMessageIds.clear();
      }
    });
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await ApiService().markMessageAsRead(messageId);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标记已读失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 获取屏幕尺寸信息
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1200; // 大屏幕（电脑）
        final isMediumScreen =
            screenWidth >= 800 && screenWidth < 1200; // 中等屏幕（平板）

        return Padding(
          padding: EdgeInsets.all(
            isLargeScreen ? 32 : (isMediumScreen ? 24 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题区域 - 响应式设计
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '消息中心',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 24 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isLoading && userProvider.isLoggedIn) ...[
                        if (_isSelectionMode) ...[
                          if (_selectedMessageIds.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: _deleteSelectedMessages,
                              icon: const Icon(Icons.delete),
                              label: Text(
                                '删除选中 (${_selectedMessageIds.length})',
                                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isLargeScreen ? 16 : 12,
                                  vertical: isLargeScreen ? 16 : 12,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _toggleSelectionMode,
                            icon: const Icon(Icons.close),
                            label: const Text('取消选择'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLargeScreen ? 16 : 12,
                                vertical: isLargeScreen ? 16 : 12,
                              ),
                            ),
                          ),
                        ] else ...[
                          IconButton(
                            onPressed: _toggleSelectionMode,
                            icon: const Icon(Icons.checklist),
                            tooltip: '选择模式',
                          ),
                          ElevatedButton.icon(
                            onPressed: _loadMessages,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              '刷新',
                              style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLargeScreen ? 16 : 12,
                                vertical: isLargeScreen ? 16 : 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: isLargeScreen ? 24 : 20),

              // 消息列表 - 响应式设计
              Expanded(
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                    child: _buildContent(context, userProvider, isLargeScreen),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, UserProvider userProvider, bool isLargeScreen) {
    if (!userProvider.isLoggedIn) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.message_outlined,
              size: isLargeScreen ? 64 : 48,
              color: AppColors.disabled(context),
            ),
            SizedBox(height: isLargeScreen ? 16 : 12),
            Text(
              '请先登录查看消息',
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                color: AppColors.disabled(context),
              ),
            ),
            SizedBox(height: isLargeScreen ? 24 : 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.login);
              },
              icon: const Icon(Icons.login),
              label: Text(
                '去登录',
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 16 : 12,
                  vertical: isLargeScreen ? 16 : 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: isLargeScreen ? 16 : 12),
            Text(
              '正在加载消息...',
              style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: isLargeScreen ? 64 : 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: isLargeScreen ? 16 : 12),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: isLargeScreen ? 14 : 12,
                color: AppColors.onSurfaceWithOpacity05(context),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isLargeScreen ? 24 : 16),
            ElevatedButton.icon(
              onPressed: _loadMessages,
              icon: const Icon(Icons.refresh),
              label: Text(
                '重试',
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 16 : 12,
                  vertical: isLargeScreen ? 16 : 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: isLargeScreen ? 64 : 48,
              color: AppColors.disabled(context),
            ),
            SizedBox(height: isLargeScreen ? 16 : 12),
            Text(
              '暂无消息',
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                color: AppColors.disabled(context),
              ),
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            Text(
              '您的消息中心是空的',
              style: TextStyle(
                fontSize: isLargeScreen ? 14 : 12,
                color: AppColors.disabled(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageItem(context, message, isLargeScreen);
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, Message message, bool isLargeScreen) {
    final isSelected = _selectedMessageIds.contains(message.id);
    
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: isLargeScreen ? 12 : 8),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: InkWell(
        onTap: _isSelectionMode
            ? () => _toggleMessageSelection(message.id)
            : () {
                // 导航到消息详情页面
                Navigator.pushNamed(
                  context,
                  AppRouter.messageDetail,
                  arguments: {'messageId': message.id},
                ).then((deleted) {
                  // 如果消息被删除，刷新列表
                  if (deleted == true) {
                    _loadMessages();
                  } else {
                    // 即使没有删除，也刷新列表（可能标记为已读）
                    _loadMessages();
                  }
                });
              },
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
          child: Row(
            children: [
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleMessageSelection(message.id),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 16 : 14,
                              fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!message.isRead && !_isSelectionMode)
                          Container(
                            width: isLargeScreen ? 8 : 6,
                            height: isLargeScreen ? 8 : 6,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isLargeScreen ? 8 : 6),
                    Text(
                      _getMessagePreview(message),
                      style: TextStyle(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: AppColors.onSurfaceWithOpacity07(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isLargeScreen ? 12 : 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(message.createdAt),
                          style: TextStyle(
                            fontSize: isLargeScreen ? 12 : 10,
                            color: AppColors.onSurfaceWithOpacity05(context),
                          ),
                        ),
                        if (!_isSelectionMode)
                          Row(
                            children: [
                              if (!message.isRead)
                                TextButton(
                                  onPressed: () => _markAsRead(message.id),
                                  child: Text(
                                    '标记已读',
                                    style: TextStyle(fontSize: isLargeScreen ? 12 : 10),
                                  ),
                                ),
                              SizedBox(width: isLargeScreen ? 8 : 4),
                              TextButton(
                                onPressed: () => _deleteMessage(message.id),
                                child: Text(
                                  '删除',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 12 : 10,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMessagePreview(Message message) {
    // 优先使用summary
    if (message.summary != null && message.summary!.isNotEmpty) {
      return message.summary!;
    }
    
    // 从content生成预览
    String content = message.content;
    if (content.length <= 150) {
      return content;
    }
    
    // 尝试在标点符号处截断
    String truncated = content.substring(0, 150);
    int lastPunctuation = [
      truncated.lastIndexOf('。'),
      truncated.lastIndexOf('！'),
      truncated.lastIndexOf('？'),
      truncated.lastIndexOf('.'),
      truncated.lastIndexOf('!'),
      truncated.lastIndexOf('?'),
    ].reduce((a, b) => a > b ? a : b);
    
    if (lastPunctuation > 75) {  // 如果标点位置合理
       return truncated.substring(0, lastPunctuation + 1);
      }
    
    return '$truncated...';
  }

  String _formatDate(DateTime date) {
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
  }
}