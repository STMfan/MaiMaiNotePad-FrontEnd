import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../services/api_service.dart';
import 'user_management_tab_content.dart';
import 'content_management_tab_content.dart';
import 'message_management_tab_content.dart';

class AdminOverviewTabContent extends StatefulWidget {
  const AdminOverviewTabContent({super.key});

  @override
  State<AdminOverviewTabContent> createState() =>
      _AdminOverviewTabContentState();
}

class _AdminOverviewTabContentState extends State<AdminOverviewTabContent>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _pendingKnowledge = [];
  List<Map<String, dynamic>> _pendingPersonas = [];
  List<Map<String, dynamic>> _recentUsers = [];

  @override
  void initState() {
    super.initState();

    // 初始化标签控制器
    _tabController = TabController(length: 4, vsync: this);

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
    _tabController.dispose();
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
      
      // 添加调试日志
      debugPrint('Admin stats API response: $data');
      
      if (data['success'] == true) {
        final responseData = data['data'];
        
        // 检查是否包含错误信息（权限错误等）
        if (responseData is Map && responseData.containsKey('detail')) {
          // 这是错误信息，不是数据
          debugPrint('API returned error: ${responseData['detail']}');
          if (mounted) {
            setState(() {
              _stats = {};
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('权限错误: ${responseData['detail']}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return; // 不继续处理
        }
        
        setState(() {
          _stats = responseData ?? {};
        });
        debugPrint('Stats loaded successfully: $_stats');
      } else {
        // 处理API返回失败的情况
        debugPrint('API returned success=false: ${data['message'] ?? 'Unknown error'}');
        if (mounted) {
          setState(() {
            _stats = {};
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('获取统计数据失败: ${data['message'] ?? '未知错误'}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // 不再静默处理，显示错误信息并添加调试日志
      debugPrint('Error loading stats: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _stats = {};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载统计数据失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: '重试',
              onPressed: _loadStats,
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadPendingKnowledge() async {
    try {
      final apiService = ApiService();
      // 使用正确的审核接口路径
      final response = await apiService.getPendingKnowledge();
      setState(() {
        _pendingKnowledge = response.items
            .map((kb) => {
                  'id': kb.id,
                  'name': kb.name,
                  'title': kb.name, // 兼容旧代码
                  'description': kb.description,
                  'uploader_id': kb.uploaderId,
                  'creatorName': kb.uploaderId, // 暂时使用uploaderId，实际应该从用户信息获取
                  'createdAt': kb.createdAt.toIso8601String(),
                })
            .toList();
      });
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _loadPendingPersonas() async {
    try {
      final apiService = ApiService();
      // 使用正确的审核接口路径
      final response = await apiService.getPendingPersonas();
      final personaList = response.items;
      setState(() {
        _pendingPersonas = personaList
            .map((pc) => {
                  'id': pc.id,
                  'name': pc.name,
                  'description': pc.description,
                  'uploader_id': pc.uploaderId,
                  'createdAt': pc.createdAt.toIso8601String(),
                })
            .toList();
      });
    } catch (e) {
      // 静默处理错误
    }
  }

  Future<void> _loadRecentUsers() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/admin/recent-users?limit=10');
      final data = response.data;
      
      // 添加调试日志
      debugPrint('Recent users API response: $data');
      
      if (data['success'] == true) {
        final responseData = data['data'];
        
        // 检查是否包含错误信息（权限错误等）
        if (responseData is Map && responseData.containsKey('detail')) {
          // 这是错误信息，不是数据
          debugPrint('API returned error: ${responseData['detail']}');
          if (mounted) {
            setState(() {
              _recentUsers = [];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('权限错误: ${responseData['detail']}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return; // 不继续处理
        }
        
        // 检查 data['data'] 的类型，确保它是 List
        final dataList = responseData;
        if (dataList is List) {
          setState(() {
            _recentUsers = List<Map<String, dynamic>>.from(
              dataList.map((item) => item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item))
            );
          });
          debugPrint('Recent users loaded successfully: ${_recentUsers.length} users');
        } else if (dataList is Map) {
          // 如果返回的是 Map，可能是单个对象，转换为列表
          debugPrint('Warning: API returned Map instead of List, converting to List');
          setState(() {
            _recentUsers = [Map<String, dynamic>.from(dataList)];
          });
          debugPrint('Recent users loaded (converted from Map): ${_recentUsers.length} users');
        } else {
          // 如果既不是 List 也不是 Map，设置为空列表
          debugPrint('Warning: API returned unexpected data type: ${dataList.runtimeType}');
          setState(() {
            _recentUsers = [];
          });
        }
      } else {
        // 处理API返回失败的情况
        debugPrint('API returned success=false: ${data['message'] ?? 'Unknown error'}');
        if (mounted) {
          setState(() {
            _recentUsers = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('获取最近用户失败: ${data['message'] ?? '未知错误'}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      // 不再静默处理，显示错误信息并添加调试日志
      debugPrint('Error loading recent users: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _recentUsers = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载最近用户失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: '重试',
              onPressed: _loadRecentUsers,
            ),
          ),
        );
      }
    }
  }

  Future<void> _approveKnowledge(String id) async {
    try {
      final apiService = ApiService();
      // 使用正确的审核接口路径
      await apiService.approveKnowledge(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('知识库审核通过'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPendingKnowledge();
      _loadStats();
    } catch (e) {
      _showError('审核失败: $e');
    }
  }

  Future<void> _rejectKnowledge(String id) async {
    try {
      final apiService = ApiService();
      // 使用正确的审核接口路径
      await apiService.rejectKnowledge(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('知识库已拒绝'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadPendingKnowledge();
    } catch (e) {
      _showError('拒绝失败: $e');
    }
  }

  Future<void> _approvePersona(String id) async {
    try {
      final apiService = ApiService();
      // 使用正确的审核接口路径
      await apiService.approvePersona(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('人格审核通过'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPendingPersonas();
      _loadStats();
    } catch (e) {
      _showError('审核失败: $e');
    }
  }

  Future<void> _rejectPersona(String id) async {
    try {
      final apiService = ApiService();
      // 使用正确的审核接口路径
      await apiService.rejectPersona(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('人格已拒绝'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadPendingPersonas();
    } catch (e) {
      _showError('拒绝失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _showSendBroadcastDialog() async {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发送系统公告'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '标题 *',
                    border: OutlineInputBorder(),
                    hintText: '请输入公告标题',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '标题不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: summaryController,
                  decoration: const InputDecoration(
                    labelText: '简介（可选）',
                    border: OutlineInputBorder(),
                    hintText: '请输入消息简介，用于列表预览',
                    helperText: '如果不填写，将自动从内容生成',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '详细内容 *',
                    border: OutlineInputBorder(),
                    hintText: '请输入公告详细内容（支持Markdown格式）',
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '内容不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '此公告将发送给所有用户',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final apiService = ApiService();
        await apiService.sendMessage(
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          summary: summaryController.text.trim().isNotEmpty
              ? summaryController.text.trim()
              : null,
          asAnnouncement: true,
          broadcastAll: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('系统公告发送成功'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          // 刷新数据
          _loadAdminData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('发送失败: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showSendBroadcastDialogOld() async {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发送系统公告'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '标题 *',
                    border: OutlineInputBorder(),
                    hintText: '请输入公告标题',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '标题不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: summaryController,
                  decoration: const InputDecoration(
                    labelText: '简介（可选）',
                    border: OutlineInputBorder(),
                    hintText: '请输入消息简介，用于列表预览',
                    helperText: '如果不填写，将自动从内容生成',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '详细内容 *',
                    border: OutlineInputBorder(),
                    hintText: '请输入公告详细内容（支持Markdown格式）',
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '内容不能为空';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '此公告将发送给所有用户',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        final apiService = ApiService();
        await apiService.sendMessage(
          title: titleController.text.trim(),
          content: contentController.text.trim(),
          summary: summaryController.text.trim().isNotEmpty
              ? summaryController.text.trim()
              : null,
          asAnnouncement: true,
          broadcastAll: true,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('系统公告发送成功'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          _showError('发送失败: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // 标签栏
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '概览'),
              Tab(text: '用户管理'),
              Tab(text: '内容管理'),
              Tab(text: '消息管理'),
            ],
          ),
          // 标签页内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 概览标签页
                _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题和发送公告按钮
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '管理员概览',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _showSendBroadcastDialog,
                            icon: const Icon(Icons.campaign),
                            label: const Text('发送系统公告'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 统计卡片
                    _buildStatsCards(),
                    const SizedBox(height: 24),

                    // 待审核内容
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // 在小屏幕上垂直排列，大屏幕上水平排列
                        if (constraints.maxWidth < 800) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPendingKnowledgeSection(),
                              const SizedBox(height: 16),
                              _buildPendingPersonasSection(),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 待审核知识库
                              Expanded(
                                flex: 3,
                                child: _buildPendingKnowledgeSection(),
                              ),
                              const SizedBox(width: 16),
                              // 待审核人格
                              Expanded(
                                flex: 2,
                                child: _buildPendingPersonasSection(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // 最近用户
                    _buildRecentUsersSection(),
                  ],
                ),
              ),
                      ),
                // 用户管理标签页
                const UserManagementTabContent(),
                // 内容管理标签页
                const ContentManagementTabContent(),
                // 消息管理标签页
                const MessageManagementTabContent(),
              ],
            ),
          ),
        ],
            ),
    );
  }

  Widget _buildStatsCards() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 根据屏幕宽度动态调整列数
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
            ? 3
            : screenWidth > 600
                ? 2
                : 1;

    final stats = [
      {
        'title': '总用户数',
        'value': _stats['totalUsers']?.toString() ?? '0',
        'icon': Icons.people,
        'color': colorScheme.primary,
      },
      {
        'title': '知识库数量',
        'value': _stats['totalKnowledge']?.toString() ?? '0',
        'icon': Icons.book,
        'color': colorScheme.secondary,
      },
      {
        'title': '人格数量',
        'value': _stats['totalPersonas']?.toString() ?? '0',
        'icon': Icons.person,
        'color': colorScheme.tertiary,
      },
      {
        'title': '待审核',
        'value':
            ((_stats['pendingKnowledge'] ?? 0) +
                    (_stats['pendingPersonas'] ?? 0))
                .toString(),
        'icon': Icons.pending,
        'color': colorScheme.error,
      },
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: stats.map((stat) {
          return _buildStatCard(
            title: stat['title'] as String,
            value: stat['value'] as String,
            icon: stat['icon'] as IconData,
            color: stat['color'] as Color,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingKnowledgeSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '待审核知识库',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_pendingKnowledge.length} 个待审核',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pendingKnowledge.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无待审核的知识库',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _pendingKnowledge.map((knowledge) {
                  return _buildPendingKnowledgeItem(knowledge);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingKnowledgeItem(Map<String, dynamic> knowledge) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  knowledge['title'] ?? '无标题',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '知识库',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            knowledge['description'] ?? '无描述',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                knowledge['creatorName'] ?? '未知用户',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(knowledge['createdAt']),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _rejectKnowledge(knowledge['id']),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('拒绝'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _approveKnowledge(knowledge['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('通过'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPersonasSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '待审核人格',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_pendingPersonas.length} 个待审核',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pendingPersonas.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 48,
                        color: colorScheme.secondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无待审核的人格',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _pendingPersonas.map((persona) {
                  return _buildPendingPersonaItem(persona);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingPersonaItem(Map<String, dynamic> persona) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: persona['avatar'] != null
                    ? NetworkImage(persona['avatar'])
                    : null,
                child: persona['avatar'] == null
                    ? Text(persona['name']?.substring(0, 1) ?? 'P')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona['name'] ?? '无名称',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      persona['description'] ?? '无描述',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '人格',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.secondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _rejectPersona(persona['id']),
                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                child: const Text('拒绝'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _approvePersona(persona['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                ),
                child: const Text('通过'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUsersSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recent_actors, color: colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  '最近注册用户',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_recentUsers.length} 个用户',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentUsers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 48,
                        color: colorScheme.tertiary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无最近注册用户',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _recentUsers.map((user) {
                  return _buildRecentUserItem(user);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentUserItem(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: user['avatar'] != null
                ? NetworkImage(user['avatar'])
                : null,
            child: user['avatar'] == null
                ? Text(user['username']?.substring(0, 1) ?? 'U')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'] ?? '未知用户',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user['email'] ?? '无邮箱',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDate(user['createdAt']),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (user['role'] != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(
                      user['role'],
                      colorScheme,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getRoleText(user['role']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getRoleColor(user['role'], colorScheme),
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '未知时间';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}天前';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}小时前';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}分钟前';
      } else {
        return '刚刚';
      }
    } catch (e) {
      return '未知时间';
    }
  }

  String _getRoleText(String? role) {
    switch (role) {
      case 'admin':
        return '管理员';
      case 'moderator':
        return '审核员';
      case 'user':
        return '用户';
      default:
        return '用户';
    }
  }

  Color _getRoleColor(String? role, ColorScheme colorScheme) {
    switch (role) {
      case 'admin':
        return colorScheme.error;
      case 'moderator':
        return colorScheme.secondary;
      case 'user':
        return colorScheme.primary;
      default:
        return colorScheme.primary;
    }
  }
}