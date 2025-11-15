import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _pendingKnowledge = [];
  List<Map<String, dynamic>> _pendingPersonas = [];
  List<Map<String, dynamic>> _recentUsers = [];

  @override
  void initState() {
    super.initState();

    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // 启动动画
    _animationController.forward();

    // 加载管理员数据
    _loadAdminData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 并行加载所有数据
      await Future.wait([
        _loadStats(),
        _loadPendingKnowledge(),
        _loadPendingPersonas(),
        _loadRecentUsers(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载管理数据失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/admin/stats');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _stats = data['data'] ?? {};
        });
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _loadPendingKnowledge() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/admin/pending/knowledge');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _pendingKnowledge = List<Map<String, dynamic>>.from(
            data['data'] ?? [],
          );
        });
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _loadPendingPersonas() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/admin/pending/personas');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _pendingPersonas = List<Map<String, dynamic>>.from(
            data['data'] ?? [],
          );
        });
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/admin/recent-users');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _recentUsers = List<Map<String, dynamic>>.from(data['data'] ?? []);
        });
      }
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _approveKnowledge(String id) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/api/admin/approve/knowledge/$id',
        data: {},
      );
      final data = response.data;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('知识库审核通过'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingKnowledge();
        _loadStats();
      } else {
        _showError(data['message'] ?? '审核失败');
      }
    } catch (e) {
      _showError('审核失败: $e');
    }
  }

  Future<void> _rejectKnowledge(String id) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/api/admin/reject/knowledge/$id',
        data: {},
      );
      final data = response.data;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('知识库已拒绝'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingKnowledge();
      } else {
        _showError(data['message'] ?? '拒绝失败');
      }
    } catch (e) {
      _showError('拒绝失败: $e');
    }
  }

  Future<void> _approvePersona(String id) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/api/admin/approve/persona/$id',
        data: {},
      );
      final data = response.data;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('人设卡审核通过'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingPersonas();
        _loadStats();
      } else {
        _showError(data['message'] ?? '审核失败');
      }
    } catch (e) {
      _showError('审核失败: $e');
    }
  }

  Future<void> _rejectPersona(String id) async {
    try {
      final apiService = ApiService();
      final response = await apiService.post(
        '/api/admin/reject/persona/$id',
        data: {},
      );
      final data = response.data;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('人设卡已拒绝'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingPersonas();
      } else {
        _showError(data['message'] ?? '拒绝失败');
      }
    } catch (e) {
      _showError('拒绝失败: $e');
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // 检查管理员权限
    if (user == null || !user.isAdminOrModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('管理员概览')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                '无权访问此页面',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text('只有管理员和版主才能查看此页面', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // 检测屏幕尺寸
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200;
    final isMediumScreen = screenWidth >= 800;
    
    // 根据屏幕尺寸调整布局
    final horizontalPadding = isLargeScreen ? 32.0 : (isMediumScreen ? 24.0 : 16.0);
    final cardSpacing = isLargeScreen ? 24.0 : (isMediumScreen ? 20.0 : 16.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员概览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: const Center(child: CircularProgressIndicator()),
            )
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(user, isLargeScreen, isMediumScreen),
                        SizedBox(height: cardSpacing),
                        _buildStatsGrid(isLargeScreen, isMediumScreen),
                        SizedBox(height: cardSpacing),
                        _buildPendingApprovals(isLargeScreen, isMediumScreen),
                        SizedBox(height: cardSpacing),
                        _buildRecentUsers(isLargeScreen, isMediumScreen),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(dynamic user, bool isLargeScreen, bool isMediumScreen) {
    // 根据屏幕尺寸调整头像和字体大小
    final avatarRadius = isLargeScreen ? 35.0 : (isMediumScreen ? 32.0 : 30.0);
    final avatarFontSize = isLargeScreen ? 28.0 : (isMediumScreen ? 26.0 : 24.0);
    final titleFontSize = isLargeScreen ? 24.0 : (isMediumScreen ? 22.0 : 20.0);
    final subtitleFontSize = isLargeScreen ? 16.0 : (isMediumScreen ? 15.0 : 14.0);
    final cardPadding = isLargeScreen ? 24.0 : (isMediumScreen ? 20.0 : 16.0);
    final spacing = isLargeScreen ? 20.0 : (isMediumScreen ? 18.0 : 16.0);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.blue,
              child: Text(
                user.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: avatarFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '欢迎，${user.name}',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.isAdmin ? '管理员' : '版主',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isLargeScreen, bool isMediumScreen) {
    // 根据屏幕尺寸调整网格布局
    final crossAxisCount = isLargeScreen ? 4 : 2;
    final crossAxisSpacing = isLargeScreen ? 16.0 : (isMediumScreen ? 14.0 : 12.0);
    final mainAxisSpacing = isLargeScreen ? 16.0 : (isMediumScreen ? 14.0 : 12.0);
    final titleFontSize = isLargeScreen ? 20.0 : (isMediumScreen ? 18.0 : 16.0);
    final sectionSpacing = isLargeScreen ? 16.0 : (isMediumScreen ? 14.0 : 12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '系统统计',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sectionSpacing),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              '总用户数',
              _stats['totalUsers']?.toString() ?? '0',
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              '总知识库',
              _stats['totalKnowledge']?.toString() ?? '0',
              Icons.library_books,
              Colors.green,
            ),
            _buildStatCard(
              '总人设卡',
              _stats['totalPersonas']?.toString() ?? '0',
              Icons.person,
              Colors.orange,
            ),
            _buildStatCard(
              '待审核数量',
              ((_stats['pendingKnowledge'] ?? 0) +
                      (_stats['pendingPersonas'] ?? 0))
                  .toString(),
              Icons.pending,
              Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    // 根据屏幕尺寸调整统计卡片样式
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 1200;
    final isMediumScreen = screenWidth >= 800;
    
    final cardPadding = isLargeScreen ? 20.0 : (isMediumScreen ? 18.0 : 16.0);
    final iconSize = isLargeScreen ? 36.0 : (isMediumScreen ? 34.0 : 32.0);
    final valueFontSize = isLargeScreen ? 28.0 : (isMediumScreen ? 26.0 : 24.0);
    final titleFontSize = isLargeScreen ? 15.0 : (isMediumScreen ? 14.0 : 13.0);
    final spacing = isLargeScreen ? 10.0 : (isMediumScreen ? 9.0 : 8.0);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            SizedBox(height: spacing),
            Text(
              value,
              style: TextStyle(
                fontSize: valueFontSize,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: spacing),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApprovals(bool isLargeScreen, bool isMediumScreen) {
    // 根据屏幕尺寸调整待审核内容样式
    final titleFontSize = isLargeScreen ? 20.0 : (isMediumScreen ? 18.0 : 16.0);
    final sectionSpacing = isLargeScreen ? 16.0 : (isMediumScreen ? 14.0 : 12.0);
    final emptyCardPadding = isLargeScreen ? 20.0 : (isMediumScreen ? 18.0 : 16.0);
    final iconSpacing = isLargeScreen ? 14.0 : (isMediumScreen ? 13.0 : 12.0);
    final emptyTextFontSize = isLargeScreen ? 18.0 : (isMediumScreen ? 17.0 : 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '待审核内容',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sectionSpacing),
        if (_pendingKnowledge.isNotEmpty) ...[
          _buildSectionTitle('知识库审核 (${_pendingKnowledge.length})', isLargeScreen, isMediumScreen),
          ..._pendingKnowledge.map(
            (item) => _buildPendingItem(
              item,
              'knowledge',
              _approveKnowledge,
              _rejectKnowledge,
              isLargeScreen,
              isMediumScreen,
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
        if (_pendingPersonas.isNotEmpty) ...[
          _buildSectionTitle('人设卡审核 (${_pendingPersonas.length})', isLargeScreen, isMediumScreen),
          ..._pendingPersonas.map(
            (item) => _buildPendingItem(
              item,
              'persona',
              _approvePersona,
              _rejectPersona,
              isLargeScreen,
              isMediumScreen,
            ),
          ),
        ],
        if (_pendingKnowledge.isEmpty && _pendingPersonas.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(emptyCardPadding),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: iconSpacing),
                  Text(
                    '暂无待审核内容',
                    style: TextStyle(fontSize: emptyTextFontSize),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isLargeScreen, bool isMediumScreen) {
    // 根据屏幕尺寸调整标题样式
    final fontSize = isLargeScreen ? 18.0 : (isMediumScreen ? 17.0 : 16.0);
    final verticalPadding = isLargeScreen ? 10.0 : (isMediumScreen ? 9.0 : 8.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPendingItem(
    Map<String, dynamic> item,
    String type,
    Future<void> Function(String) onApprove,
    Future<void> Function(String) onReject,
    bool isLargeScreen,
    bool isMediumScreen,
  ) {
    // 根据屏幕尺寸调整待审核项目样式
    final cardMargin = isLargeScreen ? 12.0 : (isMediumScreen ? 10.0 : 8.0);
    final cardPadding = isLargeScreen ? 16.0 : (isMediumScreen ? 14.0 : 12.0);
    final titleFontSize = isLargeScreen ? 18.0 : (isMediumScreen ? 17.0 : 16.0);
    final descriptionFontSize = isLargeScreen ? 15.0 : (isMediumScreen ? 14.0 : 13.0);
    final uploaderFontSize = isLargeScreen ? 13.0 : (isMediumScreen ? 12.5 : 12.0);
    final buttonSpacing = isLargeScreen ? 10.0 : (isMediumScreen ? 9.0 : 8.0);
    final contentSpacing = isLargeScreen ? 12.0 : (isMediumScreen ? 10.0 : 8.0);

    return Card(
      margin: EdgeInsets.only(bottom: cardMargin),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '未知名称',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        item['description'] ?? '无描述',
                        style: TextStyle(
                          fontSize: descriptionFontSize,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '上传者: ${item['uploaderId'] ?? '未知'}',
                        style: TextStyle(
                          fontSize: uploaderFontSize,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: contentSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onReject(item['id'].toString()),
                  child: Text(
                    '拒绝',
                    style: TextStyle(fontSize: descriptionFontSize),
                  ),
                ),
                SizedBox(width: buttonSpacing),
                ElevatedButton(
                  onPressed: () => onApprove(item['id'].toString()),
                  child: Text(
                    '通过',
                    style: TextStyle(fontSize: descriptionFontSize),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUsers(bool isLargeScreen, bool isMediumScreen) {
    // 根据屏幕尺寸调整最近注册用户样式
    final titleFontSize = isLargeScreen ? 20.0 : (isMediumScreen ? 18.0 : 16.0);
    final sectionSpacing = isLargeScreen ? 16.0 : (isMediumScreen ? 14.0 : 12.0);
    final cardMargin = isLargeScreen ? 12.0 : (isMediumScreen ? 10.0 : 8.0);
    final avatarRadius = isLargeScreen ? 24.0 : (isMediumScreen ? 22.0 : 20.0);
    final avatarFontSize = isLargeScreen ? 16.0 : (isMediumScreen ? 15.0 : 14.0);
    final titleTextFontSize = isLargeScreen ? 17.0 : (isMediumScreen ? 16.0 : 15.0);
    final subtitleFontSize = isLargeScreen ? 14.0 : (isMediumScreen ? 13.0 : 12.0);
    final trailingFontSize = isLargeScreen ? 13.0 : (isMediumScreen ? 12.5 : 12.0);
    final emptyCardPadding = isLargeScreen ? 20.0 : (isMediumScreen ? 18.0 : 16.0);
    final emptyTextFontSize = isLargeScreen ? 18.0 : (isMediumScreen ? 17.0 : 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近注册用户',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sectionSpacing),
        if (_recentUsers.isNotEmpty)
          ..._recentUsers
              .take(5)
              .map(
                (user) => Card(
                  margin: EdgeInsets.only(bottom: cardMargin),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        user['name']
                                ?.toString()
                                .substring(0, 1)
                                .toUpperCase() ??
                            '?',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: avatarFontSize,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'] ?? '未知用户',
                      style: TextStyle(fontSize: titleTextFontSize),
                    ),
                    subtitle: Text(
                      '角色: ${user['role'] ?? 'user'}',
                      style: TextStyle(fontSize: subtitleFontSize),
                    ),
                    trailing: Text(
                      user['createdAt'] != null
                          ? DateTime.tryParse(
                                  user['createdAt'].toString(),
                                )?.toString().split(' ')[0] ??
                                ''
                          : '',
                      style: TextStyle(fontSize: trailingFontSize),
                    ),
                  ),
                ),
              )
        else
          Card(
            child: Padding(
              padding: EdgeInsets.all(emptyCardPadding),
              child: Text(
                '暂无最近用户数据',
                style: TextStyle(fontSize: emptyTextFontSize),
              ),
            ),
          ),
      ],
    );
  }
}
