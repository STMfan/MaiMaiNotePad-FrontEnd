import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/knowledge.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../utils/download_helper.dart';
import '../knowledge/edit_screen.dart';

class KnowledgeDetailScreen extends StatefulWidget {
  final String knowledgeId;

  const KnowledgeDetailScreen({super.key, required this.knowledgeId});

  @override
  _KnowledgeDetailScreenState createState() => _KnowledgeDetailScreenState();
}

class _KnowledgeDetailScreenState extends State<KnowledgeDetailScreen> {
  Knowledge? _knowledge;
  bool _isLoading = true;
  bool _isStarring = false;
  String? _errorMessage;
  bool _isStarred = false;

  @override
  void initState() {
    super.initState();
    _loadKnowledgeDetail();
  }

  Future<void> _loadKnowledgeDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiService = ApiService();

      // 先加载详情，即使收藏状态检查失败也不影响详情显示
      final knowledge = await apiService.getKnowledgeDetail(
        widget.knowledgeId,
        userProvider.token,
      );
      
      // 独立检查收藏状态，即使失败也不影响详情加载
      bool isStarred = false;
      try {
        isStarred = await apiService.isKnowledgeStarred(
          widget.knowledgeId,
          userProvider.token,
        );
      } catch (e) {
        // 收藏状态检查失败不影响详情显示，只记录错误
        debugPrint('检查收藏状态失败: $e');
      }

