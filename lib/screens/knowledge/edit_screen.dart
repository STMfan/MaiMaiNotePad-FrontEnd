import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../../models/knowledge.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';

class EditKnowledgeScreen extends StatefulWidget {
  final Knowledge knowledge;

  const EditKnowledgeScreen({
    super.key,
    required this.knowledge,
  });

  @override
  State<EditKnowledgeScreen> createState() => _EditKnowledgeScreenState();
}

class _EditKnowledgeScreenState extends State<EditKnowledgeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _copyrightController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPublic = false;
  List<String> _selectedFiles = [];
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    // 初始化表单数据
    _nameController.text = widget.knowledge.title;
    _descriptionController.text = widget.knowledge.description;
    _tagsController.text = widget.knowledge.tags.join(', ');
    _copyrightController.text = widget.knowledge.copyright ?? '';
    _isPublic = widget.knowledge.isPublic;
    _tags = List.from(widget.knowledge.tags);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _copyrightController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            // Web 平台：使用文件名作为标识
            _selectedFiles = result.files.map((file) => file.name).toList();
          } else {
            // 其他平台：使用文件路径
            _selectedFiles = result.paths
                .where((path) => path != null)
                .map((path) => path!)
                .toList();
          }
        });
      }
    } catch (e) {
      _showError('选择文件失败: ${e.toString()}');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _updateTags() {
    final tagsText = _tagsController.text.trim();
    if (tagsText.isNotEmpty) {
      setState(() {
        _tags = tagsText.split(',').map((tag) => tag.trim()).toList();
      });
    }
  }

  Future<void> _updateKnowledge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().updateKnowledge(
        knowledgeId: widget.knowledge.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        copyrightOwner: _copyrightController.text.trim().isNotEmpty
            ? _copyrightController.text.trim()
            : null,
      );

      _showSuccess('知识库更新成功');
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('更新失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600 && screenWidth <= 1200;

    double containerWidth = screenWidth;
    if (isDesktop) {
      containerWidth = 800;
    } else if (isTablet) {
      containerWidth = screenWidth * 0.8;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑知识库'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: containerWidth),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 名称
                  CustomTextField(
                    controller: _nameController,
                    labelText: '名称',
                    hintText: '请输入知识库名称',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入知识库名称';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 简介
                  CustomTextField(
                    controller: _descriptionController,
                    labelText: '简介',
                    hintText: '请输入知识库简介',
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入知识库简介';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 版权所有者
                  CustomTextField(
                    controller: _copyrightController,
                    labelText: '版权所有者',
                    hintText: '请输入版权所有者',
                  ),
                  const SizedBox(height: 16),

                  // 标签
                  CustomTextField(
                    controller: _tagsController,
                    labelText: '标签',
                    hintText: '请输入标签，多个标签用逗号分隔',
                    onChanged: (_) => _updateTags(),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: AppTheme.lightOrange,
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                            _tagsController.text = _tags.join(', ');
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 是否公开
                  Row(
                    children: [
                      Checkbox(
                        value: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryOrange,
                      ),
                      const Text('公开知识库'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 文件选择提示
                  const Text(
                    '注意：编辑功能不包含文件替换。如需更换文件，请删除后重新上传。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 提交按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateKnowledge,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('更新知识库'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}