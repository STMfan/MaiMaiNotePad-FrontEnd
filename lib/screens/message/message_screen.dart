import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  bool _isLoading = false;
  List<Message> _messageList = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiService = ApiService();

      // 获取当前用户的消息
      final response = await apiService.get(
        '/api/messages/user/${userProvider.user?.id}',
      );
      final data = response.data;

      if (data['success'] == true) {
        final messages = data['data'] ?? [];
        setState(() {
          _messageList = messages
              .map((item) => Message.fromJson(item))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '加载消息失败'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载消息失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String messageId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.put('/api/messages/$messageId/read');
      final data = response.data;

      if (data['success'] == true) {
        // 更新本地消息状态
        setState(() {
          final messageIndex = _messageList.indexWhere(
            (msg) => msg.id == messageId,
          );
          if (messageIndex != -1) {
            _messageList[messageIndex] = _messageList[messageIndex].copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
        });
      }
    } catch (e) {
      // 标记已读失败不影响用户体验，静默处理
      debugPrint('标记消息已读失败: $e');
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.delete('/api/messages/$messageId');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _messageList.removeWhere((msg) => msg.id == messageId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('消息已删除'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '删除消息失败'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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

  void _showMessageDetail(Message message) {
    // 如果消息未读，标记为已读
    if (!message.isRead) {
      _markAsRead(message.id);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.content),
              const SizedBox(height: 16),
              Text(
                '发送时间: ${_formatDateTime(message.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (message.readAt != null)
                Text(
                  '阅读时间: ${_formatDateTime(message.readAt!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteMessage(message.id);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messageList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text('暂无消息', style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _messageList.length,
              itemBuilder: (context, index) {
                final message = _messageList[index];
                return MessageCard(
                  message: message,
                  onTap: () => _showMessageDetail(message),
                );
              },
            ),
    );
  }
}

class MessageCard extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;

  const MessageCard({super.key, required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: message.isRead
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          child: Icon(
            message.isRead ? Icons.mail : Icons.mail_outline,
            color: Colors.white,
          ),
        ),
        title: Text(
          message.title,
          style: TextStyle(
            fontWeight: message.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _formatDate(message.createdAt),
          style: TextStyle(
            color: message.isRead
                ? null
                : Theme.of(context).colorScheme.secondary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
