import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/knowledge.dart';
import '../../models/persona.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_router.dart';
import '../admin/overview_tab_content.dart';
import '../admin/upload_management_tab_content.dart';
import '../admin/review_tab_content.dart';
import '../knowledge/tab_content.dart';
import '../persona/tab_content.dart';
import '../message/tab_content.dart';
import '../user/profile_tab_content.dart';

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

  // 页面列表 - 根据用户权限动态生成
  List<Widget> _buildPages(UserProvider userProvider) {
    final basePages = [
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
      MessageTabContent(),
      ProfileTabContent(),
    ];

    final adminPages = <Widget>[];

    // 添加审核管理标签页（管理员和审核员可见）
    if (userProvider.currentUser?.isAdminOrModerator == true) {
      adminPages.add(ReviewTabContent());
    }

    // 添加管理员概览标签页（仅管理员可见）
    if (userProvider.currentUser?.role == 'admin') {
      adminPages.add(AdminOverviewTabContent());
    }

    // 添加上传管理标签页（管理员和审核员可见）
    if (userProvider.currentUser?.isAdminOrModerator == true) {
      adminPages.add(UploadManagementTabContent());
    }

    return [...basePages, ...adminPages];
  }

  Widget _buildMainContent(UserProvider userProvider) {
    final pages = _buildPages(userProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: pages[_currentIndex],
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
                          if (userProvider.currentUser?.isAdminOrModerator ==
                              true) ...[
                            _buildNavItem(Icons.verified, '审核管理', 4),
                          ],
                          if (userProvider.currentUser?.role == 'admin') ...[
                            _buildNavItem(
                              Icons.admin_panel_settings,
                              '管理员概览',
                              5,
                            ),
                          ],
                          if (userProvider.currentUser?.isAdminOrModerator ==
                              true) ...[
                            _buildNavItem(Icons.cloud_upload, '上传管理', 6),
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
                          child: _buildMainContent(userProvider),
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

              // 审核管理权限检查
              if (index == 4 &&
                  userProvider.currentUser?.isAdminOrModerator != true) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('需要管理员或审核员权限')));
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
        return '知识库';
      case 1:
        return '人设卡';
      case 2:
        return '消息';
      case 3:
        return '个人资料';
      case 4:
        return userProvider.currentUser?.isAdminOrModerator == true
            ? '审核管理'
            : '首页';
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
