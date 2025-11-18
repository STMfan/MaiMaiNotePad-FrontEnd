import 'package:flutter/material.dart';
import '../../models/persona.dart';
import '../../services/api_service.dart';
import '../../utils/app_router.dart';

class PersonaScreen extends StatefulWidget {
  const PersonaScreen({super.key});

  @override
  State<PersonaScreen> createState() => _PersonaScreenState();
}

class _PersonaScreenState extends State<PersonaScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Persona> _personaList = [];
  List<Persona> _filteredPersonaList = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPersonaList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonaList() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.get('/api/persona');
      final data = response.data;

      if (data['success'] == true) {
        final List<dynamic> personaData = data['data'] ?? [];
        setState(() {
          _personaList = personaData
              .map((item) => Persona.fromJson(item))
              .toList();
          _filteredPersonaList = List.from(_personaList);
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
          return persona.name.toLowerCase().contains(query.toLowerCase()) ||
              persona.description.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('人设卡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPersonaList,
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
                labelText: '搜索人设卡',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterPersonaList,
            ),
          ),

          // 人设卡列表
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _filteredPersonaList.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty ? '暂无人设卡' : '未找到匹配的人设卡',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredPersonaList.length,
                    itemBuilder: (context, index) {
                      final persona = _filteredPersonaList[index];
                      return PersonaCard(
                        persona: persona,
                        onTap: () {
                          // 跳转到详情页面
                          Navigator.pushNamed(
                            context,
                            AppRouter.personaDetail,
                            arguments: {'personaId': persona.id},
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
              content: Text('请使用首页的上传管理功能来创建人设卡'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PersonaCard extends StatelessWidget {
  final Persona persona;
  final VoidCallback onTap;

  const PersonaCard({super.key, required this.persona, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(persona.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(persona.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(persona.author ?? '未知作者'),
                const SizedBox(width: 16),
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${persona.starCount}'),
                if (persona.tags.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.tag, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      persona.tags.join(', '),
                      overflow: TextOverflow.ellipsis,
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
}
