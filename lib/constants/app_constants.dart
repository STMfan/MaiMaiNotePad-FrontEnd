class AppConstants {
  // 应用信息
  static const String appName = '麦麦笔记本';
  static const String appShortName = 'MaiMNP';
  static const String appVersion = '1.0.0';

  // API配置 - 使用编译时定义，默认值为生产环境
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:9278',
  );
  static const String apiBaseUrlKey = 'api_base_url';

  // 本地存储键
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userRoleKey = 'user_role';
  static const String userEmailKey = 'user_email';

  // 路由名称
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String knowledgeRoute = '/knowledge';
  static const String personaRoute = '/persona';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  static const String aboutRoute = '/about';
  static const String messagesRoute = '/messages';
  static const String reviewRoute = '/review';
  static const String uploadKnowledgeRoute = '/upload/knowledge';
  static const String uploadPersonaRoute = '/upload/persona';

  // 文件类型限制
  static const List<String> knowledgeFileTypes = ['txt', 'json'];
  static const List<String> personaFileTypes = ['toml'];

  // UI常量
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
}
