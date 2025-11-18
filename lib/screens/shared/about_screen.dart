import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于应用')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 应用Logo和名称
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: const Icon(
                      Icons.note_alt,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '版本 ${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 应用介绍
            Text(
              '应用介绍',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '麦麦笔记本（MaiMaiNotePad，简称MaiMNP或MMNP）是MaiBot的非官方内容分享站。'
              '本应用主要用于分享知识库和人设卡，为MaiBot用户提供一个便捷的内容分享平台。'
              '用户可以上传、浏览和收藏各种知识库和人设卡，并通过审核机制确保内容质量。',
            ),

            const SizedBox(height: 24),

            // 主要功能
            Text(
              '主要功能',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem(
              context,
              '知识库分享',
              '支持上传多个txt和json格式的文件，包含详细的元数据信息。',
            ),
            _buildFeatureItem(
              context,
              '人设卡分享',
              '支持上传最多两个.toml格式的人设卡文件，包含完整的角色设定。',
            ),
            _buildFeatureItem(
              context,
              '审核机制',
              '通过admin和moderator角色的审核，确保分享内容的质量和合规性。',
            ),
            _buildFeatureItem(context, '消息系统', '通过内置消息系统，及时通知用户审核结果和重要信息。'),
            _buildFeatureItem(
              context,
              '多端支持',
              '支持Web、Windows、macOS、Linux、Android和iOS平台。',
            ),

            const SizedBox(height: 24),

            // 技术栈
            Text(
              '技术栈',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTechItem(context, '前端框架', 'Flutter'),
            _buildTechItem(context, '状态管理', 'Provider'),
            _buildTechItem(context, '网络请求', 'Dio'),
            _buildTechItem(context, '本地存储', 'SharedPreferences'),

            const SizedBox(height: 24),

            // 开源信息
            Text(
              '开源信息',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '本项目为非官方开源项目，源代码可在GitHub上获取。'
              '欢迎贡献代码、提出问题或建议。',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.link, size: 20),
                const SizedBox(width: 8),
                const Text('GitHub: '),
                Expanded(
                  child: Text(
                    'https://github.com/your-username/MaiMNP',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 版权信息
            Text(
              '版权信息',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '© 2023 MaiMaiNotePad Team. All rights reserved.\n'
              'MaiBot相关版权归其所有者所有。\n'
              '本应用仅供学习和交流使用。',
            ),

            const SizedBox(height: 24),

            // 免责声明
            Text(
              '免责声明',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '本应用仅为内容分享平台，不对用户上传的内容负责。'
              '用户上传的内容仅代表用户个人观点，与本应用立场无关。'
              '请遵守相关法律法规，不要上传违法违规内容。',
            ),

            const SizedBox(height: 32),

            // 联系我们
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: 实现联系我们功能
                },
                icon: const Icon(Icons.email),
                label: const Text('联系我们'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(value),
            ),
          ),
        ],
      ),
    );
  }
}
