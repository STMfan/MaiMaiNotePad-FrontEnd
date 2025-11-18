import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';

class KnowledgeUploadScreen extends StatefulWidget {
  const KnowledgeUploadScreen({super.key});

  @override
  State<KnowledgeUploadScreen> createState() => _KnowledgeUploadScreenState();
}

class _KnowledgeUploadScreenState extends State<KnowledgeUploadScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _copyrightController = TextEditingController();
  final _tagsController = TextEditingController();
  List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _copyrightController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.knowledgeFileTypes,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          _selectedFiles = result.files;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已选择 ${_selectedFiles.length} 个文件'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('选择文件失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadKnowledge() async {
    // 表单验证
    if (_nameController.text.trim().isEmpty) {
      _showError('请输入知识库名称');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showError('请输入知识库简介');
      return;
    }

    if (_selectedFiles.isEmpty) {
      _showError('请选择至少一个文件');
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;

    if (userId == null) {
      _showError('用户信息获取失败，请重新登录');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final apiService = ApiService();

      // 创建元数据 - 根据API.md要求
      final metadata = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'copyright_owner': _copyrightController.text.trim().isNotEmpty
            ? _copyrightController.text.trim()
            : '',
        'isPublic': 'false', // 默认不公开，需要审核
      };

      // 准备文件上传
      final formData = FormData();

      // 添加元数据
      formData.fields.addAll(
        metadata.entries.map((e) => MapEntry(e.key, e.value.toString())),
      );

      // 添加文件
      for (var file in _selectedFiles) {
        formData.files.add(
          MapEntry(
            'files',
            MultipartFile.fromFileSync(file.path!, filename: file.name),
          ),
        );
      }

      final response = await apiService.upload('/api/knowledge/upload', formData);

      if (response.data['success'] == true) {
        _showSuccess('知识库上传成功，等待审核');
        _clearForm();

        // 延迟返回，让用户看到成功消息
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        _showError(response.data['message'] ?? '上传失败');
      }
    } catch (e) {
      _showError('上传失败: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _copyrightController.clear();
    _tagsController.clear();
    setState(() {
      _selectedFiles = [];
    });
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度以适配不同设备
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 800 && screenWidth < 1200;
    
    // 根据设备类型设置不同的边距和布局
    final horizontalPadding = isDesktop ? 64.0 : (isTablet ? 32.0 : 16.0);
    final maxContentWidth = isDesktop ? 800.0 : double.infinity;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传知识库'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_nameController.text.isNotEmpty ||
                _descriptionController.text.isNotEmpty ||
                _selectedFiles.isNotEmpty) {
              // 有未保存的内容，显示确认对话框
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认离开'),
                  content: const Text('您有未保存的内容，确定要离开吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Center(
          child: SizedBox(
            width: maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本信息区域
                _buildSectionTitle('基本信息'),
                const SizedBox(height: 16),

                // 桌面端使用两列布局，移动端使用单列
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _nameController,
                          labelText: '知识库名称',
                          hintText: '请输入知识库名称',
                          prefixIcon: Icons.title,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _copyrightController,
                          labelText: '版权所有者（可选）',
                          hintText: '请输入版权所有者或留空',
                          prefixIcon: Icons.copyright,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: '知识库简介',
                    hintText: '请详细描述知识库的内容和用途',
                    maxLines: 4,
                    prefixIcon: Icons.description,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _tagsController,
                    labelText: '标签（可选）',
                    hintText: '请用逗号分隔多个标签，如：编程,Python,教程',
                    prefixIcon: Icons.tag,
                  ),
                ] else ...[
                  CustomTextField(
                    controller: _nameController,
                    labelText: '知识库名称',
                    hintText: '请输入知识库名称',
                    prefixIcon: Icons.title,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: '知识库简介',
                    hintText: '请详细描述知识库的内容和用途',
                    maxLines: 4,
                    prefixIcon: Icons.description,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _copyrightController,
                    labelText: '版权所有者（可选）',
                    hintText: '请输入版权所有者或留空',
                    prefixIcon: Icons.copyright,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _tagsController,
                    labelText: '标签（可选）',
                    hintText: '请用逗号分隔多个标签，如：编程,Python,教程',
                    prefixIcon: Icons.tag,
                  ),
                ],

                const SizedBox(height: 32),

                // 文件上传区域
                _buildSectionTitle('文件上传'),
                const SizedBox(height: 16),

                _buildFileUploadArea(),

                const SizedBox(height: 32),

                // 提交按钮
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadKnowledge,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isUploading ? '上传中...' : '提交上传'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(
          title == '基本信息' ? Icons.info : Icons.upload_file,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withAlpha(76),
      ),
      child: Column(
        children: [
          // 选择文件按钮
          ElevatedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.file_upload),
            label: const Text('选择文件'),
          ),

          const SizedBox(height: 16),

          // 支持格式说明
          Text(
            '支持格式：${AppConstants.knowledgeFileTypes.join(", ")}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // 已选择文件列表
          if (_selectedFiles.isNotEmpty) ...[
            const Divider(),
            Text(
              '已选择的文件：',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._selectedFiles.map(
              (file) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${(file.size / 1024).toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFiles.clear();
                });
              },
              child: const Text('清空文件'),
            ),
          ],
        ],
      ),
    );
  }
}
