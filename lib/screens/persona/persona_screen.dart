import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_router.dart';

class PersonaScreen extends StatefulWidget {
  const PersonaScreen({super.key});

  @override
  State<PersonaScreen> createState() => _PersonaScreenState();
}

class _PersonaScreenState extends State<PersonaScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _personaList = [];
  List<Map<String, dynamic>> _filteredPersonaList = [];
  String _searchQuery = '';
  String _selectedSortOption = '最新发布';
  String _selectedCategory = '全部分类';
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
    _loadPersonaList();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 检查用户登录状态
  void _checkLoginStatus() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isLoggedIn = userProvider.isLoggedIn;
    });
  }

  Future<void> _loadPersonaList() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/persona/public');
      final data = response.data;

      if (data['success'] == true) {
        setState(() {
          _personaList = List<Map<String, dynamic>>.from(data['data'] ?? []);
          _filteredPersonaList = _personaList;
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '加载人设卡失败'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载人设卡失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterPersonaList(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredPersonaList = List.from(_personaList);
      } else {
        _filteredPersonaList = _personaList.where((persona) {
          final name = persona['name']?.toString().toLowerCase() ?? '';
          final description = persona['description']?.toString().toLowerCase() ?? '';
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) || description.contains(searchQuery);
        }).toList();
      }
    });
  }

  void _sortPersonaList(String sortOption) {
    setState(() {
      _selectedSortOption = sortOption;
      switch (sortOption) {
        case '最新发布':
          _filteredPersonaList.sort((a, b) {
            final aTime =
                DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
            final bTime =
                DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          break;
        case '最多收藏':
          _filteredPersonaList.sort((a, b) {
            final aStars = int.tryParse(a['stars']?.toString() ?? '0') ?? 0;
            final bStars = int.tryParse(b['stars']?.toString() ?? '0') ?? 0;
            return bStars.compareTo(aStars);
          });
          break;
        case '名称排序':
          _filteredPersonaList.sort((a, b) {
            final aName = a['name']?.toString() ?? '';
            final bName = b['name']?.toString() ?? '';
            return aName.compareTo(bName);
          });
          break;
      }
    });
  }

  void _filterByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == '全部分类') {
        _filteredPersonaList = List.from(_personaList);
      } else {
        _filteredPersonaList = _personaList.where((persona) {
          final tags = persona['tags'] as List<dynamic>? ?? [];
          return tags.contains(category);
        }).toList();
      }
    });
  }

  // 导航到上传页面
  void _navigateToUpload() {
    if (_isLoggedIn) {
      Navigator.pushNamed(
        context,
        AppRouter.upload,
        arguments: {'type': 'persona'},
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
        title: const Text('人设卡'),
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
                      onChanged: _filterPersonaList,
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
                            items: ['全部分类', '角色扮演', '助手', '创意', '专业', '娱乐']
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
                                _sortPersonaList(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 人设卡列表
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPersonaList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: 64,
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无人设卡',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? '没有找到匹配的人设卡'
                                  : '还没有人上传人设卡',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPersonaList,
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
        label: Text(_isLoggedIn ? '上传人设卡' : '登录后上传'),
        tooltip: _isLoggedIn ? '上传人设卡' : '请先登录后上传人设卡',
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
        itemCount: _filteredPersonaList.length,
        itemBuilder: (context, index) {
          final persona = _filteredPersonaList[index];
          return PersonaCard(
            persona: persona,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.personaDetail,
                arguments: {'personaId': persona['id']},
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
        itemCount: _filteredPersonaList.length,
        itemBuilder: (context, index) {
          final persona = _filteredPersonaList[index];
          return PersonaCard(
            persona: persona,
            isListView: true,
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.personaDetail,
                arguments: {'personaId': persona['id']},
              );
            },
          );
        },
      ),
    );
  }
}

class PersonaCard extends StatelessWidget {
  final Map<String, dynamic> persona;
  final VoidCallback onTap;
  final bool isListView;

  const PersonaCard({
    super.key,
    required this.persona,
    required this.onTap,
    this.isListView = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = persona['name']?.toString() ?? '未命名';
    final description = persona['description']?.toString() ?? '暂无描述';
    final starCount = persona['stars']?.toString() ?? '0';
    final author = persona['author']?.toString() ?? '未知作者';
    final tags = (persona['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

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
                  Icon(Icons.person, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(author, style: theme.textTheme.bodySmall),
                  const SizedBox(width: 16),
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(starCount, style: theme.textTheme.bodySmall),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.tag, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tags.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
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
                    theme.colorScheme.secondary.withOpacity(0.8),
                    theme.colorScheme.secondary.withOpacity(0.4),
                  ],
                ),
              ),
              child: Icon(
                Icons.person,
                size: 48,
                color: theme.colorScheme.onSecondary.withOpacity(0.8),
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
                      Icon(Icons.person, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 2),
                      Text(
                        author,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(starCount, style: theme.textTheme.bodySmall),
                    ],
                  ),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}