import 'package:flutter/material.dart';
import 'package:frontend_flutter/utils/app_theme.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('只有管理员可以修改服务器地址')));
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入密码')));
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
      final result = await authService.login(
        currentUser.name,
        passwordController.text,
      );

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('密码验证失败: $e')));
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('服务器地址已更新')));
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
    print(
      '[服务器地址修改日志] $timestamp - 管理员: $adminName - 旧地址: $oldUrl - 新地址: $newUrl',
    );
    // TODO: 如果需要持久化日志，可以保存到SharedPreferences或发送到后端
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isLoggedIn) {
          return const Center(child: Text('请先登录'));
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
                      // 响应式布局：移动端垂直，桌面端横向
                      _buildResponsiveUserInfo(userProvider),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
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
                      title: const Text(
                        '退出登录',
                        style: TextStyle(color: Colors.red),
                      ),
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
  Widget _buildAvatarWidget(UserProvider userProvider, {double size = 50}) {
    final user = userProvider.currentUser;
    final userName = user?.name ?? '?';

    return FutureBuilder<String?>(
      future: _getFullAvatarUrl(user?.avatarUrl ?? ''),
      builder: (context, snapshot) {
        final avatarUrl = snapshot.data;

        if (snapshot.hasData && avatarUrl != null && avatarUrl.isNotEmpty) {
          // 有头像URL时，使用NetworkImage
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: size,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
              onBackgroundImageError: (exception, stackTrace) {
                debugPrint('头像加载失败: $exception');
                // 网络图片加载失败，显示首字母头像
              },
            ),
          );
        }

        // 没有头像、加载失败或加载中，显示首字母头像
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: size,
            backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
            child: snapshot.hasError
                ? const Icon(Icons.error, color: Colors.white)
                : _buildInitialAvatar(userName, size),
          ),
        );
      },
    );
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

  Widget _buildResponsiveUserInfo(UserProvider userProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    if (isMobile) {
      // 移动端：垂直居中排列，更紧凑的间距
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatarWidget(userProvider),
            const SizedBox(height: 16),
            _buildUserInfoList(userProvider),
          ],
        ),
      );
    } else if (isTablet) {
      // 平板端：紧凑的横向布局
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAvatarWidget(userProvider, size: 60),
          const SizedBox(width: 24),
          Expanded(child: _buildUserInfoList(userProvider, compact: true)),
        ],
      );
    } else {
      // 桌面端：更平衡的横向布局
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAvatarWidget(userProvider, size: 70),
          const SizedBox(width: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 350),
            child: _buildUserInfoList(userProvider),
          ),
        ],
      );
    }
  }

  // 构建用户信息列表
  Widget _buildUserInfoList(UserProvider userProvider, {bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 用户名信息 - 突出显示
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
                size: compact ? 16 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProvider.currentUser?.name ?? '未知用户',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '用户名',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: compact ? 6 : 12),

        // 邮箱信息
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.email,
                color: Theme.of(context).colorScheme.primary,
                size: compact ? 16 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProvider.currentUser?.email ?? '未知邮箱',
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '邮箱地址',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 用户角色信息（如果存在）
        if (userProvider.currentUser?.role != null) ...[
          SizedBox(height: compact ? 6 : 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                  size: compact ? 16 : 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getRoleDisplayName(userProvider.currentUser!.role),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '用户角色',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('已退出登录')));
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
