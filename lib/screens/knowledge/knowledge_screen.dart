import 'package:flutter/material.dart';
import '../../models/knowledge.dart';
import '../../services/api_service.dart';
import '../../utils/app_router.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Knowledge> _knowledgeList = [];
  List<Knowledge> _filteredKnowledgeList = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadKnowledgeList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadKnowledgeList() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.get('/knowledge');
      final data = response.data;

      if (data['success'] == true) {
        final List<dynamic> knowledgeData = data['data'] ?? [];
        setState(() {
          _knowledgeList = knowledgeData
              .map((item) => Knowledge.fromJson(item))
              .toList();
          _filteredKnowledgeList = List.from(_knowledgeList);
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? '加载知识库失败'),
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
            content: Text('加载知识库失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _filterKnowledgeList(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredKnowledgeList = List.from(_knowledgeList);
      } else {
        _filteredKnowledgeList = _knowledgeList.where((knowledge) {
          return knowledge.name.toLowerCase().contains(query.toLowerCase()) ||
              knowledge.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadKnowledgeList,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '搜索知识库',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterKnowledgeList,
            ),
          ),

          // 知识库列表
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _filteredKnowledgeList.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty ? '暂无知识库' : '未找到匹配的知识库',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredKnowledgeList.length,
                    itemBuilder: (context, index) {
                      final knowledge = _filteredKnowledgeList[index];
                      return KnowledgeCard(
                        knowledge: knowledge,
                        onTap: () {
                          // 跳转到详情页面
                          Navigator.pushNamed(
                            context,
                            AppRouter.knowledgeDetail,
                            arguments: {'knowledgeId': knowledge.id},
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 显示提示信息，引导用户使用上传管理功能
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请使用首页的上传管理功能来上传知识库'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class KnowledgeCard extends StatelessWidget {
  final Knowledge knowledge;
  final VoidCallback onTap;

  const KnowledgeCard({
    super.key,
    required this.knowledge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(knowledge.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(knowledge.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${knowledge.starCount}'),
                const SizedBox(width: 16),
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(knowledge.uploaderId),
                if (knowledge.copyrightOwner != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.copyright, size: 16),
                  const SizedBox(width: 4),
                  Text(knowledge.copyrightOwner!),
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
}
