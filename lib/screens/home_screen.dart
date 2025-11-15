import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/knowledge.dart';
import '../models/persona.dart';
import '../models/message.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../constants/app_constants.dart';
import '../utils/app_router.dart';
import 'admin_overview_tab_content.dart';
import 'upload_management_tab_content.dart';

// 主页内容组件
class HomePageContent extends StatelessWidget {
  final VoidCallback? onUploadPressed;
  final VoidCallback? onAdminPressed;

  const HomePageContent({super.key, this.onUploadPressed, this.onAdminPressed});

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
            Text('欢迎使用 ${AppConstants.appName}', style: titleStyle),
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
                            Navigator.pushNamed(
                              context,
                              AppRouter.knowledgeUpload,
                            );
                          },
                          isLargeScreen,
                        ),
                        _buildQuickActionCard(
                          context,
                          '创建人设卡',
                          Icons.person_add,
                          '设计和分享角色人设卡',
                          () {
                            Navigator.pushNamed(
                              context,
                              AppRouter.personaUpload,
                            );
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
                            Navigator.pushNamed(context, AppRouter.profile);
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
                  color: Theme.of(context).textTheme.bodySmall?.color,
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

// 知识库标签页内容
class KnowledgeTabContent extends StatelessWidget {
  final List<Knowledge> knowledgeList;
  final TextEditingController searchController;
  final Function(String) onSearch;

  const KnowledgeTabContent({
    super.key,
    required this.knowledgeList,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸信息
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200; // 大屏幕（电脑）
    final isMediumScreen = screenWidth >= 800 && screenWidth < 1200; // 中等屏幕（平板）

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.library_books,
                  size: isLargeScreen ? 120 : (isMediumScreen ? 100 : 80),
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                Text(
                  '请先登录',
                  style: isLargeScreen
                      ? Theme.of(context).textTheme.displaySmall
                      : Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: isLargeScreen ? 32 : 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.login);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 32 : 24,
                      vertical: isLargeScreen ? 16 : 12,
                    ),
                  ),
                  child: Text(
                    '去登录',
                    style: TextStyle(fontSize: isLargeScreen ? 18 : 16),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(
            isLargeScreen ? 24 : (isMediumScreen ? 20 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索区域 - 响应式设计
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(
                    isLargeScreen ? 24 : (isMediumScreen ? 20 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '知识库浏览',
                        style: isLargeScreen
                            ? Theme.of(context).textTheme.headlineMedium
                            : Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: isLargeScreen ? 16 : 12),

                      // 搜索框 - 响应式尺寸
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: '搜索知识库',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 20 : 16,
                            vertical: isLargeScreen ? 16 : 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                        onChanged: onSearch,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isLargeScreen ? 32 : 24),

              // 知识库列表 - 响应式布局
              Text(
                '知识库列表',
                style: isLargeScreen
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: isLargeScreen ? 24 : 16),

              if (knowledgeList.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Container(
                    padding: EdgeInsets.all(
                      isLargeScreen ? 48 : (isMediumScreen ? 32 : 24),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.library_books,
                          size: isLargeScreen ? 96 : (isMediumScreen ? 64 : 48),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: isLargeScreen ? 24 : 16),
                        Text(
                          searchController.text.isEmpty ? '暂无知识库' : '未找到匹配的知识库',
                          style: isLargeScreen
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 根据屏幕尺寸确定网格列数
                    int crossAxisCount;
                    if (isLargeScreen) {
                      crossAxisCount = 3; // 大屏幕：3列
                    } else if (isMediumScreen) {
                      crossAxisCount = 2; // 中等屏幕：2列
                    } else {
                      crossAxisCount = 1; // 小屏幕：1列
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: isLargeScreen
                            ? 1.8
                            : (isMediumScreen ? 1.5 : 1.2),
                        crossAxisSpacing: isLargeScreen ? 16 : 12,
                        mainAxisSpacing: isLargeScreen ? 16 : 12,
                      ),
                      itemCount: knowledgeList.length,
                      itemBuilder: (context, index) {
                        final knowledge = knowledgeList[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('查看知识库: ${knowledge.name}'),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isLargeScreen ? 16 : (isMediumScreen ? 14 : 12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.library_books,
                                        size: isLargeScreen ? 28 : 20,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      SizedBox(width: isLargeScreen ? 12 : 8),
                                      Expanded(
                                        child: Text(
                                          knowledge.name,
                                          style: TextStyle(
                                            fontSize: isLargeScreen ? 16 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isLargeScreen ? 8 : 6),
                                  Text(
                                    knowledge.description,
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 12 : 10,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isLargeScreen ? 8 : 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '创建者: ${knowledge.authorName}',
                                        style: TextStyle(
                                          fontSize: isLargeScreen ? 12 : 10,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      Text(
                                        '${knowledge.downloads} 下载',
                                        style: TextStyle(
                                          fontSize: isLargeScreen ? 12 : 10,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// 人设卡标签页内容
class PersonaTabContent extends StatelessWidget {
  final List<Persona> personaList;
  final TextEditingController searchController;
  final Function(String) onSearch;

  const PersonaTabContent({
    super.key,
    required this.personaList,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸信息
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200; // 大屏幕（电脑）
    final isMediumScreen = screenWidth >= 800 && screenWidth < 1200; // 中等屏幕（平板）

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: isLargeScreen ? 120 : (isMediumScreen ? 100 : 80),
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: isLargeScreen ? 24 : 16),
                Text(
                  '请先登录',
                  style: isLargeScreen
                      ? Theme.of(context).textTheme.displaySmall
                      : Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: isLargeScreen ? 32 : 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.login);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 32 : 24,
                      vertical: isLargeScreen ? 16 : 12,
                    ),
                  ),
                  child: Text(
                    '去登录',
                    style: TextStyle(fontSize: isLargeScreen ? 18 : 16),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(
            isLargeScreen ? 32 : (isMediumScreen ? 24 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索区域 - 响应式设计
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(
                    isLargeScreen ? 32 : (isMediumScreen ? 24 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '人设卡浏览',
                        style: isLargeScreen
                            ? Theme.of(context).textTheme.headlineMedium
                            : Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: isLargeScreen ? 24 : 16),

                      // 搜索框 - 响应式尺寸
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          labelText: '搜索人设卡',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 20 : 16,
                            vertical: isLargeScreen ? 16 : 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isLargeScreen ? 16 : 14),
                        onChanged: onSearch,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isLargeScreen ? 32 : 24),

              // 人设卡列表 - 响应式布局
              Text(
                '人设卡列表',
                style: isLargeScreen
                    ? Theme.of(context).textTheme.headlineMedium
                    : Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: isLargeScreen ? 24 : 16),

              if (personaList.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: Container(
                    padding: EdgeInsets.all(
                      isLargeScreen ? 48 : (isMediumScreen ? 32 : 24),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person,
                          size: isLargeScreen ? 96 : (isMediumScreen ? 64 : 48),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: isLargeScreen ? 24 : 16),
                        Text(
                          searchController.text.isEmpty ? '暂无人设卡' : '未找到匹配的人设卡',
                          style: isLargeScreen
                              ? Theme.of(context).textTheme.headlineSmall
                              : Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 根据屏幕尺寸确定网格列数
                    int crossAxisCount;
                    if (isLargeScreen) {
                      crossAxisCount = 3; // 大屏幕：3列
                    } else if (isMediumScreen) {
                      crossAxisCount = 2; // 中等屏幕：2列
                    } else {
                      crossAxisCount = 1; // 小屏幕：1列
                    }

                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: isLargeScreen
                            ? 1.8
                            : (isMediumScreen ? 1.5 : 1.2),
                        crossAxisSpacing: isLargeScreen ? 24 : 16,
                        mainAxisSpacing: isLargeScreen ? 24 : 16,
                      ),
                      itemCount: personaList.length,
                      itemBuilder: (context, index) {
                        final persona = personaList[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('查看人设卡: ${persona.name}'),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.all(
                                isLargeScreen ? 20 : (isMediumScreen ? 16 : 12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: isLargeScreen ? 32 : 24,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      SizedBox(width: isLargeScreen ? 12 : 8),
                                      Expanded(
                                        child: Text(
                                          persona.name,
                                          style: TextStyle(
                                            fontSize: isLargeScreen ? 16 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isLargeScreen ? 12 : 8),
                                  Text(
                                    persona.description,
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 14 : 12,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isLargeScreen ? 12 : 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '创建者: ${persona.authorName}',
                                        style: TextStyle(
                                          fontSize: isLargeScreen ? 12 : 10,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      Text(
                                        '${persona.downloads ?? 0} 下载',
                                        style: TextStyle(
                                          fontSize: isLargeScreen ? 12 : 10,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

// 消息标签页内容
class MessageTabContent extends StatelessWidget {
  final List<Message> messageList;
  final bool isLoading;
  final Function(String) onDelete;
  final Function(String) onMarkAsRead;

  const MessageTabContent({
    super.key,
    required this.messageList,
    required this.isLoading,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, ThemeProvider>(
      builder: (context, userProvider, themeProvider, child) {
        if (!userProvider.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('请先登录', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.login);
                  },
                  child: const Text('去登录'),
                ),
              ],
            ),
          );
        }

        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (messageList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('暂无消息', style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...messageList.map(
                (message) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: message.isRead
                          ? Colors.grey
                          : Theme.of(context).colorScheme.primary,
                      child: Icon(
                        message.isRead ? Icons.check : Icons.mark_email_unread,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(message.title),
                    subtitle: Text(message.content),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('删除消息'),
                            content: const Text('您确定要删除这条消息吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          onDelete(message.id);
                        }
                      },
                    ),
                    onTap: () {
                      if (!message.isRead) {
                        onMarkAsRead(message.id);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 个人资料标签页内容
class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (!userProvider.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_circle,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text('请先登录', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.login);
                  },
                  child: const Text('去登录'),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 用户信息卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          userProvider.currentUser?.name.substring(0, 1) ?? 'U',
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userProvider.currentUser?.name ?? '未知用户',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '角色：${userProvider.currentUser?.role ?? '普通用户'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (userProvider.currentUser?.email != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          userProvider.currentUser!.email!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 功能菜单
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('编辑资料'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: 实现编辑资料功能
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('修改密码'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: 实现修改密码功能
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('通知设置'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: 实现通知设置功能
                      },
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
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _sidebarAnimationController;

  bool _isSidebarExpanded = true;
  int _currentIndex = 0;

  // 数据相关状态
  final List<Knowledge> _knowledgeList = [];
  final List<Knowledge> _filteredKnowledgeList = [];
  final List<Persona> _personaList = [];
  final List<Persona> _filteredPersonaList = [];
  final List<Message> _messageList = [];
  bool _isMessageLoading = false;

  final TextEditingController _knowledgeSearchController =
      TextEditingController();
  final TextEditingController _personaSearchController =
      TextEditingController();

  String _knowledgeSearchQuery = '';
  String _personaSearchQuery = '';

  @override
  void initState() {
    super.initState();

    // 主内容动画
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();

    // 侧边栏动画
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sidebarAnimationController.forward();

    // 加载数据
    _loadKnowledgeList();
    _loadPersonaList();
    _loadMessages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sidebarAnimationController.dispose();
    _knowledgeSearchController.dispose();
    _personaSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadKnowledgeList() async {
    // TODO: 实现知识库列表加载
    setState(() {
      _knowledgeList.clear();
      _filteredKnowledgeList.clear();
    });
  }

  Future<void> _loadPersonaList() async {
    // TODO: 实现人设卡列表加载
    setState(() {
      _personaList.clear();
      _filteredPersonaList.clear();
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isMessageLoading = true;
    });

    // TODO: 实现消息列表加载

    setState(() {
      _isMessageLoading = false;
    });
  }

  void _searchKnowledge(String query) {
    setState(() {
      _knowledgeSearchQuery = query;
      if (query.isEmpty) {
        _filteredKnowledgeList.clear();
        _filteredKnowledgeList.addAll(_knowledgeList);
      } else {
        _filteredKnowledgeList.clear();
        _filteredKnowledgeList.addAll(
          _knowledgeList.where((knowledge) {
            return knowledge.name.toLowerCase().contains(query.toLowerCase()) ||
                knowledge.description.toLowerCase().contains(
                  query.toLowerCase(),
                );
          }).toList(),
        );
      }
    });
  }

  void _searchPersona(String query) {
    setState(() {
      _personaSearchQuery = query;
      if (query.isEmpty) {
        _filteredPersonaList.clear();
        _filteredPersonaList.addAll(_personaList);
      } else {
        _filteredPersonaList.clear();
        _filteredPersonaList.addAll(
          _personaList.where((persona) {
            return persona.name.toLowerCase().contains(query.toLowerCase()) ||
                persona.description.toLowerCase().contains(query.toLowerCase());
          }).toList(),
        );
      }
    });
  }

  Future<void> _deleteMessage(String messageId) async {
    // TODO: 实现消息删除
  }

  Future<void> _markMessageAsRead(String messageId) async {
    // TODO: 实现消息标记已读
  }

  // 页面列表
  List<Widget> get _pages => [
    KnowledgeTabContent(
      knowledgeList:
          _filteredKnowledgeList.isEmpty && _knowledgeSearchQuery.isEmpty
          ? _knowledgeList
          : _filteredKnowledgeList,
      searchController: _knowledgeSearchController,
      onSearch: _searchKnowledge,
    ),
    PersonaTabContent(
      personaList: _filteredPersonaList.isEmpty && _personaSearchQuery.isEmpty
          ? _personaList
          : _filteredPersonaList,
      searchController: _personaSearchController,
      onSearch: _searchPersona,
    ),
    MessageTabContent(
      messageList: _messageList,
      isLoading: _isMessageLoading,
      onDelete: _deleteMessage,
      onMarkAsRead: _markMessageAsRead,
    ),
    ProfileTabContent(),
    // 管理员概览标签页内容
    AdminOverviewTabContent(),
    // 上传管理标签页内容
    UploadManagementTabContent(),
  ];

  Widget _buildMainContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _pages[_currentIndex],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 获取屏幕尺寸信息
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1200; // 大屏幕（电脑）
        final isMediumScreen =
            screenWidth >= 800 && screenWidth < 1200; // 中等屏幕（平板）

        // 侧边栏始终展开（已删除收起按钮）
        if (!_isSidebarExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isSidebarExpanded = true;
              });
            }
          });
        }

        return Scaffold(
          body: Row(
            children: [
              // 侧边栏 - 始终展开
              Container(
                width: isLargeScreen ? 240 : (isMediumScreen ? 220 : 180),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Logo和标题 - 响应式调整
                    Container(
                      padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: isLargeScreen ? 40 : 32,
                            height: isLargeScreen ? 40 : 32,
                            child: Image.asset(
                              'assets/logo/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: isLargeScreen ? 40 : 32,
                                  height: isLargeScreen ? 40 : 32,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    color: Colors.white,
                                    size: isLargeScreen ? 24 : 20,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: isLargeScreen ? 20 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          _buildNavItem(Icons.library_books, '知识库', 0),
                          _buildNavItem(Icons.person, '人设卡', 1),
                          _buildNavItem(Icons.message, '消息', 2),
                          _buildNavItem(Icons.account_circle, '个人资料', 3),
                          if (userProvider.currentUser?.role == 'admin') ...[
                            _buildNavItem(
                              Icons.admin_panel_settings,
                              '管理员概览',
                              4,
                            ),
                          ],
                          if (userProvider.currentUser?.isAdminOrModerator ==
                              true) ...[
                            _buildNavItem(Icons.cloud_upload, '上传管理', 5),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // 顶部工具栏 - 响应式设计
                      Container(
                        padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getPageTitle(_currentIndex, userProvider),
                                style: TextStyle(
                                  fontSize: isLargeScreen
                                      ? 20
                                      : (isMediumScreen ? 18 : 16),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // 用户信息和操作
                            if (userProvider.isLoggedIn) ...[
                              // 主题切换按钮
                              Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return IconButton(
                                    icon: Icon(
                                      themeProvider.isDarkMode
                                          ? Icons.light_mode
                                          : Icons.dark_mode,
                                    ),
                                    onPressed: () {
                                      themeProvider.toggleTheme();
                                    },
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              // 通知图标
                              IconButton(
                                icon: const Icon(Icons.notifications),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('通知功能开发中')),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              // 用户头像
                              CircleAvatar(
                                radius: isLargeScreen ? 16 : 14,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: Text(
                                  userProvider.currentUser?.name.substring(
                                        0,
                                        1,
                                      ) ??
                                      'U',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isLargeScreen ? 14 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // 用户名（仅在大屏幕显示）
                              if (isLargeScreen)
                                Text(
                                  userProvider.currentUser?.name ?? '用户',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ] else ...[
                              // 登录按钮
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRouter.login);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLargeScreen ? 20 : 16,
                                    vertical: isLargeScreen ? 12 : 8,
                                  ),
                                ),
                                child: Text(
                                  '登录',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 14 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // 主内容区域
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                          child: _buildMainContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 导航项构建器 - 响应式设计
  Widget _buildNavItem(IconData icon, String title, int index) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1200;
        final isSelected = _currentIndex == index;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? 8 : 6,
            vertical: isLargeScreen ? 4 : 3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 8),
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
          ),
          child: ListTile(
            leading: Icon(icon, size: isLargeScreen ? 24 : 20),
            title: _isSidebarExpanded
                ? Text(
                    title,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 14 : 12,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  )
                : null,
            selected: isSelected,
            dense: !isLargeScreen,
            contentPadding: EdgeInsets.symmetric(
              horizontal: _isSidebarExpanded ? (isLargeScreen ? 16 : 12) : 8,
              vertical: isLargeScreen ? 10 : 6,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isLargeScreen ? 12 : 8),
            ),
            onTap: () {
              // 检查登录状态
              if (!userProvider.isLoggedIn && index != 0) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请先登录')));
                return;
              }

              // 管理员权限检查
              if (index == 5 && userProvider.currentUser?.role != 'admin') {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('需要管理员权限')));
                return;
              }

              // 上传管理权限检查
              if (index == 6 &&
                  userProvider.currentUser?.isAdminOrModerator != true) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('需要管理员或审核员权限')));
                return;
              }

              setState(() {
                _currentIndex = index;
              });
            },
          ),
        );
      },
    );
  }

  // 获取页面标题
  String _getPageTitle(int index, UserProvider userProvider) {
    switch (index) {
      case 0:
        return '首页';
      case 1:
        return '知识库';
      case 2:
        return '人设卡';
      case 3:
        return '消息';
      case 4:
        return '个人资料';
      case 5:
        return userProvider.currentUser?.role == 'admin' ? '管理员概览' : '首页';
      case 6:
        return userProvider.currentUser?.isAdminOrModerator == true
            ? '上传管理'
            : '首页';
      default:
        return '首页';
    }
  }
}
