import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/user_provider.dart';

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

  void _showServerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('服务器设置'),
          content: TextField(
            controller: _serverController,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: '例如: http://localhost:8000',
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
                  await ApiService().updateBaseUrl(newUrl);
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
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(userProvider.currentUser?.name ?? '未知用户'),
                        subtitle: Text(userProvider.currentUser?.email ?? ''),
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
                      title: const Text('设置'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: 打开设置页面
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.dns),
                      title: const Text('服务器设置'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: _showServerDialog,
                    ),
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