      setState(() {
        _knowledge = knowledge;
        _isStarred = isStarred;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载知识库详情失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStar() async {
    if (_knowledge == null || _isStarring) return;

    setState(() {
      _isStarring = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiService = ApiService();

      if (_isStarred) {
        await apiService.unstarKnowledge(
          widget.knowledgeId,
          userProvider.token,
        );
        setState(() {
          _isStarred = false;
          if (_knowledge != null) {
            _knowledge = Knowledge(
              id: _knowledge!.id,
              name: _knowledge!.name,
              description: _knowledge!.description,
              uploaderId: _knowledge!.uploaderId,
              copyrightOwner: _knowledge!.copyrightOwner,
              starCount: _knowledge!.starCount - 1,
              isPublic: _knowledge!.isPublic,
              fileNames: _knowledge!.fileNames,
              createdAt: _knowledge!.createdAt,
              updatedAt: _knowledge!.updatedAt,
              content: _knowledge!.content,
              tags: _knowledge!.tags,
              downloads: _knowledge!.downloads,
              downloadUrl: _knowledge!.downloadUrl,
              previewUrl: _knowledge!.previewUrl,
              version: _knowledge!.version,
              size: _knowledge!.size,
            );
          }
        });
      } else {
        await apiService.starKnowledge(widget.knowledgeId, userProvider.token);
        setState(() {
          _isStarred = true;
          if (_knowledge != null) {
            _knowledge = Knowledge(
              id: _knowledge!.id,
              name: _knowledge!.name,
              description: _knowledge!.description,
              uploaderId: _knowledge!.uploaderId,
              copyrightOwner: _knowledge!.copyrightOwner,
              starCount: _knowledge!.starCount + 1,
              isPublic: _knowledge!.isPublic,
              fileNames: _knowledge!.fileNames,
              createdAt: _knowledge!.createdAt,
              updatedAt: _knowledge!.updatedAt,
              content: _knowledge!.content,
              tags: _knowledge!.tags,
              downloads: _knowledge!.downloads,
              downloadUrl: _knowledge!.downloadUrl,
              previewUrl: _knowledge!.previewUrl,
              version: _knowledge!.version,
              size: _knowledge!.size,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
    } finally {
      setState(() {
        _isStarring = false;
      });
    }
  }

  Future<void> _launchDownloadUrl() async {
    if (_knowledge?.downloadUrl == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在下载...')),
      );
    }

    try {
      // 使用 DownloadHelper 下载文件（自动携带 token）
      final success = await DownloadHelper.downloadFile(
        downloadUrl: _knowledge!.downloadUrl!,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('下载成功')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('下载失败，请稍后重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库详情'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (_knowledge != null) ...[
            // 编辑按钮（仅对有权限的用户显示）
            if (_canEditKnowledge())
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: _editKnowledge,
              ),
            // 删除按钮（仅对有权限的用户显示）
            if (_canDeleteKnowledge())
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteKnowledge,
              ),
            // 收藏按钮
            IconButton(
              icon: _isStarring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Icon(
                      _isStarred ? Icons.star : Icons.star_border,
                      color: Colors.white,
                    ),
              onPressed: _toggleStar,
            ),
          ],
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
                    onPressed: _loadKnowledgeDetail,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : _knowledge == null
          ? const Center(child: Text('知识库不存在'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题和作者信息
                  Text(
                    _knowledge!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 4),
                      Text('作者: ${_knowledge!.author}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '更新时间: ${_formatDate(_knowledge!.updatedAt ?? DateTime.now())}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 预览图片
                  if (_knowledge!.previewUrl != null) ...[
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: CachedNetworkImage(
                        imageUrl: _knowledge!.previewUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error, size: 50),
                      ),
                    ),
                  ],

                  // 描述
                  const Text(
                    '描述',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_knowledge!.description),
                  const SizedBox(height: 16),

                  // 标签
                  if (_knowledge!.tags.isNotEmpty) ...[
                    const Text(
                      '标签',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _knowledge!.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: AppTheme.lightOrange,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 统计信息
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber[500], size: 20),
                      const SizedBox(width: 4),
                      Text('${_knowledge!.stars} 收藏'),
                      const SizedBox(width: 16),
                      const Icon(Icons.download, size: 20),
                      const SizedBox(width: 4),
                      Text('${_knowledge!.downloads} 下载'),
                    ],
                  ),

                  if (_knowledge!.version != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 4),
                        Text('版本: ${_knowledge!.version}'),
                      ],
                    ),
                  ],

                  if (_knowledge!.size != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storage, size: 20),
                        const SizedBox(width: 4),
                        Text('大小: ${_formatFileSize(_knowledge!.size!)}'),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 下载按钮
                  if (_knowledge!.downloadUrl != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _launchDownloadUrl,
                        icon: const Icon(Icons.download),
                        label: const Text('下载'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // 编辑知识库
  void _editKnowledge() async {
    if (_knowledge == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/editKnowledge',
      arguments: _knowledge,
    );
    
    if (result == true) {
      // 编辑成功，重新加载数据
      _loadKnowledgeDetail();
    }
  }

  // 检查是否可以删除知识库
  bool _canDeleteKnowledge() {
    if (_knowledge == null) return false;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) return false;
    
    // 上传者、管理员和审核员都可以删除
    return _knowledge!.uploaderId == currentUser.id ||
           currentUser.isAdmin ||
           currentUser.isModerator;
  }

  // 检查是否可以编辑知识库
  bool _canEditKnowledge() {
    if (_knowledge == null) return false;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) return false;
    
    // 上传者、管理员和审核员都可以编辑
    return _knowledge!.uploaderId == currentUser.id ||
           currentUser.isAdmin ||
           currentUser.isModerator;
  }

  // 删除知识库
  void _deleteKnowledge() async {
    if (_knowledge == null) return;
    
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    final isModerator = currentUser?.isModerator ?? false;
    final isUploader = _knowledge!.uploaderId == currentUser?.id;
    
    String? deleteReason;
    
    // 如果是审核员且不是上传者，需要填写删除原因
    if (isModerator && !isUploader) {
      final reasonController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('确定要删除知识库"${_knowledge!.title}"吗？此操作不可恢复。'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: '删除原因',
                  hintText: '请填写删除原因（必填）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写删除原因')),
                  );
                  return;
                }
                deleteReason = reasonController.text.trim();
                Navigator.of(context).pop(true);
              },
              child: const Text('删除'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    } else {
      // 上传者或管理员删除，显示普通确认对话框
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除知识库"${_knowledge!.title}"吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // TODO: 如果后端支持删除原因参数，需要传递deleteReason
      await ApiService().deleteKnowledge(_knowledge!.id);
      
      // 删除成功，返回上一页
      Navigator.of(context).pop(true);
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('知识库删除成功')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: ${e.toString()}')),
      );
    }
  }
}
