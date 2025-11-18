import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_text_field.dart';

class UploadManagementTabContent extends StatefulWidget {
  const UploadManagementTabContent({super.key});

  @override
  State<UploadManagementTabContent> createState() =>
      _UploadManagementTabContentState();
}

class _UploadManagementTabContentState extends State<UploadManagementTabContent>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  List<Map<String, dynamic>> _uploadHistory = [];
  Map<String, dynamic>? _uploadStats;

  // 上传状态
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';
  String _currentUploadType = ''; // 'knowledge' or 'persona'

  // 知识库相关控制器
  final _knowledgeNameController = TextEditingController();
  final _knowledgeDescriptionController = TextEditingController();
  final _knowledgeCopyrightController = TextEditingController();
  final _knowledgeTagsController = TextEditingController();
  List<PlatformFile> _knowledgeFiles = [];

  // 人设卡相关控制器
  final _personaNameController = TextEditingController();
  final _personaDescriptionController = TextEditingController();
  final _personaAuthorController = TextEditingController();
  final _personaTagsController = TextEditingController();
  List<PlatformFile> _personaFiles = [];

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // 启动动画
    _animationController.forward();

    // 加载上传管理数据
    _loadUploadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    // 清理控制器
    _knowledgeNameController.dispose();
    _knowledgeDescriptionController.dispose();
    _knowledgeCopyrightController.dispose();
    _knowledgeTagsController.dispose();
    _personaNameController.dispose();
    _personaDescriptionController.dispose();
    _personaAuthorController.dispose();
    _personaTagsController.dispose();
    super.dispose();
  }

  Future<void> _loadUploadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 并行加载所有数据
      await Future.wait([_loadUploadHistory(), _loadUploadStats()]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载上传数据失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadUploadHistory() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/admin/upload-history');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _uploadHistory = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _loadUploadStats() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/admin/upload-stats');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _uploadStats = data['data'];
        });
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _pickKnowledgeFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _knowledgeFiles = result.files;
        });
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

  Future<void> _pickPersonaFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _personaFiles = result.files;
        });
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
    if (_knowledgeFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择要上传的文件'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_knowledgeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入知识库名称'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentUploadType = 'knowledge';
      _uploadStatus = '正在上传知识库...';
    });

    try {
      // 模拟上传进度
      for (int i = 0; i <= 50; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _uploadProgress = i / 100.0;
        });
      }

      // 获取文件路径
      final filePaths = _knowledgeFiles.map((file) => file.path!).toList();

      // 解析标签
      final tags = _knowledgeTagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // 调用API上传知识库
      final apiService = ApiService();
      await apiService.uploadKnowledge(
        name: _knowledgeNameController.text.trim(),
        description: _knowledgeDescriptionController.text.trim(),
        filePaths: filePaths,
        content: _knowledgeCopyrightController.text.trim(),
        tags: tags,
        isPublic: false,
      );

      // 完成上传
      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = '知识库上传完成！';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // 重置状态
      setState(() {
        _isUploading = false;
        _currentUploadType = '';
        _knowledgeNameController.clear();
        _knowledgeDescriptionController.clear();
        _knowledgeCopyrightController.clear();
        _knowledgeTagsController.clear();
        _knowledgeFiles.clear();
      });

      // 刷新数据
      await _loadUploadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('知识库上传成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _currentUploadType = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('知识库上传失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadPersona() async {
    if (_personaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择要上传的文件'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_personaNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入人设卡名称'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _currentUploadType = 'persona';
      _uploadStatus = '正在上传人设卡...';
    });

    try {
      // 模拟上传进度
      for (int i = 0; i <= 50; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _uploadProgress = i / 100.0;
        });
      }

      // 获取文件路径
      final filePaths = _personaFiles.map((file) => file.path!).toList();

      // 解析标签
      final tags = _personaTagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      // 调用API上传人设卡
      final apiService = ApiService();
      await apiService.uploadPersona(
        name: _personaNameController.text.trim(),
        description: _personaDescriptionController.text.trim(),
        content: _personaAuthorController.text.trim(),
        filePaths: filePaths,
        tags: tags,
        isPublic: false,
      );

      // 完成上传
      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = '人设卡上传完成！';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      // 重置状态
      setState(() {
        _isUploading = false;
        _currentUploadType = '';
        _personaNameController.clear();
        _personaDescriptionController.clear();
        _personaAuthorController.clear();
        _personaTagsController.clear();
        _personaFiles.clear();
      });

      // 刷新数据
      await _loadUploadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('人设卡上传成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _currentUploadType = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('人设卡上传失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showKnowledgeUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('上传知识库'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _knowledgeNameController,
                  labelText: '知识库名称 *',
                  hintText: '请输入知识库名称',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _knowledgeDescriptionController,
                  labelText: '描述',
                  hintText: '请输入知识库描述',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _knowledgeCopyrightController,
                  labelText: '版权信息',
                  hintText: '请输入版权信息（可选）',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _knowledgeTagsController,
                  labelText: '标签',
                  hintText: '请输入标签，用逗号分隔',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pickKnowledgeFiles();
                        setState(() {}); // 更新对话框状态
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('选择文件'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _knowledgeFiles.isEmpty
                          ? '未选择文件'
                          : '已选择 ${_knowledgeFiles.length} 个文件',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (_knowledgeFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已选择的文件：',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ..._knowledgeFiles.map(
                          (file) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _knowledgeFiles.remove(file);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _uploadKnowledge();
              },
              child: const Text('上传'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonaUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('上传人设卡'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: _personaNameController,
                  labelText: '人设卡名称 *',
                  hintText: '请输入人设卡名称',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _personaDescriptionController,
                  labelText: '描述',
                  hintText: '请输入人设卡描述',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _personaAuthorController,
                  labelText: '作者',
                  hintText: '请输入作者名称',
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _personaTagsController,
                  labelText: '标签',
                  hintText: '请输入标签，用逗号分隔',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pickPersonaFiles();
                        setState(() {}); // 更新对话框状态
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('选择文件'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _personaFiles.isEmpty
                          ? '未选择文件'
                          : '已选择 ${_personaFiles.length} 个文件',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (_personaFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已选择的文件：',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ..._personaFiles.map(
                          (file) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.insert_drive_file, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      _personaFiles.remove(file);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _uploadPersona();
              },
              child: const Text('上传'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUpload(String id) async {
    try {
      final apiService = ApiService();
      final response = await apiService.delete('/api/admin/uploads/$id');
      final data = response.data;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('上传记录已删除'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadUploadData();
      } else {
        _showError(data['message'] ?? '删除失败');
      }
    } catch (e) {
      _showError('删除失败: $e');
    }
  }

  Future<void> _reprocessUpload(String id) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/api/admin/uploads/$id/reprocess',
        data: {},
      );
      final data = response.data;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('正在重新处理文件'),
            backgroundColor: Colors.blue,
          ),
        );
        _loadUploadData();
      } else {
        _showError(data['message'] ?? '重新处理失败');
      }
    } catch (e) {
      _showError('重新处理失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUploadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题和操作按钮
                    Row(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            '上传管理',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            // 上传知识库按钮
                            ElevatedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : () {
                                      _showKnowledgeUploadDialog();
                                    },
                              icon: const Icon(Icons.school),
                              label: const Text('上传知识库'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 上传人设卡按钮
                            ElevatedButton.icon(
                              onPressed: _isUploading
                                  ? null
                                  : () {
                                      _showPersonaUploadDialog();
                                    },
                              icon: const Icon(Icons.person),
                              label: const Text('上传人设卡'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 上传进度条
                    if (_isUploading) ...[
                      _buildUploadProgress(),
                      const SizedBox(height: 24),
                    ],

                    // 统计卡片
                    _buildUploadStatsCards(),
                    const SizedBox(height: 24),

                    // 上传历史
                    _buildUploadHistorySection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUploadProgress() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_upload, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _currentUploadType == 'persona' ? '人设卡上传中' : '知识库上传中',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}% - $_uploadStatus',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadStatsCards() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stats = [
      {
        'title': '总上传数',
        'value': _uploadStats?['totalUploads']?.toString() ?? '0',
        'icon': Icons.upload_file,
        'color': colorScheme.primary,
      },
      {
        'title': '成功处理',
        'value': _uploadStats?['successfulUploads']?.toString() ?? '0',
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'title': '处理失败',
        'value': _uploadStats?['failedUploads']?.toString() ?? '0',
        'icon': Icons.error,
        'color': colorScheme.error,
      },
      {
        'title': '处理中',
        'value': _uploadStats?['processingUploads']?.toString() ?? '0',
        'icon': Icons.hourglass_empty,
        'color': Colors.orange,
      },
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        childAspectRatio: 1.5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: stats.map((stat) {
          return _buildUploadStatCard(
            title: stat['title'] as String,
            value: stat['value'] as String,
            icon: stat['icon'] as IconData,
            color: stat['color'] as Color,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUploadStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadHistorySection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '上传历史',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_uploadHistory.length} 个文件',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_uploadHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无上传记录',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击上方"上传文件"按钮开始上传',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _uploadHistory.map((upload) {
                  return _buildUploadHistoryItem(upload);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadHistoryItem(Map<String, dynamic> upload) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final status = upload['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status, colorScheme);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getFileIcon(upload['fileType']),
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upload['fileName'] ?? '未知文件',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatFileSize(upload['fileSize']),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                upload['uploaderName'] ?? '未知用户',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(upload['uploadedAt']),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          if (upload['errorMessage'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      upload['errorMessage'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (status == 'failed') ...[
                TextButton.icon(
                  onPressed: () => _reprocessUpload(upload['_id']),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重新处理'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton.icon(
                onPressed: () => _deleteUpload(upload['_id']),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('删除'),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'failed':
        return colorScheme.error;
      default:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'success':
        return '成功';
      case 'processing':
        return '处理中';
      case 'failed':
        return '失败';
      default:
        return '未知';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle;
      case 'processing':
        return Icons.hourglass_empty;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  IconData _getFileIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
      case 'md':
        return Icons.text_fields;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '未知大小';

    if (bytes < 1024) {
      return '${bytes}B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) {
      return '未知时间';
    }
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
}
