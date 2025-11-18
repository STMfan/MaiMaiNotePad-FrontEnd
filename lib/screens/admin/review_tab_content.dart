import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/knowledge.dart';
import '../../models/persona.dart';

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

  Future<void> _loadPendingItems() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();

      // 获取待审核的知识库
      final knowledgeResponse = await apiService.get('/knowledge/pending');
      final List<dynamic> knowledgeList = knowledgeResponse.data;
      final List<Knowledge> knowledgeItems = knowledgeList
          .map((item) => Knowledge.fromJson(item))
          .toList();

      // 获取待审核的人设卡
      final personaResponse = await apiService.get('/persona/pending');
      final List<dynamic> personaList = personaResponse.data;
      final List<Persona> personaItems = personaList
          .map((item) => Persona.fromJson(item))
          .toList();

      if (mounted) {
        setState(() {
          _pendingKnowledge = knowledgeItems;
          _pendingPersonas = personaItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveKnowledge(String knowledgeId) async {
    try {
      final apiService = ApiService();
      await apiService.post('/knowledge/$knowledgeId/approve');

      setState(() {
        _pendingKnowledge.removeWhere((item) => item.id == knowledgeId);
      });

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
      await apiService.post('/knowledge/$knowledgeId/reject');

      setState(() {
        _pendingKnowledge.removeWhere((item) => item.id == knowledgeId);
      });

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
      await apiService.post('/persona/$personaId/approve');

      setState(() {
        _pendingPersonas.removeWhere((item) => item.id == personaId);
      });

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
      await apiService.post('/persona/$personaId/reject');

      setState(() {
        _pendingPersonas.removeWhere((item) => item.id == personaId);
      });

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
      return const Center(child: Text('暂无待审核的知识库'));
    }

    return RefreshIndicator(
      onRefresh: _loadPendingItems,
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
      return const Center(child: Text('暂无待审核的人设卡'));
    }

    return RefreshIndicator(
      onRefresh: _loadPendingItems,
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
    );
  }
}