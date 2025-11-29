import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_router.dart';

class ProfileTabContent extends StatefulWidget {
  const ProfileTabContent({super.key});

  @override
  State<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<ProfileTabContent> {
  final TextEditingController _serverController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  void _loadCurrentServer() async {
    final currentUrl = await ApiService().getCurrentBaseUrl();
    setState(() {
      _serverController.text = currentUrl;
    });
  }

  void _showServerDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null || currentUser.role != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只有管理员可以修改服务器地址')),
      );
      return;
    }
    
    // 第一步：显示密码确认对话框
    final passwordController = TextEditingController();
    final passwordConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('管理员身份确认'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('为了安全，请再次输入管理员密码以确认操作：'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '管理员密码',
                hintText: '请输入管理员密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入密码')),
                );
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
    
    if (passwordConfirmed != true) return;
    
    // 验证密码
    try {
      final authService = AuthService();
      final result = await authService.login(currentUser.name, passwordController.text);
      
      if (!result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('密码验证失败: ${result['message']}')),
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('密码验证失败: $e')),
        );
      }
      return;
    }
    
    // 第二步：显示服务器地址修改对话框
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('服务器设置'),
          content: TextField(
            controller: _serverController,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: '例如: http://hk-2.lcf.im:10103',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final newUrl = _serverController.text.trim();
                if (newUrl.isNotEmpty) {
                  final oldUrl = await ApiService().getCurrentBaseUrl();
                  await ApiService().updateBaseUrl(newUrl);
                  
                  // 记录日志
                  _logServerChange(currentUser.name, oldUrl, newUrl);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('服务器地址已更新')),
                    );
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
  
  // 记录服务器地址修改日志
  void _logServerChange(String adminName, String oldUrl, String newUrl) {
    final timestamp = DateTime.now().toIso8601String();
    print('[服务器地址修改日志] $timestamp - 管理员: $adminName - 旧地址: $oldUrl - 新地址: $newUrl');
    // TODO: 如果需要持久化日志，可以保存到SharedPreferences或发送到后端
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isLoggedIn) {
          return const Center(
            child: Text('请先登录'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '个人信息',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 头像显示
                      Center(
                        child: _buildAvatarWidget(userProvider.currentUser),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(userProvider.currentUser?.name ?? '未知用户'),
                        subtitle: const Text('用户名'),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(userProvider.currentUser?.email ?? '未知邮箱'),
                        subtitle: const Text('邮箱地址'),
                      ),
                      if (userProvider.currentUser?.role != null) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.security),
                          title: Text(_getRoleDisplayName(userProvider.currentUser!.role)),
                          subtitle: const Text('用户角色'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('用户设置'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.settings);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.folder_shared),
                      title: const Text('我的知识库与人设卡'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.myContent);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.star),
                      title: const Text('我的收藏'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushNamed(context, '/stars');
                      },
                    ),
                    // 服务器设置（仅管理员可见）
                    if (userProvider.currentUser?.role == 'admin') ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.dns),
                        title: const Text('服务器设置'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: _showServerDialog,
                      ),
                    ],
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('关于'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'MaiMNP',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2024 MaiMNP Team',
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                      onTap: () => _showLogoutDialog(userProvider),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '管理员';
      case 'moderator':
        return '审核员';
      case 'user':
        return '普通用户';
      default:
        return role;
    }
  }

  // 获取头像URL（包含基础URL）
  Future<String?> _getFullAvatarUrl(String? avatarUrl) async {
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
  Widget _buildAvatarWidget(user) {
    final avatarUrl = user?.avatarUrl;
    final userName = user?.name ?? '?';
    
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      // 有上传的头像，使用FutureBuilder异步获取完整URL
      return FutureBuilder<String?>(
        future: _getFullAvatarUrl(avatarUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(snapshot.data!),
              onBackgroundImageError: (exception, stackTrace) {
                // 如果网络图片加载失败，显示首字母头像
                debugPrint('头像加载失败: $exception');
              },
              child: snapshot.hasError
                  ? _buildInitialAvatar(userName, 100)
                  : null,
            );
          }
          // 加载中或失败，显示首字母头像
          return _buildInitialAvatar(userName, 100);
        },
      );
    }
    // 没有头像，显示首字母头像
    return _buildInitialAvatar(userName, 100);
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

  void _showLogoutDialog(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认退出'),
          content: const Text('您确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await userProvider.logout();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已退出登录')),
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
