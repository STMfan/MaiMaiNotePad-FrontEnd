import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_text_field.dart';

enum UploadType { knowledge, persona }

class UnifiedUploadScreen extends StatefulWidget {
  final UploadType initialType;

  const UnifiedUploadScreen({
    super.key,
    this.initialType = UploadType.knowledge,
  });

  @override
  State<UnifiedUploadScreen> createState() => _UnifiedUploadScreenState();
}

class _UnifiedUploadScreenState extends State<UnifiedUploadScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ApiService _apiService;

  // 知识库相关
  final _knowledgeNameController = TextEditingController();
  final _knowledgeDescriptionController = TextEditingController();
  final _knowledgeCopyrightController = TextEditingController();
  final _knowledgeTagsController = TextEditingController();
  List<PlatformFile> _knowledgeFiles = [];

  // 人设卡相关
  final _personaNameController = TextEditingController();
  final _personaDescriptionController = TextEditingController();
  final _personaAuthorController = TextEditingController();
  final _personaTagsController = TextEditingController();
  List<PlatformFile> _personaFiles = [];

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == UploadType.knowledge ? 0 : 1,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
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

  Future<void> _pickFiles(UploadType type) async {
    try {
      final isPersona = type == UploadType.persona;
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: isPersona
            ? AppConstants.personaFileTypes
            : AppConstants.knowledgeFileTypes,
        allowMultiple: true,
      );

      if (result != null) {
        // 人设卡限制
        if (isPersona && result.files.length > 2) {
          _showError('人设卡最多只能上传2个文件');
          return;
        }

        // 验证文件格式
        for (var file in result.files) {
          final extension = file.extension?.toLowerCase();
          if (isPersona) {
            if (!AppConstants.personaFileTypes.contains(extension)) {
              _showError('只支持 .toml 格式的文件');
              return;
            }
          } else {
            if (!AppConstants.knowledgeFileTypes.contains(extension)) {
              _showError('不支持的文件格式');
              return;
            }
          }
        }

        setState(() {
          if (isPersona) {
            _personaFiles = result.files;
          } else {
            _knowledgeFiles = result.files;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '已选择 ${isPersona ? _personaFiles.length : _knowledgeFiles.length} 个文件',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showError('选择文件失败: $e');
    }
  }

  Future<void> _uploadFiles() async {
    final currentIndex = _tabController.index;
    final isPersona = currentIndex == 1;

    final nameController = isPersona
        ? _personaNameController
        : _knowledgeNameController;
    final descriptionController = isPersona
        ? _personaDescriptionController
        : _knowledgeDescriptionController;
    final files = isPersona ? _personaFiles : _knowledgeFiles;

    // 表单验证
    if (nameController.text.trim().isEmpty) {
      _showError(isPersona ? '请输入人设卡名称' : '请输入知识库名称');
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      _showError(isPersona ? '请输入人设卡简介' : '请输入知识库简介');
      return;
    }

    if (files.isEmpty) {
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
      if (isPersona) {
        await _uploadPersona(userId);
      } else {
        await _uploadKnowledge(userId);
      }
    } catch (e) {
      _showError('上传失败: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadKnowledge(String userId) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('name', _knowledgeNameController.text.trim()),
      MapEntry('description', _knowledgeDescriptionController.text.trim()),
      MapEntry('uploaderId', userId),
    ]);

    if (_knowledgeCopyrightController.text.trim().isNotEmpty) {
      formData.fields.add(
        MapEntry('copyrightOwner', _knowledgeCopyrightController.text.trim()),
      );
    }

    if (_knowledgeTagsController.text.trim().isNotEmpty) {
      final tags = _knowledgeTagsController.text
          .trim()
          .split(',')
          .map((tag) => tag.trim())
          .join(',');
      formData.fields.add(MapEntry('tags', tags));
    }

    formData.fields.add(MapEntry('starCount', '0'));

    for (var file in _knowledgeFiles) {
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromFileSync(file.path!, filename: file.name),
        ),
      );
    }

    final response = await _apiService.upload('/api/knowledge', formData);

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        _showSuccess('知识库上传成功，等待审核');
        _clearForm(UploadType.knowledge);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        _showError(data['message'] ?? '上传失败');
      }
    } else {
      _showError('上传失败: ${response.statusCode}');
    }
  }

  Future<void> _uploadPersona(String userId) async {
    final metadata = {
      'name': _personaNameController.text.trim(),
      'description': _personaDescriptionController.text.trim(),
      'uploaderId': userId,
      'author': _personaAuthorController.text.trim().isNotEmpty
          ? _personaAuthorController.text.trim()
          : null,
      'tags': _personaTagsController.text.trim().isNotEmpty
          ? _personaTagsController.text
                .trim()
                .split(',')
                .map((tag) => tag.trim())
                .toList()
          : null,
      'starCount': 0,
    };

    final formData = FormData();
    formData.fields.addAll(
      metadata.entries.map((e) => MapEntry(e.key, e.value.toString())),
    );

    for (var file in _personaFiles) {
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromFileSync(file.path!, filename: file.name),
        ),
      );
    }

    final response = await _apiService.upload('/api/persona', formData);

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['success'] == true) {
        _showSuccess('人设卡上传成功，等待审核');
        _clearForm(UploadType.persona);

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        _showError(data['message'] ?? '上传失败');
      }
    } else {
      _showError('上传失败: ${response.statusCode}');
    }
  }

  void _clearForm(UploadType type) {
    if (type == UploadType.knowledge) {
      _knowledgeNameController.clear();
      _knowledgeDescriptionController.clear();
      _knowledgeCopyrightController.clear();
      _knowledgeTagsController.clear();
      _knowledgeFiles.clear();
    } else {
      _personaNameController.clear();
      _personaDescriptionController.clear();
      _personaAuthorController.clear();
      _personaTagsController.clear();
      _personaFiles.clear();
    }
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
    // 获取屏幕尺寸信息
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200; // 大屏幕（电脑）
    final isMediumScreen = screenWidth >= 800 && screenWidth < 1200; // 中等屏幕（平板）
    final isSmallScreen = screenWidth < 800; // 小屏幕（手机）

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '统一上传',
          style: TextStyle(fontSize: isLargeScreen ? 24 : 20),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: isLargeScreen ? 28 : 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(
                Icons.library_books,
                size: isLargeScreen ? 24 : 20,
              ),
              text: '知识库',
            ),
            Tab(
              icon: Icon(
                Icons.person,
                size: isLargeScreen ? 24 : 20,
              ),
              text: '人设卡',
            ),
          ],
          labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildKnowledgeUploadTab(isLargeScreen, isMediumScreen, isSmallScreen),
            _buildPersonaUploadTab(isLargeScreen, isMediumScreen, isSmallScreen),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isLargeScreen, isMediumScreen, isSmallScreen),
    );
  }

  Widget _buildKnowledgeUploadTab(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLargeScreen ? 32 : (isMediumScreen ? 24 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('知识库信息', isLargeScreen, isMediumScreen, isSmallScreen),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _knowledgeNameController,
            labelText: '知识库名称 *',
            hintText: '请输入知识库名称',
            prefixIcon: Icons.title,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _knowledgeDescriptionController,
            labelText: '知识库简介 *',
            hintText: '请输入知识库简介',
            prefixIcon: Icons.description,
            maxLines: 3,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _knowledgeCopyrightController,
            labelText: '版权信息',
            hintText: '请输入版权信息（可选）',
            prefixIcon: Icons.copyright,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _knowledgeTagsController,
            labelText: '标签',
            hintText: '多个标签用逗号分隔（可选）',
            prefixIcon: Icons.tag,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 48 : 32),

          _buildSectionTitle('文件上传', isLargeScreen, isMediumScreen, isSmallScreen),
          SizedBox(height: isLargeScreen ? 24 : 16),

          _buildFilePicker(
            isPersona: false,
            files: _knowledgeFiles,
            onTap: () => _pickFiles(UploadType.knowledge),
            isLargeScreen: isLargeScreen,
            isMediumScreen: isMediumScreen,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaUploadTab(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isLargeScreen ? 32 : (isMediumScreen ? 24 : 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('人设卡信息', isLargeScreen, isMediumScreen, isSmallScreen),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _personaNameController,
            labelText: '人设卡名称 *',
            hintText: '请输入人设卡名称',
            prefixIcon: Icons.title,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _personaDescriptionController,
            labelText: '人设卡简介 *',
            hintText: '请输入人设卡简介',
            prefixIcon: Icons.description,
            maxLines: 3,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _personaAuthorController,
            labelText: '作者',
            hintText: '请输入作者名称（可选）',
            prefixIcon: Icons.person,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 24 : 16),

          CustomTextField(
            controller: _personaTagsController,
            labelText: '标签',
            hintText: '多个标签用逗号分隔（可选）',
            prefixIcon: Icons.tag,
            labelStyle: TextStyle(fontSize: isLargeScreen ? 16 : 14),
            style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
          ),
          SizedBox(height: isLargeScreen ? 48 : 32),

          _buildSectionTitle('文件上传', isLargeScreen, isMediumScreen, isSmallScreen),
          SizedBox(height: isLargeScreen ? 24 : 16),

          _buildFilePicker(
            isPersona: true,
            files: _personaFiles,
            onTap: () => _pickFiles(UploadType.persona),
            isLargeScreen: isLargeScreen,
            isMediumScreen: isMediumScreen,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Row(
      children: [
        Icon(
          Icons.widgets_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: isLargeScreen ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilePicker({
    required bool isPersona,
    required List<PlatformFile> files,
    required VoidCallback onTap,
    required bool isLargeScreen,
    required bool isMediumScreen,
    required bool isSmallScreen,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(isLargeScreen ? 32 : (isMediumScreen ? 24 : 16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_upload,
                size: isLargeScreen ? 80 : (isMediumScreen ? 64 : 48),
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              SizedBox(height: isLargeScreen ? 24 : 16),
              Text(
                '点击选择${isPersona ? '人设卡' : '知识库'}文件',
                style: TextStyle(
                  fontSize: isLargeScreen ? 20 : (isMediumScreen ? 16 : 14),
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isLargeScreen ? 12 : 8),
              Text(
                '支持 PDF、DOCX、TXT、MD 格式',
                style: TextStyle(
                  fontSize: isLargeScreen ? 14 : 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (files.isNotEmpty) ...[
                SizedBox(height: isLargeScreen ? 24 : 16),
                Container(
                  padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '已选择 ${files.length} 个文件：',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 16 : 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: isLargeScreen ? 12 : 8),
                      Column(
                        children: files.map((file) => Padding(
                          padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 4 : 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.insert_drive_file,
                                size: isLargeScreen ? 20 : 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: isLargeScreen ? 12 : 8),
                              Text(
                                file.name,
                                style: TextStyle(
                                  fontSize: isLargeScreen ? 14 : 12,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : () {
                _clearForm(
                  _tabController.index == 1
                      ? UploadType.persona
                      : UploadType.knowledge,
                );
              },
              icon: Icon(
                Icons.clear,
                size: isLargeScreen ? 24 : 20,
              ),
              label: Text(
                '清空表单',
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                padding: EdgeInsets.symmetric(
                  vertical: isLargeScreen ? 16 : 12,
                  horizontal: isLargeScreen ? 24 : 16,
                ),
              ),
            ),
          ),
          SizedBox(width: isLargeScreen ? 24 : 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFiles,
              icon: _isUploading
                  ? SizedBox(
                      width: isLargeScreen ? 24 : 20,
                      height: isLargeScreen ? 24 : 20,
                      child: CircularProgressIndicator(
                        strokeWidth: isLargeScreen ? 3 : 2,
                      ),
                    )
                  : Icon(
                      Icons.upload,
                      size: isLargeScreen ? 24 : 20,
                    ),
              label: Text(
                _isUploading ? '上传中...' : '开始上传',
                style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: isLargeScreen ? 16 : 12,
                  horizontal: isLargeScreen ? 24 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
