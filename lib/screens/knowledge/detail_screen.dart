import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/knowledge.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/download_helper.dart';
import '../../viewmodels/knowledge_detail_viewmodel.dart';
import '../../widgets/async_state_view.dart';

class KnowledgeDetailScreen extends StatelessWidget {
  const KnowledgeDetailScreen({super.key, required this.knowledgeId});

  final String knowledgeId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          KnowledgeDetailViewModel(knowledgeId: knowledgeId)..load(),
      child: const _KnowledgeDetailView(),
    );
  }
}

class _KnowledgeDetailView extends StatelessWidget {
  const _KnowledgeDetailView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KnowledgeDetailViewModel>();
    final knowledge = viewModel.knowledge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库详情'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (knowledge != null) ...[
            if (_canEditKnowledge(context, knowledge))
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => _editKnowledge(context, knowledge),
              ),
            if (_canDeleteKnowledge(context, knowledge))
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () => _deleteKnowledge(context),
              ),
            IconButton(
              icon: viewModel.isStarring
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Icon(
                      viewModel.isStarred ? Icons.star : Icons.star_border,
                      color: Colors.white,
                    ),
              onPressed: viewModel.toggleStar,
            ),
          ],
        ],
      ),
      body: AsyncStateView(
        isLoading: viewModel.isLoading,
        errorMessage: viewModel.errorMessage,
        onRetry: () => context.read<KnowledgeDetailViewModel>().load(),
        isEmpty: knowledge == null,
        emptyWidget: const Center(child: Text('知识库不存在')),
        builder: (_) => _KnowledgeDetailBody(knowledge: knowledge!),
      ),
    );
  }

  static bool _canEditKnowledge(BuildContext context, Knowledge knowledge) {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return false;
    return knowledge.uploaderId == user.id || user.isAdmin || user.isModerator;
  }

  static bool _canDeleteKnowledge(BuildContext context, Knowledge knowledge) {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return false;
    return knowledge.uploaderId == user.id || user.isAdmin || user.isModerator;
  }

  Future<void> _editKnowledge(BuildContext context, Knowledge knowledge) async {
    final result = await Navigator.pushNamed(
      context,
      '/editKnowledge',
      arguments: knowledge,
    );
    if (result == true && context.mounted) {
      await context.read<KnowledgeDetailViewModel>().load();
    }
  }

  Future<void> _deleteKnowledge(BuildContext context) async {
    final viewModel = context.read<KnowledgeDetailViewModel>();
    final knowledge = viewModel.knowledge;
    if (knowledge == null) {
      return;
    }

    final user = context.read<UserProvider>().currentUser;
    final isModerator = user?.isModerator ?? false;
    final isUploader = user?.id == knowledge.uploaderId;
    String? deleteReason;

    if (isModerator && !isUploader) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('确定要删除知识库"${knowledge.title}"吗？此操作不可恢复。'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
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
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请填写删除原因')),
                  );
                  return;
                }
                deleteReason = controller.text.trim();
                Navigator.of(context).pop(true);
              },
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (confirmed != true) {
        return;
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除知识库"${knowledge.title}"吗？此操作不可恢复。'),
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
      if (confirmed != true) {
        return;
      }
    }

    try {
      await viewModel.deleteKnowledge();
      if (context.mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('知识库删除成功')),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      final reasonSuffix =
          deleteReason != null ? '\n原因: $deleteReason' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $error$reasonSuffix')),
      );
    }
  }
}

class _KnowledgeDetailBody extends StatelessWidget {
  const _KnowledgeDetailBody({required this.knowledge});

  final Knowledge knowledge;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<KnowledgeDetailViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            knowledge.title,
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
              Text('作者: ${knowledge.author ?? '未知'}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: 4),
              Text(
                '更新时间: ${_formatDate(knowledge.updatedAt ?? DateTime.now())}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (knowledge.previewUrl != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              child: CachedNetworkImage(
                imageUrl: knowledge.previewUrl!,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, size: 50),
              ),
            ),
          ],
          const Text(
            '描述',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(knowledge.description),
          const SizedBox(height: 16),
          if (knowledge.tags.isNotEmpty) ...[
            const Text(
              '标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: knowledge.tags
                  .map(
                    (tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppTheme.lightOrange,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[500], size: 20),
              const SizedBox(width: 4),
              Text('${knowledge.stars} 收藏'),
              const SizedBox(width: 16),
              const Icon(Icons.download, size: 20),
              const SizedBox(width: 4),
              Text('${knowledge.downloads} 下载'),
            ],
          ),
          if (knowledge.version != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 4),
                Text('版本: ${knowledge.version}'),
              ],
            ),
          ],
          if (knowledge.size != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 4),
                Text('大小: ${_formatFileSize(knowledge.size!)}'),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            '文件列表',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (knowledge.files.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('暂无可下载文件'),
            )
          else
            Column(
              children: knowledge.files.map((file) {
                final isDeleting = viewModel.deletingFileId == file.fileId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(file.originalName),
                    subtitle: Text('大小: ${_formatFileSize(file.fileSize)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download),
                          tooltip: '下载文件',
                          onPressed: () => _downloadSingleFile(context, file),
                        ),
                        if (_KnowledgeDetailView._canDeleteKnowledge(
                            context, knowledge))
                          isDeleting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: '删除文件',
                                  onPressed: () =>
                                      _deleteKnowledgeFile(context, file),
                                ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          if (knowledge.downloadUrl != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchDownloadUrl(context),
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
      ),
    );
  }

  Future<void> _launchDownloadUrl(BuildContext context) async {
    if (knowledge.downloadUrl == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在下载...')),
    );
    try {
      final success = await DownloadHelper.downloadFile(
        downloadUrl: knowledge.downloadUrl!,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '下载成功' : '下载失败，请稍后重试'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('下载失败: $error')),
      );
    }
  }

  Future<void> _downloadSingleFile(
    BuildContext context,
    KnowledgeFile file,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('正在下载 ${file.originalName}...')),
    );
    final success = await DownloadHelper.downloadFile(
      downloadUrl: '/api/knowledge/${knowledge.id}/file/${file.fileId}',
      filename: file.originalName,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '下载成功' : '下载失败，请稍后重试'),
      ),
    );
  }

  Future<void> _deleteKnowledgeFile(
    BuildContext context,
    KnowledgeFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除文件'),
        content: Text('确定要删除文件 "${file.originalName}" 吗？此操作不可恢复。'),
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
    if (confirmed != true) {
      return;
    }
    final viewModel = context.read<KnowledgeDetailViewModel>();
    final result = await viewModel.deleteFile(file.fileId);
    if (!context.mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('删除文件失败，请稍后重试')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    if (result.knowledgeDeleted) {
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }
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


