import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ContentManagementTabContent extends StatefulWidget {
  const ContentManagementTabContent({super.key});

  @override
  State<ContentManagementTabContent> createState() =>
      _ContentManagementTabContentState();
}

class _ContentManagementTabContentState
    extends State<ContentManagementTabContent>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _knowledgeBases = [];
  List<Map<String, dynamic>> _personas = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;
  String? _statusFilter;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadContent(resetPage: true);
      }
    });
    _loadContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isKnowledgeTab => _tabController.index == 0;

  Future<void> _loadContent({bool resetPage = false}) async {
    if (!mounted) return;

    if (resetPage) {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = _isKnowledgeTab
          ? await _apiService.getAllKnowledgeBases(
              page: _currentPage,
              limit: 20,
              status: _statusFilter,
              search: _searchQuery,
            )
          : await _apiService.getAllPersonas(
              page: _currentPage,
              limit: 20,
              status: _statusFilter,
              search: _searchQuery,
            );

      final data = response.data['data'];
      final items = List<Map<String, dynamic>>.from(
        _isKnowledgeTab ? data['knowledgeBases'] : data['personas'],
      );

      if (mounted) {
        setState(() {
          if (resetPage) {
            if (_isKnowledgeTab) {
              _knowledgeBases = items;
            } else {
              _personas = items;
            }
          } else {
            if (_isKnowledgeTab) {
              _knowledgeBases.addAll(items);
            } else {
              _personas.addAll(items);
            }
          }
          _totalPages = (data['total'] / 20).ceil();
          _total = data['total'] ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载内容列表失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadContent(resetPage: true);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _statusFilter = status;
    });
    _loadContent(resetPage: true);
  }

  Future<void> _refreshContent() async {
    await _loadContent(resetPage: true);
  }

  Future<void> _deleteContent(String id, String name, bool isKnowledge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除${isKnowledge ? '知识库' : '人设卡'} "$name" 吗？\n\n此操作不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (isKnowledge) {
          await _apiService.deleteKnowledge(id);
        } else {
          await _apiService.deletePersona(id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isKnowledge ? '知识库' : '人设卡'}删除成功'),
            ),
          );
          _refreshContent();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('删除失败: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _revertContent(
    String id,
    String name,
    bool isKnowledge,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('退回内容'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '确定要退回${isKnowledge ? '知识库' : '人设卡'} "$name" 吗？\n\n退回后，内容将重新进入待审核状态。',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: '退回原因（可选）',
                    border: OutlineInputBorder(),
                    hintText: '请输入退回原因',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('确认退回'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        if (isKnowledge) {
          await _apiService.revertKnowledgeBase(
            id,
            reason: reasonController.text.isEmpty
                ? null
                : reasonController.text,
          );
        } else {
          await _apiService.revertPersonaCard(
            id,
            reason: reasonController.text.isEmpty
                ? null
                : reasonController.text,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isKnowledge ? '知识库' : '人设卡'}已退回待审核'),
            ),
          );
          _refreshContent();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('退回失败: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return '待审核';
      case 'approved':
        return '已通过';
      case 'rejected':
        return '已拒绝';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _currentItems =>
      _isKnowledgeTab ? _knowledgeBases : _personas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标签栏
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '知识库管理'),
            Tab(text: '人设卡管理'),
          ],
        ),
        // 搜索和筛选栏
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: '搜索${_isKnowledgeTab ? '知识库' : '人设卡'}（名称、描述）',
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
              Row(
                children: [
                  const Text('状态筛选: '),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<String?>(
                      segments: const [
                        ButtonSegment(value: null, label: Text('全部')),
                        ButtonSegment(
                          value: 'pending',
                          label: Text('待审核'),
                        ),
                        ButtonSegment(
                          value: 'approved',
                          label: Text('已通过'),
                        ),
                        ButtonSegment(
                          value: 'rejected',
                          label: Text('已拒绝'),
                        ),
                      ],
                      selected: {_statusFilter},
                      onSelectionChanged: (Set<String?> selection) {
                        _onStatusFilterChanged(selection.first);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '共 $_total 个${_isKnowledgeTab ? '知识库' : '人设卡'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        // 内容列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshContent,
            child: _isLoading && _currentItems.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _currentItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('加载失败: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshContent,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : _currentItems.isEmpty
                        ? const Center(child: Text('暂无内容'))
                        : ListView.builder(
                            itemCount: _currentItems.length +
                                (_currentPage < _totalPages ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _currentItems.length) {
                                if (_currentPage < _totalPages) {
                                  _currentPage++;
                                  _loadContent();
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return null;
                              }

                              final item = _currentItems[index];
                              final status = item['status'] ?? 'pending';
                              final canRevert = status == 'approved';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(item['name'] ?? '未知'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        item['description'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              _getStatusDisplayName(status),
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            backgroundColor: _getStatusColor(
                                              status,
                                            ).withOpacity(0.2),
                                            labelStyle: TextStyle(
                                              color: _getStatusColor(status),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '上传者: ${item['uploader_name'] ?? '未知'}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '⭐ ${item['star_count'] ?? 0}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (canRevert)
                                        IconButton(
                                          icon: const Icon(Icons.undo),
                                          tooltip: '退回',
                                          onPressed: () => _revertContent(
                                            item['id'],
                                            item['name'] ?? '未知',
                                            _isKnowledgeTab,
                                          ),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        tooltip: '删除',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                        onPressed: () => _deleteContent(
                                          item['id'],
                                          item['name'] ?? '未知',
                                          _isKnowledgeTab,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}



