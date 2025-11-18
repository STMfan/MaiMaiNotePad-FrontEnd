import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_router.dart';
import '../../services/api_service.dart';
import '../../constants/app_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isChangingServer = false;
  final TextEditingController _serverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentServerUrl();
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  void _loadCurrentServerUrl() async {
    final apiService = ApiService();
    final baseUrl = await apiService.getCurrentBaseUrl();
    _serverController.text = baseUrl;
  }

  Future<void> _changeServerUrl() async {
    final newUrl = _serverController.text.trim();

    if (newUrl.isEmpty) {
      _showError('服务器地址不能为空');
      return;
    }

    setState(() {
      _isChangingServer = true;
    });

    try {
      final apiService = ApiService();
      await apiService.updateBaseUrl(newUrl);

      if (mounted) {
        _showSuccess('服务器地址已更新');
      }
    } catch (e) {
      if (mounted) {
        _showError('更新服务器地址失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChangingServer = false;
        });
      }
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

  void _showServerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('切换服务器地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('当前服务器地址:'),
            const SizedBox(height: 8),
            Text(
              _serverController.text,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(
                labelText: '新服务器地址',
                hintText: '请输入新的服务器地址',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _isChangingServer
                ? null
                : () {
                    Navigator.of(context).pop();
                    _changeServerUrl();
                  },
            child: _isChangingServer
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _navigateToAbout() {
    Navigator.pushNamed(context, AppRouter.about);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? '未知用户',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getRoleDisplayName(user?.role ?? ''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 功能列表
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // 主题设置
                ListTile(
                  leading: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                  title: const Text('主题模式'),
                  subtitle: Text(themeProvider.isDarkMode ? '深色模式' : '亮色模式'),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme();
                    },
                  ),
                  onTap: () {
                    themeProvider.toggleTheme();
                  },
                ),

                // 关于应用
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('关于应用'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _navigateToAbout,
                ),

                // 切换服务器
                ListTile(
                  leading: const Icon(Icons.settings_ethernet),
                  title: const Text('切换服务器'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: _showServerDialog,
                ),

                // 版本信息
                ListTile(
                  leading: const Icon(Icons.system_update),
                  title: const Text('版本信息'),
                  subtitle: Text(AppConstants.appVersion),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: AppConstants.appName,
                      applicationVersion: AppConstants.appVersion,
                      applicationIcon: const Icon(Icons.note_alt, size: 48),
                      children: [
                        const Text('麦麦笔记本是MaiBot的非官方内容分享站，主要用于分享知识库和人设卡。'),
                      ],
                    );
                  },
                ),

                // 管理员功能
                if (user?.isAdminOrModerator == true) ...[
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '管理员功能',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  // 审核管理
                  ListTile(
                    leading: const Icon(Icons.approval),
                    title: const Text('审核管理'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: 导航到审核页面
                    },
                  ),
                ],
              ],
            ),

            // 登出按钮
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await userProvider.logout();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.login,
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('退出登录'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return '管理员';
      case 'moderator':
        return '审核员';
      case 'user':
        return '普通用户';
      default:
        return '未知角色';
    }
  }
}
