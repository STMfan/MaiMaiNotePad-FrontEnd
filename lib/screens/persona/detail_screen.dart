import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/persona.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

import '../../utils/download_helper.dart';

class PersonaDetailScreen extends StatefulWidget {
  final String personaId;

  const PersonaDetailScreen({super.key, required this.personaId});

  @override
  _PersonaDetailScreenState createState() => _PersonaDetailScreenState();
}

class _PersonaDetailScreenState extends State<PersonaDetailScreen> {
  Persona? _persona;
  bool _isLoading = true;
  bool _isStarring = false;
  String? _errorMessage;
  bool _isStarred = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadPersonaDetail();
  }

  Future<void> _loadPersonaDetail() async {
    // 验证 personaId 是否为空
    if (widget.personaId.isEmpty) {
      setState(() {
        _errorMessage = '人设卡ID为空，无法加载详情';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiService = ApiService();

      // 先加载详情，即使收藏状态检查失败也不影响详情显示
      final persona = await apiService.getPersonaDetail(
        widget.personaId,
        userProvider.token,
      );
      
      // 独立检查收藏状态，即使失败也不影响详情加载
      bool isStarred = false;
      try {
        isStarred = await apiService.isPersonaStarred(
          widget.personaId,
          userProvider.token,
        );
      } catch (e) {
        // 收藏状态检查失败不影响详情显示，只记录错误
        debugPrint('检查收藏状态失败: $e');
      }

      setState(() {
        _persona = persona;
        _isStarred = isStarred;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载人设卡详情失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStar() async {
    if (_persona == null || _isStarring) return;

    setState(() {
      _isStarring = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiService = ApiService();

      if (_isStarred) {
        await apiService.unstarPersona(widget.personaId, userProvider.token);
        setState(() {
          _isStarred = false;
          if (_persona != null) {
            _persona = Persona(
              id: _persona!.id,
              name: _persona!.name,
              description: _persona!.description,
              content: _persona!.content,
              uploaderId: _persona!.uploaderId,
              author: _persona!.author,
              authorId: _persona!.authorId,
              tags: _persona!.tags,
              createdAt: _persona!.createdAt,
              updatedAt: _persona!.updatedAt,
              stars: _persona!.stars - 1,
              starCount: _persona!.starCount - 1,
              isPublic: _persona!.isPublic,
              fileNames: _persona!.fileNames,
              downloadUrl: _persona!.downloadUrl,
              previewUrl: _persona!.previewUrl,
              version: _persona!.version,
              size: _persona!.size,
              downloads: _persona!.downloads,
            );
          }
        });
      } else {
        await apiService.starPersona(widget.personaId, userProvider.token);
        setState(() {
          _isStarred = true;
          if (_persona != null) {
            _persona = Persona(
              id: _persona!.id,
              name: _persona!.name,
              description: _persona!.description,
              content: _persona!.content,
              uploaderId: _persona!.uploaderId,
              author: _persona!.author,
              authorId: _persona!.authorId,
              tags: _persona!.tags,
              createdAt: _persona!.createdAt,
              updatedAt: _persona!.updatedAt,
              stars: _persona!.stars + 1,
              starCount: _persona!.starCount + 1,
              isPublic: _persona!.isPublic,
              fileNames: _persona!.fileNames,
              downloadUrl: _persona!.downloadUrl,
              previewUrl: _persona!.previewUrl,
              version: _persona!.version,
              size: _persona!.size,
              downloads: _persona!.downloads,
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

  // 检查当前用户是否有权限删除此人设卡
  bool _canDeletePersona() {
    if (_persona == null) return false;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;
    
    if (currentUser == null) return false;
    
    // 只有上传者、管理员或版主可以删除
    return _persona!.uploaderId == currentUser.id ||
        currentUser.isAdmin ||
        currentUser.isModerator;
  }

  // 删除人设卡
  Future<void> _deletePersona() async {
    if (_persona == null || _isDeleting) return;

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除人设卡 "${_persona!.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final apiService = ApiService();

      await apiService.deletePersona(widget.personaId);

      if (mounted) {
        // 删除成功，返回上一页
        Navigator.of(context).pop(true); // 传递 true 表示已删除，可以用于刷新列表
        
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('人设卡删除成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _launchDownloadUrl() async {
    if (_persona?.downloadUrl == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在下载...')),
      );
    }

    try {
      // 使用 DownloadHelper 下载文件（自动携带 token）
      final success = await DownloadHelper.downloadFile(
        downloadUrl: _persona!.downloadUrl!,
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
        title: const Text('人设卡详情'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (_persona != null) ...[
            // 删除按钮（只有上传者、管理员或版主可见）
            if (_canDeletePersona())
              IconButton(
                icon: _isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                onPressed: _isDeleting ? null : _deletePersona,
                tooltip: '删除人设卡',
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
              tooltip: _isStarred ? '取消收藏' : '收藏',
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
                    onPressed: _loadPersonaDetail,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : _persona == null
          ? const Center(child: Text('人设卡不存在'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称和作者信息
                  Text(
                    _persona!.name,
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
                      Text('作者: ${_persona!.authorName}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '更新时间: ${_formatDate(_persona!.updatedAt ?? _persona!.createdAt)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 预览图片
                  if (_persona!.previewUrl != null) ...[
                    Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: CachedNetworkImage(
                        imageUrl: _persona!.previewUrl!,
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
                  Text(_persona!.description),
                  const SizedBox(height: 16),

                  // 标签
                  if (_persona!.tags.isNotEmpty) ...[
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
                      children: _persona!.tags.map((tag) {
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
                      Text('${_persona!.starCount > 0 ? _persona!.starCount : _persona!.stars} 收藏'),
                      const SizedBox(width: 16),
                      const Icon(Icons.download, size: 20),
                      const SizedBox(width: 4),
                      Text('${_persona!.downloads ?? 0} 下载'),
                    ],
                  ),

                  if (_persona!.version != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20),
                        const SizedBox(width: 4),
                        Text('版本: ${_persona!.version}'),
                      ],
                    ),
                  ],

                  if (_persona!.size != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.storage, size: 20),
                        const SizedBox(width: 4),
                        Text('大小: ${_formatFileSize(_persona!.size!)}'),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 下载按钮
                  if (_persona!.downloadUrl != null) ...[
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
}
