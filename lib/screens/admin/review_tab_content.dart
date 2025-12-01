import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/knowledge.dart';
import '../../models/persona.dart';
import '../../widgets/pagination_widget.dart';

class ReviewTabContent extends StatefulWidget {
  const ReviewTabContent({super.key});

  @override
  State<ReviewTabContent> createState() => _ReviewTabContentState();
}

class _ReviewTabContentState extends State<ReviewTabContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Knowledge> _pendingKnowledge = [];
  List<Persona> _pendingPersonas = [];
  bool _isLoading = false;
  String? _error;

  // 分页状态
  int _knowledgeCurrentPage = 1;
  int _knowledgeTotal = 0;
  final int _knowledgePageSize = 20;
  int _personaCurrentPage = 1;
  int _personaTotal = 0;
  final int _personaPageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPendingItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingItems({int? knowledgePage, int? personaPage}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();

      // 获取待审核的知识库（使用封装好的方法）
      final knowledgeResponse = await apiService.getPendingKnowledge(
        page: knowledgePage ?? _knowledgeCurrentPage,
        pageSize: _knowledgePageSize,
      );

      // 获取待审核的人设卡（使用封装好的方法）
      final personaResponse = await apiService.getPendingPersonas(
        page: personaPage ?? _personaCurrentPage,
        pageSize: _personaPageSize,
      );

      if (mounted) {
        setState(() {
          _pendingKnowledge = knowledgeResponse.items;
          _knowledgeTotal = knowledgeResponse.total;
          if (knowledgePage != null) {
            _knowledgeCurrentPage = knowledgePage;
          }

          _pendingPersonas = personaResponse.items;
          _personaTotal = personaResponse.total;
          if (personaPage != null) {
            _personaCurrentPage = personaPage;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载待审核内容失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _onKnowledgePageChanged(int page) {
    _loadPendingItems(knowledgePage: page);
  }

  void _onPersonaPageChanged(int page) {
    _loadPendingItems(personaPage: page);
  }

  Future<void> _approveKnowledge(String knowledgeId) async {
    try {
      final apiService = ApiService();
      await apiService.approveKnowledge(knowledgeId);

      setState(() {
        _pendingKnowledge.removeWhere((item) => item.id == knowledgeId);
      });
      _loadPendingItems();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('知识库已通过审核')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  Future<void> _rejectKnowledge(String knowledgeId) async {
    try {
      final apiService = ApiService();
      await apiService.rejectKnowledge(knowledgeId);

      setState(() {
        _pendingKnowledge.removeWhere((item) => item.id == knowledgeId);
      });
      _loadPendingItems();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('知识库已拒绝')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  Future<void> _approvePersona(String personaId) async {
    try {
      final apiService = ApiService();
      await apiService.approvePersona(personaId);

      setState(() {
        _pendingPersonas.removeWhere((item) => item.id == personaId);
      });
      _loadPendingItems();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('人设卡已通过审核')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  Future<void> _rejectPersona(String personaId) async {
    try {
      final apiService = ApiService();
      await apiService.rejectPersona(personaId);

      setState(() {
        _pendingPersonas.removeWhere((item) => item.id == personaId);
      });
      _loadPendingItems();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('人设卡已拒绝')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('审核管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '知识库'),
            Tab(text: '人设卡'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingItems,
            tooltip: '刷新',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildKnowledgeList(), _buildPersonaList()],
      ),
    );
  }

  Widget _buildKnowledgeList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingItems,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_pendingKnowledge.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无待审核的知识库'),
            if (_knowledgeTotal > 0)
              Text(
                '总数: $_knowledgeTotal',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPendingItems(),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _pendingKnowledge.length,
              itemBuilder: (context, index) {
                final knowledge = _pendingKnowledge[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(knowledge.name),
                    subtitle: Text('作者: ${knowledge.authorName}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approveKnowledge(knowledge.id),
                          tooltip: '通过',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectKnowledge(knowledge.id),
                          tooltip: '拒绝',
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/knowledge_detail',
                        arguments: {'knowledgeId': knowledge.id},
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (_knowledgeTotal > 0)
            PaginationWidget(
              currentPage: _knowledgeCurrentPage,
              totalPages: (_knowledgeTotal / _knowledgePageSize)
                  .ceil()
                  .clamp(1, double.infinity)
                  .toInt(),
              total: _knowledgeTotal,
              pageSize: _knowledgePageSize,
              onPageChanged: _onKnowledgePageChanged,
            ),
        ],
      ),
    );
  }

  Widget _buildPersonaList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('加载失败: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingItems,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_pendingPersonas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('暂无待审核的人设卡'),
            if (_personaTotal > 0)
              Text(
                '总数: $_personaTotal',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPendingItems(),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _pendingPersonas.length,
              itemBuilder: (context, index) {
                final persona = _pendingPersonas[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(persona.name),
                    subtitle: Text('作者: ${persona.authorName}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _approvePersona(persona.id),
                          tooltip: '通过',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _rejectPersona(persona.id),
                          tooltip: '拒绝',
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/persona_detail',
                        arguments: {'personaId': persona.id},
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (_personaTotal > 0)
            PaginationWidget(
              currentPage: _personaCurrentPage,
              totalPages: (_personaTotal / _personaPageSize)
                  .ceil()
                  .clamp(1, double.infinity)
                  .toInt(),
              total: _personaTotal,
              pageSize: _personaPageSize,
              onPageChanged: _onPersonaPageChanged,
            ),
        ],
      ),
    );
  }
}
