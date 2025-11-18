import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../utils/app_router.dart';

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
        _error = '加载消息失败: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      // 删除消息功能暂不支持，显示提示信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('消息删除功能暂未开放')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      await ApiService().markMessageAsRead(messageId);
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标记已读失败: ${e.toString()}')),
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
                      if (!_isLoading && userProvider.isLoggedIn)
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
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: isLargeScreen ? 16 : 12),
            Text(
              '请先登录查看消息',
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                color: Theme.of(context).disabledColor,
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: isLargeScreen ? 16 : 12),
            Text(
              '暂无消息',
              style: TextStyle(
                fontSize: isLargeScreen ? 18 : 16,
                color: Theme.of(context).disabledColor,
              ),
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            Text(
              '您的消息中心是空的',
              style: TextStyle(
                fontSize: isLargeScreen ? 14 : 12,
                color: Theme.of(context).disabledColor,
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
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: isLargeScreen ? 12 : 8),
      child: InkWell(
        onTap: message.isRead ? null : () => _markAsRead(message.id),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
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
                  if (!message.isRead)
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
                message.content,
                style: TextStyle(
                    fontSize: isLargeScreen ? 14 : 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
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
      ),
    );
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