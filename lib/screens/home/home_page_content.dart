import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_router.dart';
import '../../utils/app_colors.dart';

// 主页内容组件
class HomePageContent extends StatelessWidget {
  final VoidCallback? onUploadPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onAdminPressed;

  const HomePageContent({
    super.key,
    this.onUploadPressed,
    this.onProfilePressed,
    this.onAdminPressed,
  });

  // 构建欢迎内容 - 响应式设计
  List<Widget> _buildWelcomeContent(
    BuildContext context,
    UserProvider userProvider,
    bool isLargeScreen,
  ) {
    final logoSize = isLargeScreen ? 64.0 : 48.0;
    final titleStyle = isLargeScreen
        ? Theme.of(context).textTheme.headlineMedium
        : Theme.of(context).textTheme.headlineSmall;
    final bodyStyle = isLargeScreen
        ? Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16)
        : Theme.of(context).textTheme.bodyLarge;

    return [
      SizedBox(
        width: logoSize,
        height: logoSize,
        child: Image.asset(
          'assets/logo/logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.school,
              size: logoSize,
              color: Theme.of(context).colorScheme.primary,
            );
          },
        ),
      ),
      SizedBox(width: isLargeScreen ? 24 : 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppConstants.appName},让每个人的麦麦都变得好聪明好聪明！o(*￣▽￣*)ブ',
              style: titleStyle,
            ),
            SizedBox(height: isLargeScreen ? 12 : 8),
            if (userProvider.isLoggedIn) ...[
              Text(
                '你好，${userProvider.currentUser?.name ?? '用户'}!',
                style: bodyStyle,
              ),
              Text(
                '角色：${userProvider.currentUser?.role ?? '普通用户'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: isLargeScreen ? 14 : null,
                ),
              ),
            ] else ...[
              Text('请先登录以体验更多功能', style: bodyStyle),
              SizedBox(height: isLargeScreen ? 20 : 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRouter.login);
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24 : 16,
                    vertical: isLargeScreen ? 16 : 12,
                  ),
                ),
                child: Text(
                  '去登录',
                  style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                ),
              ),
            ],
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        // 获取屏幕尺寸信息
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1200; // 大屏幕（电脑）
        final isMediumScreen =
            screenWidth >= 800 && screenWidth < 1200; // 中等屏幕（平板）
        final isSmallScreen = screenWidth < 800; // 小屏幕（手机）

        return Container(
          padding: EdgeInsets.all(
            isLargeScreen ? 32 : (isMediumScreen ? 24 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎区域 - 响应式布局
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 32 : 24),
                  child: isSmallScreen
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: _buildWelcomeContent(
                            context,
                            userProvider,
                            isLargeScreen,
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildWelcomeContent(
                            context,
                            userProvider,
                            isLargeScreen,
                          ),
                        ),
                ),
              ),
              SizedBox(height: isLargeScreen ? 24 : 20),

              // 快速操作区域 - 响应式网格
              if (userProvider.isLoggedIn) ...[
                Text(
                  '快速操作',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: isLargeScreen ? 24 : null,
                  ),
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 根据屏幕尺寸和内容区域宽度动态计算列数
                    int crossAxisCount;
                    double childAspectRatio;

                    if (isLargeScreen && constraints.maxWidth > 1000) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.6;
                    } else if (isMediumScreen || constraints.maxWidth > 600) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.4;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 1.2;
                    }

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: isLargeScreen ? 24 : 16,
                      mainAxisSpacing: isLargeScreen ? 24 : 16,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildQuickActionCard(
                          context,
                          '上传知识库',
                          Icons.upload_file,
                          '分享您的知识库文件',
                          () {
                            // 使用回调函数导航到上传管理
                            if (onUploadPressed != null) {
                              onUploadPressed!();
                            }
                          },
                          isLargeScreen,
                        ),
                        _buildQuickActionCard(
                          context,
                          '创建人设卡',
                          Icons.person_add,
                          '设计和分享角色人设卡',
                          () {
                            // 使用回调函数导航到上传管理
                            if (onUploadPressed != null) {
                              onUploadPressed!();
                            }
                          },
                          isLargeScreen,
                        ),
                        _buildQuickActionCard(
                          context,
                          '浏览知识库',
                          Icons.explore,
                          '探索其他用户的知识库',
                          () {
                            Navigator.pushNamed(context, AppRouter.knowledge);
                          },
                          isLargeScreen,
                        ),
                        _buildQuickActionCard(
                          context,
                          '个人资料',
                          Icons.settings,
                          '管理个人信息和设置',
                          () {
                            // 使用回调函数导航到个人资料
                            if (onProfilePressed != null) {
                              onProfilePressed!();
                            }
                          },
                          isLargeScreen,
                        ),
                        if (userProvider.currentUser?.isAdminOrModerator ==
                            true) ...[
                          _buildQuickActionCard(
                            context,
                            '上传管理',
                            Icons.cloud_upload,
                            '管理文件上传',
                            onUploadPressed!,
                            isLargeScreen,
                          ),
                          if (userProvider.currentUser?.role == 'admin') ...[
                            _buildQuickActionCard(
                              context,
                              '管理员概览',
                              Icons.admin_panel_settings,
                              '查看系统统计信息',
                              onAdminPressed!,
                              isLargeScreen,
                            ),
                          ],
                        ],
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 构建快速操作卡片 - 响应式设计
  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onPressed,
    bool isLargeScreen,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isLargeScreen ? 40 : 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(height: isLargeScreen ? 12 : 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isLargeScreen ? 14 : 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargeScreen ? 6 : 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: isLargeScreen ? 12 : 10,
                  color: AppColors.onSurfaceWithOpacity05(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
