import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/knowledge.dart';
import '../models/persona.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'knowledge_detail_screen.dart';
import 'persona_detail_screen.dart';

class StarsScreen extends StatefulWidget {
  const StarsScreen({super.key});

  @override
  _StarsScreenState createState() => _StarsScreenState();
}

class _StarsScreenState extends State<StarsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Knowledge> _starredKnowledge = [];
  List<Persona> _starredPersonas = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStarredItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStarredItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiService = ApiService();

      final starsData = await apiService.getUserStars(userProvider.token!);

      setState(() {
        _starredKnowledge = starsData['knowledge'] ?? [];
        _starredPersonas = starsData['personas'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载收藏内容失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadStarredItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '知识库'),
            Tab(text: '人设卡'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('重试'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildKnowledgeList(), _buildPersonaList()],
            ),
    );
  }

  Widget _buildKnowledgeList() {
    if (_starredKnowledge.isEmpty) {
      return const Center(child: Text('暂无收藏的知识库'));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _starredKnowledge.length,
        itemBuilder: (context, index) {
          final knowledge = _starredKnowledge[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: ListTile(
              title: Text(
                knowledge.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                knowledge.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        KnowledgeDetailScreen(knowledgeId: knowledge.id),
                  ),
                ).then((_) => _refreshData());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonaList() {
    if (_starredPersonas.isEmpty) {
      return const Center(child: Text('暂无收藏的人设卡'));
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _starredPersonas.length,
        itemBuilder: (context, index) {
          final persona = _starredPersonas[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: ListTile(
              title: Text(
                persona.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                persona.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PersonaDetailScreen(personaId: persona.id),
                  ),
                ).then((_) => _refreshData());
              },
            ),
          );
        },
      ),
    );
  }
}
