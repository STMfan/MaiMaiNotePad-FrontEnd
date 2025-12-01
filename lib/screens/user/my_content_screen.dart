import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/knowledge.dart';
import '../../models/persona.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import '../../widgets/pagination_widget.dart';
import '../../utils/app_router.dart';

enum ContentStatusFilter { all, pending, approved, rejected }

class MyContentScreen extends StatefulWidget {
  const MyContentScreen({super.key});

  @override
  State<MyContentScreen> createState() => _MyContentScreenState();
}

class _MyContentScreenState extends State<MyContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;


  // 筛选与分页状态
  String _nameQuery = '';
  String _tagQuery = '';
  ContentStatusFilter _statusFilter = ContentStatusFilter.all;
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  String _userFilter = '';
  static const int _pageSize = 10;
  int _kbPage = 1;
  int _personaPage = 1;

  // 服务端分页数据
  List<Knowledge> _kbItems = [];
  int _kbTotal = 0;
  List<Persona> _personaItems = [];
  int _personaTotal = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 等待用户信息就绪后再加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        _loadData();
      } else {
        // 监听用户变化
        Provider.of<UserProvider>(context, listen: false)
            .addListener(_onUserReady);
      }
    });
  }

  @override
  void dispose() {
    Provider.of<UserProvider>(context, listen: false)
        .removeListener(_onUserReady);
    _tabController.dispose();
    super.dispose();
  }

  void _onUserReady() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      Provider.of<UserProvider>(context, listen: false)
          .removeListener(_onUserReady);
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUserId = userProvider.user?.id ?? '';
    final targetUserId =
        _userFilter.trim().isEmpty ? currentUserId : _userFilter.trim();

    if (targetUserId.isEmpty) {
      setState(() {
        _error = '未获取到用户信息，请先登录';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = ApiService();

      final kb = await apiService.getUserKnowledge(
        targetUserId,
        page: _kbPage,
        pageSize: _pageSize,
        name: _nameQuery,
        tag: _tagQuery,
        status: _statusFilter.name,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      final personas = await apiService.getUserPersonas(
        targetUserId,
        page: _personaPage,
        pageSize: _pageSize,
        name: _nameQuery,
        tag: _tagQuery,
        status: _statusFilter.name,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      setState(() {
        _kbItems = kb.items;
        _kbTotal = kb.total;
        _personaItems = personas.items;
        _personaTotal = personas.total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _deriveStatus({required bool isPending, required bool isPublic}) {
    if (isPending) return 'pending';
    if (isPublic) return 'approved';
    return 'rejected';
  }

  bool _personaPending(Persona p) {
    try {
      final json = p.toJson();
      return json['is_pending'] == true;
    } catch (_) {
      return false;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return '待审核';
      case 'approved':
        return '已通过';
      case 'rejected':
      default:
        return '已退回';
    }
  }

  Future<void> _deleteKnowledge(String id) async {
    final apiService = ApiService();
    await apiService.deleteKnowledge(id);
  }

  Future<void> _deletePersona(String id) async {
    final apiService = ApiService();
    await apiService.deletePersona(id);
  }

  Widget _buildFilters(bool isAdmin) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 200,
          child: TextField(
            decoration: const InputDecoration(
              labelText: '名称搜索',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() {
              _nameQuery = v;
              _kbPage = 1;
              _personaPage = 1;
            }),
            onSubmitted: (_) => _loadData(),
          ),
        ),
        SizedBox(
          width: 200,
          child: TextField(
            decoration: const InputDecoration(
              labelText: '标签搜索',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() {
              _tagQuery = v;
              _kbPage = 1;
              _personaPage = 1;
            }),
            onSubmitted: (_) => _loadData(),
          ),
        ),
        DropdownButton<ContentStatusFilter>(
          value: _statusFilter,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _statusFilter = val;
                _kbPage = 1;
                _personaPage = 1;
              });
              _loadData();
            }
          },
          items: const [
            DropdownMenuItem(
              value: ContentStatusFilter.all,
              child: Text('全部状态'),
            ),
            DropdownMenuItem(
              value: ContentStatusFilter.pending,
              child: Text('待审核'),
            ),
            DropdownMenuItem(
              value: ContentStatusFilter.approved,
              child: Text('已通过'),
            ),
            DropdownMenuItem(
              value: ContentStatusFilter.rejected,
              child: Text('已退回'),
            ),
          ],
        ),
        DropdownButton<String>(
          value: _sortBy,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _sortBy = val;
                _kbPage = 1;
                _personaPage = 1;
              });
              _loadData();
            }
          },
          items: const [
            DropdownMenuItem(value: 'created_at', child: Text('按创建时间')),
            DropdownMenuItem(value: 'updated_at', child: Text('按更新时间')),
            DropdownMenuItem(value: 'name', child: Text('按名称')),
            DropdownMenuItem(value: 'downloads', child: Text('按下载')),
            DropdownMenuItem(value: 'star_count', child: Text('按收藏')),
          ],
        ),
        DropdownButton<String>(
          value: _sortOrder,
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _sortOrder = val;
                _kbPage = 1;
                _personaPage = 1;
              });
              _loadData();
            }
          },
          items: const [
            DropdownMenuItem(value: 'desc', child: Text('降序')),
            DropdownMenuItem(value: 'asc', child: Text('升序')),
          ],
        ),
        if (isAdmin)
          SizedBox(
            width: 200,
            child: TextField(
              decoration: const InputDecoration(
                labelText: '用户ID（仅管理员）',
                hintText: '空则查看自己',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) {
                _userFilter = v;
              },
              onSubmitted: (_) => _loadData(),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('刷新'),
        ),
      ],
    );
  }

  Widget _buildKnowledgeList(bool isAdmin) {
    return Column(
      children: [
        _buildFilters(isAdmin),
        const SizedBox(height: 12),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(child: Text('加载失败: $_error')),
          )
        else if (_kbItems.isEmpty)
          const Expanded(child: Center(child: Text('暂无数据')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _kbItems.length,
              itemBuilder: (context, index) {
                final item = _kbItems[index];
                final status = _deriveStatus(
                  isPending: item.isPending,
                  isPublic: item.isPublic,
                );
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        '${_statusText(status)} · 文件 ${item.files.length} · 更新 ${item.updatedAt ?? item.createdAt}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        switch (val) {
                          case 'view':
                            Navigator.pushNamed(
                              context,
                              AppRouter.knowledgeDetail,
                              arguments: {'knowledgeId': item.id},
                            );
                            break;
                          case 'edit':
                            Navigator.pushNamed(
                              context,
                              AppRouter.editKnowledge,
                              arguments: {'knowledge': item},
                            );
                            break;
                          case 'delete':
                            _confirmDelete(isKnowledge: true, id: item.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'view', child: Text('查看详情')),
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (!_isLoading && _error == null && _kbItems.isNotEmpty)
          PaginationWidget(
            currentPage: _kbPage,
            totalPages:
                (_kbTotal / _pageSize).ceil().clamp(1, double.infinity).toInt(),
            total: _kbTotal,
            pageSize: _pageSize,
            onPageChanged: (p) => setState(() {
              _kbPage = p;
              _loadData();
            }),
          ),
      ],
    );
  }

  Widget _buildPersonaList(bool isAdmin) {
    return Column(
      children: [
        _buildFilters(isAdmin),
        const SizedBox(height: 12),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Expanded(
            child: Center(child: Text('加载失败: $_error')),
          )
        else if (_personaItems.isEmpty)
          const Expanded(child: Center(child: Text('暂无数据')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _personaItems.length,
              itemBuilder: (context, index) {
                final item = _personaItems[index];
                final status = _deriveStatus(
                  isPending: _personaPending(item),
                  isPublic: item.isPublic,
                );
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                        '${_statusText(status)} · 文件 ${item.fileNames.length} · 更新 ${item.updatedAt ?? item.createdAt}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        switch (val) {
                          case 'view':
                            Navigator.pushNamed(
                              context,
                              AppRouter.personaDetail,
                              arguments: {'personaId': item.id},
                            );
                            break;
                          case 'delete':
                            _confirmDelete(isKnowledge: false, id: item.id);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'view', child: Text('查看详情')),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('删除', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (!_isLoading && _error == null && _personaItems.isNotEmpty)
          PaginationWidget(
            currentPage: _personaPage,
            totalPages:
                (_personaTotal / _pageSize).ceil().clamp(1, double.infinity).toInt(),
            total: _personaTotal,
            pageSize: _pageSize,
            onPageChanged: (p) => setState(() {
              _personaPage = p;
              _loadData();
            }),
          ),
      ],
    );
  }

  Future<void> _confirmDelete({required bool isKnowledge, required String id}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后不可恢复，确认删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      if (isKnowledge) {
        await _deleteKnowledge(id);
      } else {
        await _deletePersona(id);
      }
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final isAdmin = user?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的内容管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '知识库'),
            Tab(text: '人设卡'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKnowledgeList(isAdmin),
          _buildPersonaList(isAdmin),
        ],
      ),
    );
  }
}
