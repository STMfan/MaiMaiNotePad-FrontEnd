import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 修改密码相关
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // 头像相关
  bool _isUploadingAvatar = false;
  bool _isDeletingAvatar = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 修改密码
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          _showSuccess('密码修改成功，请重新登录');
          // 清空表单
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          
          // 延迟后退出登录
          Future.delayed(const Duration(seconds: 1), () async {
            if (mounted) {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              await userProvider.logout();
              // 返回到登录页面
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
        } else {
          _showError(result['message'] ?? '密码修改失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('密码修改失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingPassword = false;
        });
      }
    }
  }

  // 选择头像文件
  Future<void> _pickAvatarImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // 验证文件扩展名
        final extension = file.extension?.toLowerCase();
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        if (extension == null || !allowedExtensions.contains(extension)) {
          _showError('不支持的文件格式，仅支持 JPG、PNG、GIF、WebP');
          return;
        }
        
        // 验证文件大小
        if (file.size > 2 * 1024 * 1024) {
          _showError('文件大小不能超过2MB');
          return;
        }

        await _uploadAvatar(file);
      }
    } catch (e) {
      _showError('选择文件失败: $e');
    }
  }

  // 上传头像
  Future<void> _uploadAvatar(PlatformFile file) async {
    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final apiService = ApiService();
      MultipartFile multipartFile;

      if (kIsWeb) {
        // Web平台使用bytes
        if (file.bytes == null) {
          throw Exception('文件数据不可用');
        }
        multipartFile = MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        );
      } else {
        // 其他平台使用path
        if (file.path == null) {
          throw Exception('文件路径不可用');
        }
        multipartFile = await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        );
      }

      final result = await apiService.uploadAvatarFile(multipartFile);

      if (mounted) {
        if (result['success'] == true) {
          _showSuccess('头像上传成功');
          // 刷新用户信息
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.refreshUserInfo();
        } else {
          _showError(result['message'] ?? '头像上传失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('头像上传失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  // 删除头像
  Future<void> _deleteAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除头像吗？删除后将恢复为默认头像。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeletingAvatar = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.deleteAvatar();

      if (mounted) {
        if (result['success'] == true) {
          _showSuccess('头像已删除');
          // 刷新用户信息
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.refreshUserInfo();
        } else {
          _showError(result['message'] ?? '删除头像失败');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('删除头像失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeletingAvatar = false;
        });
      }
    }
  }

  // 获取头像URL（包含基础URL）
  Future<String?> _getAvatarUrl(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    // 如果已经是完整URL，直接返回
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return avatarUrl;
    }
    // 否则需要拼接基础URL
    try {
      final apiService = ApiService();
      final baseUrl = await apiService.getCurrentBaseUrl();
      // 确保avatarUrl以/开头
      final path = avatarUrl.startsWith('/') ? avatarUrl : '/$avatarUrl';
      return '$baseUrl$path';
    } catch (e) {
      return null;
    }
  }

  // 显示头像（支持首字母头像）
  Widget _buildAvatarWidget(User? user, {double size = 80}) {
    final avatarUrl = user?.avatarUrl;
    final userName = user?.name ?? '?';
    
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // 有上传的头像，使用FutureBuilder异步获取完整URL
      return FutureBuilder<String?>(
        future: _getAvatarUrl(avatarUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              radius: size / 2,
              backgroundImage: NetworkImage(snapshot.data!),
              onBackgroundImageError: (exception, stackTrace) {
                // 如果网络图片加载失败，显示首字母头像
                debugPrint('头像加载失败: $exception');
              },
              child: snapshot.hasError
                  ? _buildInitialAvatar(userName, size)
                  : null,
            );
          }
          // 加载中或失败，显示首字母头像
          return _buildInitialAvatar(userName, size);
        },
      );
    }
    // 没有头像，显示首字母头像
    return _buildInitialAvatar(userName, size);
  }

  // 生成首字母头像
  Widget _buildInitialAvatar(String name, double size) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户设置'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.currentUser;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 头像管理卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '头像管理',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Stack(
                            children: [
                              _buildAvatarWidget(user, size: 100),
                              if (_isUploadingAvatar || _isDeletingAvatar)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isUploadingAvatar || _isDeletingAvatar
                                  ? null
                                  : _pickAvatarImage,
                              icon: const Icon(Icons.upload),
                              label: const Text('上传头像'),
                            ),
                            const SizedBox(width: 16),
                            if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                              ElevatedButton.icon(
                                onPressed: _isUploadingAvatar || _isDeletingAvatar
                                    ? null
                                    : _deleteAvatar,
                                icon: const Icon(Icons.delete),
                                label: const Text('删除头像'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '支持格式：JPG、PNG、GIF、WebP\n最大文件大小：2MB',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 修改密码卡片
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '修改密码',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _currentPasswordController,
                            decoration: InputDecoration(
                              labelText: '当前密码',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrentPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureCurrentPassword = !_obscureCurrentPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureCurrentPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入当前密码';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: '新密码',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureNewPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请输入新密码';
                              }
                              if (value.length < 6) {
                                return '密码长度不能少于6位';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: '确认新密码',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '请确认新密码';
                              }
                              if (value != _newPasswordController.text) {
                                return '两次输入的密码不一致';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isChangingPassword ? null : _changePassword,
                              child: _isChangingPassword
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('修改密码'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

