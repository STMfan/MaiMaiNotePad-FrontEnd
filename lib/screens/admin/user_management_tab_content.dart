import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';

class UserManagementTabContent extends StatefulWidget {
  const UserManagementTabContent({super.key});

  @override
  State<UserManagementTabContent> createState() =>
      _UserManagementTabContentState();
}

class _UserManagementTabContentState extends State<UserManagementTabContent> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  String? _roleFilter;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentUserId = prefs.getString(AppConstants.userIdKey);
      });
    }
  }

  Future<void> _loadUsers({bool resetPage = false}) async {
    if (!mounted) return;

    if (resetPage) {
      _currentPage = 1;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.getAllUsers(
        page: _currentPage,
        limit: 20,
        search: _searchQuery,
        role: _roleFilter,
      );

      // 异步操作完成后检查 mounted
      if (!mounted) return;

      final data = response.data['data'];
      final users = List<Map<String, dynamic>>.from(data['users']);

      if (mounted) {
        setState(() {
          if (resetPage) {
            _users = users;
          } else {
            _users.addAll(users);
          }
          _totalPages = data['totalPages'] ?? 1;
          _total = data['total'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 错误处理时也要检查 mounted
      if (!mounted) return;
      
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('加载用户列表失败: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _onSearch(String query) {
    if (!mounted) return;
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    if (mounted) {
      _loadUsers(resetPage: true);
    }
  }

  void _onRoleFilterChanged(String? role) {
    if (!mounted) return;
    setState(() {
      _roleFilter = role;
    });
    if (mounted) {
      _loadUsers(resetPage: true);
    }
  }

  Future<void> _refreshUsers() async {
    if (!mounted) return;
    await _loadUsers(resetPage: true);
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    if (!mounted) return;
    
    try {
      await _apiService.updateUserRole(userId, newRole);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用户角色更新成功')),
        );
        if (mounted) {
          await _refreshUsers();
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新用户角色失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteUser(String userId, String username) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除用户 "$username" 吗？\n\n此操作将标记用户为已删除状态，用户将无法登录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.deleteUser(userId);
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('用户删除成功')),
          );
          if (mounted) {
            await _refreshUsers();
          }
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除用户失败: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditRoleDialog(String userId, String currentRole) async {
    if (!mounted) return;
    
    String? selectedRole = currentRole;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('编辑用户角色'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('当前角色: $currentRole'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(
                  labelText: '选择新角色',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('普通用户')),
                  DropdownMenuItem(value: 'moderator', child: Text('审核员')),
                  DropdownMenuItem(value: 'admin', child: Text('管理员')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(selectedRole),
              child: const Text('确认'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != currentRole && mounted) {
      await _updateUserRole(userId, result);
    }
  }

  Future<void> _showCreateUserDialog() async {
    if (!mounted) return;
    
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String selectedRole = 'user';
    
    // 保存 widget 的 context 引用
    final widgetContext = context;

    try {
      await showDialog(
        context: widgetContext,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: const Text('创建新用户'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入用户名';
                        }
                        if (value.length < 3) {
                          return '用户名至少3个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: '邮箱',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入邮箱';
                        }
                        if (!value.contains('@')) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        if (value.length < 8) {
                          return '密码至少8位';
                        }
                        if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                          return '密码必须包含字母和数字';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: '确认密码',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        // 在验证器中直接使用 controller.text，避免在 dispose 后访问
                        final password = passwordController.text;
                        if (value != password) {
                          return '两次输入的密码不一致';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: '角色',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('普通用户')),
                        DropdownMenuItem(value: 'moderator', child: Text('审核员')),
                        DropdownMenuItem(value: 'admin', child: Text('管理员')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    // 在关闭对话框前保存表单值
                    final username = usernameController.text;
                    final email = emailController.text;
                    final password = passwordController.text;
                    final role = selectedRole;
                    
                    Navigator.of(dialogContext).pop();
                    
                    // 延迟 dispose controller，确保对话框完全关闭
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      usernameController.dispose();
                      emailController.dispose();
                      passwordController.dispose();
                      confirmPasswordController.dispose();
                    });
                    
                    // 在异步操作前检查 mounted
                    if (!mounted) return;
                    
                    try {
                      await _apiService.createUser(
                        username: username,
                        email: email,
                        password: password,
                        role: role,
                      );
                      
                      // 异步操作完成后再次检查 mounted 和 context
                      if (mounted && widgetContext.mounted) {
                        ScaffoldMessenger.of(widgetContext).showSnackBar(
                          const SnackBar(content: Text('用户创建成功')),
                        );
                        // 确保在调用 _refreshUsers 前检查 mounted
                        if (mounted) {
                          await _refreshUsers();
                        }
                      }
                    } catch (e) {
                      // 错误处理时也要检查 mounted 和 context
                      if (mounted && widgetContext.mounted) {
                        ScaffoldMessenger.of(widgetContext).showSnackBar(
                          SnackBar(
                            content: Text('创建用户失败: $e'),
                            backgroundColor: Theme.of(widgetContext).colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('创建'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // 如果对话框显示失败，也要 dispose controller
      SchedulerBinding.instance.addPostFrameCallback((_) {
        usernameController.dispose();
        emailController.dispose();
        passwordController.dispose();
        confirmPasswordController.dispose();
      });
    }
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
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshUsers,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 搜索和筛选栏
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // 搜索框
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '搜索用户（用户名、邮箱）',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: _onSearch,
                  ),
                  const SizedBox(height: 12),
                  // 角色筛选
                  Row(
                    children: [
                      const Text('角色筛选: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<String?>(
                          segments: const [
                            ButtonSegment(value: null, label: Text('全部')),
                            ButtonSegment(value: 'user', label: Text('用户')),
                            ButtonSegment(value: 'moderator', label: Text('审核员')),
                            ButtonSegment(value: 'admin', label: Text('管理员')),
                          ],
                          selected: {_roleFilter},
                          onSelectionChanged: (Set<String?> selection) {
                            _onRoleFilterChanged(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 统计信息
                  Text(
                    '共 $_total 个用户',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          // 用户列表
          if (_isLoading && _users.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _users.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('加载失败: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshUsers,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _users.length) {
                    if (_currentPage < _totalPages && mounted) {
                      _currentPage++;
                      _loadUsers();
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return null;
                  }

                  final user = _users[index];
                  final isCurrentUser = user['id'] == _currentUserId;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user['username']?[0]?.toUpperCase() ?? 'U',
                        ),
                      ),
                      title: Text(user['username'] ?? '未知用户'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['email'] ?? ''),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  _getRoleDisplayName(user['role'] ?? 'user'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: _getRoleColor(
                                  user['role'] ?? 'user',
                                ).withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: _getRoleColor(user['role'] ?? 'user'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '知识库: ${user['knowledgeCount'] ?? 0}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '人设卡: ${user['personaCount'] ?? 0}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCurrentUser) ...[
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: '编辑角色',
                              onPressed: () => _showEditRoleDialog(
                                user['id'],
                                user['role'] ?? 'user',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: '删除用户',
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () => _deleteUser(
                                user['id'],
                                user['username'] ?? '未知用户',
                              ),
                            ),
                          ] else
                            const Text(
                              '当前用户',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _users.length + (_currentPage < _totalPages ? 1 : 0),
              ),
            ),
          // 底部操作按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton.extended(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('新增用户'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

