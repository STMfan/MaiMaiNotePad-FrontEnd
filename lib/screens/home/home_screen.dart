import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/knowledge.dart';
import '../../models/persona.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_router.dart';
import '../../services/api_service.dart';
import '../admin/upload_management_tab_content.dart';
import '../admin/review_tab_content.dart';
import '../admin/overview_tab_content.dart';
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

  // 未读消息数量
  int _unreadMessageCount = 0;

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
    _loadUnreadMessageCount();
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
    try {
      final apiService = ApiService();
      final response = await apiService.getPublicKnowledge();

      setState(() {
        _knowledgeList.clear();
        _knowledgeList.addAll(response.items);
        _filteredKnowledgeList.clear();
        _filteredKnowledgeList.addAll(response.items);
      });
    } catch (e) {
      // 静默处理错误，避免在未登录时显示错误提示
      if (mounted) {
        debugPrint('加载知识库列表失败: $e');
        setState(() {
          _knowledgeList.clear();
          _filteredKnowledgeList.clear();
        });
      }
    }
  }

  Future<void> _loadPersonaList() async {
    try {
      final apiService = ApiService();
      final response = await apiService.getPublicPersonas();

      setState(() {
        _personaList.clear();
        _personaList.addAll(response.items);
        _filteredPersonaList.clear();
        _filteredPersonaList.addAll(response.items);
      });
    } catch (e) {
      // 静默处理错误，避免在未登录时显示错误提示
      if (mounted) {
        debugPrint('加载人设卡列表失败: $e');
        setState(() {
          _personaList.clear();
          _filteredPersonaList.clear();
        });
      }
    }
  }

  Future<void> _loadUnreadMessageCount() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (!userProvider.isLoggedIn) {
        setState(() {
          _unreadMessageCount = 0;
        });
        return;
      }

      final apiService = ApiService();
      final messages = await apiService.getUserMessages(page: 1, limit: 100);
      final unreadCount = messages
          .where((msg) => msg['is_read'] == false)
          .length;

      if (mounted) {
        setState(() {
          _unreadMessageCount = unreadCount;
        });
      }
    } catch (e) {
      // 静默处理错误
      if (mounted) {
        debugPrint('加载未读消息数量失败: $e');
        setState(() {
          _unreadMessageCount = 0;
        });
      }
    }
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

  // 计算上传管理标签页的索引
  int _getUploadManagementIndex(UserProvider userProvider) {
    // 上传管理在导航中的索引总是4，但在实际页面列表中的位置是动态的
    // 基础页面：知识库(0)、人设卡(1)、消息(2)、个人资料(3)
    int uploadManagementIndex = 4; // 从4开始（基础页面之后）

    // 加上审核管理（如果用户有权限）
    if (userProvider.currentUser?.isAdminOrModerator == true) {
      uploadManagementIndex += 1; // 审核管理占一个位置
    }

    // 加上管理员概览（如果用户是管理员）
    if (userProvider.currentUser?.role == 'admin') {
      uploadManagementIndex += 1; // 管理员概览占一个位置
    }

    return uploadManagementIndex;
  }

  // 跳转到上传管理标签页
  void _switchToUploadManagementTab() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _currentIndex = _getUploadManagementIndex(userProvider);
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
        onSwitchToUploadManagement: _switchToUploadManagementTab,
        onRefresh: () {
          // 刷新知识库列表
          _loadKnowledgeList();
        },
      ),
      PersonaTabContent(
        personaList: _filteredPersonaList.isEmpty && _personaSearchQuery.isEmpty
            ? _personaList
            : _filteredPersonaList,
        searchController: _personaSearchController,
        onSearch: _searchPersona,
        onSwitchToUploadManagement: _switchToUploadManagementTab,
        onRefresh: () async {
          // 刷新人设卡列表
          await _loadPersonaList();
          // 如果当前有搜索查询，重新应用搜索过滤
          if (_personaSearchQuery.isNotEmpty) {
            _searchPersona(_personaSearchQuery);
          }
        },
      ),
      MessageTabContent(),
      // 个人资料页面保留在页面列表中，但不在侧边栏显示
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

    // 添加上传管理标签页（所有登录用户可见）
    adminPages.add(UploadManagementTabContent());

    return [...basePages, ...adminPages];
  }

  Widget _buildMainContent(UserProvider userProvider) {
    final pages = _buildPages(userProvider);
    // 确保索引在有效范围内，防止越界错误
    final safeIndex = _currentIndex >= 0 && _currentIndex < pages.length
        ? _currentIndex
        : 0;
    // 如果索引无效，重置为0
    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = 0;
          });
        }
      });
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: pages[safeIndex],
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
                          // 基础标签页：知识库、人设卡
                          _buildNavItem(Icons.library_books, '知识库', 0),
                          _buildNavItem(Icons.person, '人设卡', 1),

                          // 根据用户角色动态添加管理页面
                          // 管理员/审核员：显示审核管理
                          if (userProvider.currentUser?.isAdminOrModerator ==
                              true)
                            _buildNavItem(Icons.verified, '审核管理', 2),

                          // 管理员：显示管理员概览
                          if (userProvider.currentUser?.role == 'admin')
                            _buildNavItem(
                              Icons.admin_panel_settings,
                              '管理员概览',
                              3,
                            ),

                          // 上传管理对所有登录用户可见（索引根据前面的页面数量动态计算）
                          if (userProvider.isLoggedIn) ...[
                            _buildNavItem(
                              Icons.cloud_upload,
                              '上传管理',
                              _getUploadManagementNavIndex(userProvider),
                            ),
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
                              // 通知图标（带未读消息提示）
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications),
                                    onPressed: () {
                                      setState(() {
                                        _currentIndex = 2; // 跳转到消息页面
                                      });
                                      // 刷新未读消息数量
                                      _loadUnreadMessageCount();
                                    },
                                    tooltip: '消息通知',
                                  ),
                                  if (_unreadMessageCount > 0)
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 16,
                                          minHeight: 16,
                                        ),
                                        child: Text(
                                          _unreadMessageCount > 99
                                              ? '99+'
                                              : '$_unreadMessageCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // 用户菜单（头像+用户名）
                              PopupMenuButton<String>(
                                offset: const Offset(0, 50),
                                child: InkWell(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: isLargeScreen ? 16 : 14,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        child: Text(
                                          userProvider.currentUser?.name
                                                  .substring(0, 1) ??
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
                                          userProvider.currentUser?.name ??
                                              '用户',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        size: isLargeScreen ? 20 : 18,
                                      ),
                                    ],
                                  ),
                                ),
                                onSelected: (value) {
                                  if (value == 'profile') {
                                    // 切换到个人资料标签页（索引3）
                                    setState(() {
                                      _currentIndex = 3;
                                    });
                                  } else if (value == 'logout') {
                                    // 登出
                                    userProvider.logout();
                                    // 不需要提示，直接跳转
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      AppRouter.login,
                                      (route) => false,
                                    );
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'profile',
                                    child: Row(
                                      children: [
                                        Icon(Icons.account_circle, size: 20),
                                        SizedBox(width: 8),
                                        Text('个人资料'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.logout,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '登出',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

  // 计算基础页面数量（不包括动态管理页面）
  int _getBasePageCount(UserProvider userProvider) {
    // 基础页面：知识库(0)、人设卡(1)、消息(2)、个人资料(3) = 4个
    return 4;
  }

  // 计算上传管理的导航索引
  int _getUploadManagementNavIndex(UserProvider userProvider) {
    int index = 2; // 从索引2开始（知识库、人设卡之后）

    // 如果有审核管理，索引+1
    if (userProvider.currentUser?.isAdminOrModerator == true) {
      index++;
    }

    // 如果有管理员概览，索引+1
    if (userProvider.currentUser?.role == 'admin') {
      index++;
    }

    return index;
  }

  // 将页面索引转换为导航索引
  int _getNavIndexFromPageIndex(int pageIndex, UserProvider userProvider) {
    // 基础页面：知识库(0)、人设卡(1) - 在导航中直接对应
    if (pageIndex <= 1) {
      return pageIndex;
    }

    // 消息(2)和个人资料(3)不显示在导航中，映射到人设卡(1)
    if (pageIndex == 2 || pageIndex == 3) {
      return 1;
    }

    // 动态管理页面：根据页面在列表中的实际位置计算
    int basePageCount = _getBasePageCount(userProvider);
    int uploadManagementIndex = _getUploadManagementIndex(userProvider);

    // 上传管理：固定为导航索引4
    if (pageIndex == uploadManagementIndex) {
      return 4;
    }

    // 审核管理：在基础页面之后，管理员概览之前
    if (userProvider.currentUser?.isAdminOrModerator == true &&
        pageIndex == basePageCount) {
      return 2;
    }

    // 管理员概览：在审核管理之后，上传管理之前
    if (userProvider.currentUser?.role == 'admin' &&
        pageIndex == basePageCount + 1) {
      return 3;
    }

    // 默认返回知识库索引
    return 0;
  }

  // 导航项构建器 - 响应式设计
  Widget _buildNavItem(IconData icon, String title, int index) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1200;
        // 将实际页面索引转换为导航索引进行比较
        final navIndex = _getNavIndexFromPageIndex(_currentIndex, userProvider);
        final isSelected = navIndex == index;

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

              // 计算实际页面索引
              int actualIndex = 0;

              // 基础页面：知识库(0)、人设卡(1) 直接对应
              if (index <= 1) {
                actualIndex = index;
              }
              // 审核管理
              else if (index == 2 &&
                  userProvider.currentUser?.isAdminOrModerator == true) {
                actualIndex = 4; // 在基础页面之后
              }
              // 管理员概览
              else if (index == 3 &&
                  userProvider.currentUser?.role == 'admin') {
                actualIndex = 5; // 审核管理之后
              }
              // 上传管理
              else if (index == _getUploadManagementNavIndex(userProvider)) {
                actualIndex = _getUploadManagementIndex(userProvider);
              }

              setState(() {
                _currentIndex = actualIndex;
              });

              // 如果切换到消息页面，刷新未读消息数量
              if (actualIndex == 2) {
                _loadUnreadMessageCount();
              }
            },
          ),
        );
      },
    );
  }

  // 获取页面标题
  String _getPageTitle(int index, UserProvider userProvider) {
    // 基础页面：知识库(0), 人设卡(1), 消息(2), 个人资料(3)
    if (index < 4) {
      switch (index) {
        case 0:
          return '知识库';
        case 1:
          return '人设卡';
        case 2:
          return '消息';
        case 3:
          return '个人资料';
        default:
          return '首页';
      }
    }

    int currentIndex = 4;

    // 审核管理（管理员和审核员可见）
    if (userProvider.currentUser?.isAdminOrModerator == true) {
      if (index == currentIndex) {
        return '审核管理';
      }
      currentIndex++;
    }

    // 管理员概览（仅管理员可见）
    if (userProvider.currentUser?.role == 'admin') {
      if (index == currentIndex) {
        return '管理员概览';
      }
      currentIndex++;
    }

    // 上传管理（所有登录用户可见）
    if (index == currentIndex) {
      return '上传管理';
    }

    return '首页';
  }
}
