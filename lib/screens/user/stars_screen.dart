import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/knowledge.dart';
import '../../models/persona.dart';
import '../../utils/app_theme.dart';
import '../../viewmodels/stars_viewmodel.dart';
import '../knowledge/detail_screen.dart';
import '../persona/detail_screen.dart';

class StarsScreen extends StatelessWidget {
  const StarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StarsViewModel()..init(),
      child: const DefaultTabController(
        length: 2,
        child: _StarsView(),
      ),
    );
  }
}

class _StarsView extends StatelessWidget {
  const _StarsView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<StarsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<Map<String, String>>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              final sortBy = value['sortBy'] ?? 'created_at';
              final sortOrder = value['sortOrder'] ?? 'desc';
              context
                  .read<StarsViewModel>()
                  .changeSort(sortBy: sortBy, sortOrder: sortOrder);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: {'sortBy': 'created_at', 'sortOrder': 'desc'},
                child: Text('按收藏时间（新→旧）'),
              ),
              PopupMenuItem(
                value: {'sortBy': 'created_at', 'sortOrder': 'asc'},
                child: Text('按收藏时间（旧→新）'),
              ),
              PopupMenuItem(
                value: {'sortBy': 'star_count', 'sortOrder': 'desc'},
                child: Text('按收藏数（高→低）'),
              ),
            ],
          ),
        ],
        bottom: const TabBar(
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: '知识库'),
            Tab(text: '人设卡'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            children: [
              _KnowledgeList(viewModel: viewModel),
              _PersonaList(viewModel: viewModel),
            ],
          ),
          if (viewModel.isBusy)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}

class _KnowledgeList extends StatelessWidget {
  const _KnowledgeList({required this.viewModel});

  final StarsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final knowledge = viewModel.knowledge;
    if (viewModel.errorMessage != null && knowledge.isEmpty) {
      return _ErrorView(
        message: viewModel.errorMessage!,
        onRetry: () => context.read<StarsViewModel>().refresh(type: 'knowledge'),
      );
    }
    if (knowledge.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<StarsViewModel>().refresh(type: 'knowledge'),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('暂无收藏的知识库')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<StarsViewModel>().refresh(type: 'knowledge'),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: knowledge.length + (viewModel.knowledgeHasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= knowledge.length) {
            context.read<StarsViewModel>().loadMore(type: 'knowledge');
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = knowledge[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: ListTile(
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    tooltip: '取消收藏',
                    onPressed: () async {
                      try {
                        await context.read<StarsViewModel>().unstarKnowledge(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已取消收藏')),
                        );
                      } catch (_) {}
                    },
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        KnowledgeDetailScreen(knowledgeId: item.id),
                  ),
                ).then((_) => context
                    .read<StarsViewModel>()
                    .refresh(type: 'knowledge'));
              },
            ),
          );
        },
      ),
    );
  }
}

class _PersonaList extends StatelessWidget {
  const _PersonaList({required this.viewModel});

  final StarsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final personas = viewModel.personas;
    if (viewModel.errorMessage != null && personas.isEmpty) {
      return _ErrorView(
        message: viewModel.errorMessage!,
        onRetry: () => context.read<StarsViewModel>().refresh(type: 'persona'),
      );
    }
    if (personas.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<StarsViewModel>().refresh(type: 'persona'),
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(child: Text('暂无收藏的人设卡')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<StarsViewModel>().refresh(type: 'persona'),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: personas.length + (viewModel.personaHasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= personas.length) {
            context.read<StarsViewModel>().loadMore(type: 'persona');
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final persona = personas[index];
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    tooltip: '取消收藏',
                    onPressed: () async {
                      try {
                        await context.read<StarsViewModel>().unstarPersona(persona.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已取消收藏')),
                        );
                      } catch (_) {}
                    },
                  ),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PersonaDetailScreen(personaId: persona.id),
                  ),
                ).then(
                    (_) => context.read<StarsViewModel>().refresh(type: 'persona'));
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}


