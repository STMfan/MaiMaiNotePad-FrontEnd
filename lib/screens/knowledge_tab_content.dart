import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/knowledge.dart';
import '../utils/app_router.dart';

// 知识库标签页内容组件
class KnowledgeTabContent extends StatelessWidget {
  final List<Knowledge> knowledgeList;
  final TextEditingController searchController;
  final Function(String) onSearch;

  const KnowledgeTabContent({
    super.key,
    required this.knowledgeList,
    required this.searchController,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // 获取屏幕尺寸信息
        final screenWidth = MediaQuery.of(context).size.width;
        final isLargeScreen = screenWidth >= 1200; // 大屏幕（电脑）
        final isMediumScreen =
            screenWidth >= 800 && screenWidth < 1200; // 中等屏幕（平板）

        return Padding(
          padding: EdgeInsets.all(
            isLargeScreen ? 32 : (isMediumScreen ? 24 : 16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索区域 - 响应式设计
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '知识库管理',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 24 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isLargeScreen ? 16 : 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: '搜索知识库...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isLargeScreen ? 16 : 12,
                                  vertical: isLargeScreen ? 16 : 12,
                                ),
                              ),
                              onSubmitted: onSearch,
                            ),
                          ),
                          SizedBox(width: isLargeScreen ? 16 : 12),
                          ElevatedButton.icon(
                            onPressed: () => onSearch(searchController.text),
                            icon: const Icon(Icons.search),
                            label: Text(
                              '搜索',
                              style: TextStyle(
                                fontSize: isLargeScreen ? 16 : 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLargeScreen ? 16 : 12,
                                vertical: isLargeScreen ? 16 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isLargeScreen ? 24 : 20),

              // 知识库列表 - 响应式网格
              Expanded(
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                    child: knowledgeList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: isLargeScreen ? 64 : 48,
                                  color: Theme.of(context).disabledColor,
                                ),
                                SizedBox(height: isLargeScreen ? 16 : 12),
                                Text(
                                  '暂无知识库',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 18 : 16,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                SizedBox(height: isLargeScreen ? 12 : 8),
                                Text(
                                  '请登录后上传知识库文件',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 14 : 12,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                                SizedBox(height: isLargeScreen ? 24 : 16),
                                if (userProvider.isLoggedIn)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // 使用回调函数导航到上传管理
                                      // 注意：这里需要父组件提供导航回调
                                      Navigator.pushNamed(
                                        context,
                                        AppRouter.knowledge,
                                      );
                                    },
                                    icon: const Icon(Icons.upload_file),
                                    label: Text(
                                      '上传知识库',
                                      style: TextStyle(
                                        fontSize: isLargeScreen ? 16 : 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isLargeScreen ? 16 : 12,
                                        vertical: isLargeScreen ? 16 : 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLargeScreen
                                      ? 3
                                      : (isMediumScreen ? 2 : 1),
                                  childAspectRatio: isLargeScreen ? 1.6 : 1.4,
                                  crossAxisSpacing: isLargeScreen ? 24 : 16,
                                  mainAxisSpacing: isLargeScreen ? 24 : 16,
                                ),
                            itemCount: knowledgeList.length,
                            itemBuilder: (context, index) {
                              final knowledge = knowledgeList[index];
                              return _buildKnowledgeCard(
                                context,
                                knowledge,
                                isLargeScreen,
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建知识库卡片 - 响应式设计
  Widget _buildKnowledgeCard(
    BuildContext context,
    Knowledge knowledge,
    bool isLargeScreen,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.knowledgeDetail,
            arguments: knowledge.id,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(isLargeScreen ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      knowledge.name,
                      style: TextStyle(
                        fontSize: isLargeScreen ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (knowledge.isPublic)
                    Icon(
                      Icons.public,
                      size: isLargeScreen ? 20 : 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              SizedBox(height: isLargeScreen ? 8 : 6),
              Expanded(
                child: Text(
                  knowledge.description,
                  style: TextStyle(
                    fontSize: isLargeScreen ? 14 : 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: isLargeScreen ? 12 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '作者: ${knowledge.authorName}',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 12 : 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    '${knowledge.fileNames.length} 文件',
                    style: TextStyle(
                      fontSize: isLargeScreen ? 12 : 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
