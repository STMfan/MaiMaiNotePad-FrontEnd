import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_router.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  List<Map<String, dynamic>> _knowledgeList = [];
  List<Map<String, dynamic>> _filteredKnowledgeList = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _uploaderController = TextEditingController();
  String _selectedSortOption = '最新发布';
  String _selectedCategory = '全部分类';
  String _selectedOrder = 'desc';
  final List<Map<String, String>> _sortOptions = const [
    {'label': '最新发布', 'sortBy': 'created_at', 'sortOrder': 'desc'},
    {'label': '最早发布', 'sortBy': 'created_at', 'sortOrder': 'asc'},
    {'label': '更新时间降序', 'sortBy': 'updated_at', 'sortOrder': 'desc'},
    {'label': '更新时间升序', 'sortBy': 'updated_at', 'sortOrder': 'asc'},
    {'label': '名称升序', 'sortBy': 'name', 'sortOrder': 'asc'},
    {'label': '名称降序', 'sortBy': 'name', 'sortOrder': 'desc'},
    {'label': '下载量降序', 'sortBy': 'downloads', 'sortOrder': 'desc'},
    {'label': '收藏数降序', 'sortBy': 'star_count', 'sortOrder': 'desc'},
  ];
  String _searchQuery = '';
  String _uploaderQuery = '';
  String _currentSortBy = 'created_at';
  String _currentSortOrder = 'desc';
  Timer? _searchDebounce;
  static const _searchDebounceDuration = Duration(milliseconds: 450);
  bool _isGridView = true;

  // 添加用户登录状态检查
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
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

    // 检查登录状态
    _checkLoginStatus();

    // 加载数据
    _loadKnowledgeList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _uploaderController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // 检查用户登录状态
  void _checkLoginStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isLoggedIn = userProvider.isLoggedIn;
    });
  }

  Future<void> _loadKnowledgeList({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final apiService = ApiService();
      final response = await apiService.getPublicKnowledge(
        name: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
        uploaderId: _uploaderQuery.trim().isEmpty ? null : _uploaderQuery.trim(),
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      );

      final items = response.items.map((kb) {
        final starCount = kb.starCount;
        return {
          'id': kb.id,
          'name': kb.name,
          'description': kb.description,
          'uploader_id': kb.uploaderId,
          'copyright_owner': kb.copyrightOwner,
          'star_count': starCount,
          'stars': starCount,
          'is_public': kb.isPublic,
          'is_pending': kb.isPending,
          'created_at': kb.createdAt.toIso8601String(),
          'updated_at': kb.updatedAt?.toIso8601String(),
          'file_names': kb.fileNames,
          'download_url': kb.downloadUrl,
          'preview_url': kb.previewUrl,
          'tags': kb.tags,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _knowledgeList = items;
        _filteredKnowledgeList = _applyLocalFilters(items);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('加载知识库失败: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _applyLocalFilters(
    List<Map<String, dynamic>> source,
  ) {
    var result = List<Map<String, dynamic>>.from(source);
    final query = _searchQuery.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((knowledge) {
        final name = knowledge['name']?.toString().toLowerCase() ?? '';
        final description =
            knowledge['description']?.toString().toLowerCase() ?? '';
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    if (_selectedCategory != '全部分类') {
      result = result.where((knowledge) {
        final tags = knowledge['tags'] as List<dynamic>? ?? [];
        return tags.contains(_selectedCategory);
      }).toList();
    }

    return result;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filteredKnowledgeList = _applyLocalFilters(_knowledgeList);
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      _searchDebounceDuration,
      () => _loadKnowledgeList(showLoadingIndicator: false),
    );
  }

  void _onUploaderChanged(String value) {
    setState(() {
      _uploaderQuery = value;
    });
  }

  void _applyUploaderFilter() {
    _loadKnowledgeList();
  }

  void _onSortOptionSelected(String sortOption) {
    final config = _sortOptions.firstWhere(
      (opt) => opt['label'] == sortOption,
      orElse: () => _sortOptions.first,
    );
    setState(() {
      _selectedSortOption = sortOption;
      _currentSortBy = config['sortBy']!;
      _currentSortOrder = config['sortOrder']!;
    });
    _loadKnowledgeList();
  }

  Map<String, String> _resolveSortConfig(String sortOption) {
    switch (sortOption) {
      case '最多收藏':
        return {'sortBy': 'star_count', 'sortOrder': 'desc'};
      case '名称排序':
        return {'sortBy': 'name', 'sortOrder': 'asc'};
      case '最新发布':
      default:
        return {'sortBy': 'created_at', 'sortOrder': 'desc'};
    }
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredKnowledgeList = _applyLocalFilters(_knowledgeList);
    });
  }

  // 导航到上传页面
  void _navigateToUpload() {
    if (_isLoggedIn) {
      Navigator.pushNamed(
        context,
        AppRouter.upload,
        arguments: {'type': 'knowledge'},
      );
    } else {
      // 未登录时导航到登录页面
      Navigator.pushNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 1200;
    final isTablet =
        mediaQuery.size.width > 800 && mediaQuery.size.width <= 1200;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('知识库'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // 搜索和筛选栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 搜索框
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '搜索...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _uploaderController,
                      decoration: InputDecoration(
                        hintText: '按上传者ID筛选',
                        prefixIcon: const Icon(Icons.person_search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.filter_alt),
                          tooltip: '应用上传者筛选',
                          onPressed: _applyUploaderFilter,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onChanged: _onUploaderChanged,
                      onSubmitted: (_) => _applyUploaderFilter(),
                    ),
                    const SizedBox(height: 16),
                    // 筛选选项
                    Row(
                      children: [
                        // 分类筛选
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: '分类',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: ['全部分类', '技术', '文学', '历史', '科学', '艺术']
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _filterByCategory(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 排序选项
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSortOption,
                            decoration: InputDecoration(
                              labelText: '排序',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: ['最新发布', '最多收藏', '名称排序']
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                _onSortOptionSelected(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 知识库列表
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredKnowledgeList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 64,
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无知识库',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? '没有找到匹配的知识库'
                                  : '还没有人上传知识库',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            _loadKnowledgeList(showLoadingIndicator: false),
                        child: _isGridView
                            ? _buildGridView(isDesktop, isTablet)
                            : _buildListView(),
                      ),
              ),
            ],
          ),
        ),
      ),
      // 添加上传按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToUpload,
        icon: const Icon(Icons.add),
        label: Text(_isLoggedIn ? '上传知识库' : '登录后上传'),
        tooltip: _isLoggedIn ? '上传知识库' : '请先登录后上传知识库',
      ),
    );
  }

  Widget _buildGridView(bool isDesktop, bool isTablet) {
    final crossAxisCount = isDesktop
        ? 4
        : isTablet
        ? 3
        : 2;
    final childAspectRatio = isDesktop ? 1.2 : 1.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: _filteredKnowledgeList.length,
        itemBuilder: (context, index) {
          final knowledge = _filteredKnowledgeList[index];
          return KnowledgeCard(
            knowledge: knowledge,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.knowledgeDetail,
                arguments: {'knowledgeId': knowledge['id']},
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        itemCount: _filteredKnowledgeList.length,
        itemBuilder: (context, index) {
          final knowledge = _filteredKnowledgeList[index];
          return KnowledgeCard(
            knowledge: knowledge,
            isListView: true,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.knowledgeDetail,
                arguments: {'knowledgeId': knowledge['id']},
              );
            },
          );
        },
      ),
    );
  }
}

class KnowledgeCard extends StatelessWidget {
  final Map<String, dynamic> knowledge;
  final VoidCallback onTap;
  final bool isListView;

  const KnowledgeCard({
    super.key,
    required this.knowledge,
    required this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = knowledge['name']?.toString() ?? '未命名';
    final description = knowledge['description']?.toString() ?? '暂无描述';
    final starCount =
        (knowledge['star_count'] ?? knowledge['stars'] ?? 0).toString();
    final uploaderId = knowledge['uploader_id']?.toString() ?? '未知用户';
    final copyrightOwner = knowledge['copyright_owner']?.toString();

    if (isListView) {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(name, style: theme.textTheme.titleMedium),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(starCount, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.person,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(uploaderId, style: theme.textTheme.bodySmall),
                  if (copyrightOwner != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.copyright,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(copyrightOwner, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: onTap,
        ),
      );
    }

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部图片区域
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.primary.withOpacity(0.4),
                  ],
                ),
              ),
              child: Icon(
                Icons.folder,
                size: 48,
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
              ),
              alignment: Alignment.center,
            ),

            // 内容区域
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(starCount, style: theme.textTheme.bodySmall),
                      const Spacer(),
                      Icon(
                        Icons.person,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        uploaderId,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
