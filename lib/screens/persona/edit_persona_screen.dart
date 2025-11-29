import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/persona.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';

class EditPersonaScreen extends StatefulWidget {
  const EditPersonaScreen({super.key, required this.persona});

  final Persona persona;

  @override
  State<EditPersonaScreen> createState() => _EditPersonaScreenState();
}

class _EditPersonaScreenState extends State<EditPersonaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _copyrightController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.persona.name);
    _descriptionController =
        TextEditingController(text: widget.persona.description);
    _copyrightController =
        TextEditingController(text: widget.persona.copyrightOwner ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _copyrightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
    });
    try {
      final apiService = ApiService();
      await apiService.updatePersona(
        personaId: widget.persona.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        copyrightOwner: _copyrightController.text.trim().isEmpty
            ? null
            : _copyrightController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存成功')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<UserProvider>().currentUser;
    final canEdit = user?.isAdmin == true ||
        user?.isModerator == true ||
        user?.id == widget.persona.uploaderId;

    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('编辑人设卡')),
        body: const Center(child: Text('没有权限编辑该人设卡')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑人设卡'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '名称不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '描述不能为空';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _copyrightController,
                decoration: const InputDecoration(
                  labelText: '版权方（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
