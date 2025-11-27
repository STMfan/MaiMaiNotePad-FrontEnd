# 项目代码规范文档

## 概述

本文档定义了"麦麦笔记本"(MaiMNP) Flutter 项目的代码规范和最佳实践，旨在确保代码质量、一致性和可维护性。

## 🏗️ 项目架构规范

### 目录结构

项目采用标准 Flutter 分层架构，所有源码文件位于 `lib/` 目录下：

```
lib/
├── constants/          # 应用常量定义
│   └── app_constants.dart
├── models/             # 数据模型类
│   ├── knowledge.dart
│   ├── knowledge.g.dart
│   ├── user.dart
│   ├── user.g.dart
│   └── ...
├── providers/          # 状态管理 (Provider 模式)
│   ├── user_provider.dart
│   └── theme_provider.dart
├── screens/            # UI 页面组件
│   ├── home/
│   ├── knowledge/
│   ├── persona/
│   ├── message/
│   ├── user/
│   ├── admin/
│   └── shared/
├── services/           # 业务服务层
│   ├── api_service.dart
│   └── auth_service.dart
├── utils/              # 工具类
│   ├── app_theme.dart
│   ├── app_router.dart
│   ├── app_colors.dart
│   ├── download_helper.dart
│   └── ...
└── widgets/            # 通用 UI 组件
    ├── custom_text_field.dart
    └── pagination_widget.dart
```

### 代码分层原则

- **Model 层**：数据模型，使用 JSON 序列化注解
- **Service 层**：业务逻辑，单例模式管理
- **Provider 层**：状态管理，使用 `ChangeNotifier`
- **UI 层**：页面和组件，遵循 Material Design 3

## 📝 命名规范

### 文件命名

- **Dart 文件**：使用小写下划线分隔 (`snake_case.dart`)
- **生成文件**：主文件配对生成 (`knowledge.dart` + `knowledge.g.dart`)
- **测试文件**：以 `_test.dart` 结尾

### 类命名

- **类名**：PascalCase (`Knowledge`, `UserProvider`)
- **抽象类**：以 `Abstract` 前缀 (`AbstractService`)
- **异常类**：以 `Exception` 后缀 (`ApiException`)

### 方法和变量命名

- **方法和变量**：camelCase (`getUserInfo()`, `userName`)
- **私有成员**：下划线前缀 (`_user`, `_initDio()`)
- **布尔变量**：使用肯定式命名 (`isLoggedIn`, `hasPermission`)

### 常量命名

- **应用常量**：camelCase (`apiBaseUrl`, `defaultPadding`)
- **编译时常量**：`String.fromEnvironment()`
- **枚举值**：UPPER_SNAKE_CASE (`LogLevel.DEBUG`)

### 导入规范

```dart
// 标准库
import 'dart:async';
import 'dart:io';

// 第三方包
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 项目内部
import '../models/user.dart';
import '../services/api_service.dart';
import '../constants/app_constants.dart';
```

## 🎨 代码风格规范

### 格式化规则

```yaml
# analysis_options.yaml
linter:
  rules:
    prefer_single_quotes: true      # 偏好单引号
    library_private_types_in_public_api: false
    use_build_context_synchronously: false
    avoid_print: false
```

### 代码注释

```dart
/// 这是一个示例类
/// 
/// 使用说明：
/// ```dart
/// final example = ExampleClass();
/// example.doSomething();
/// ```
class ExampleClass {
  // 单行注释使用 // 
  final String _privateField;
  
  /* 多行注释
     可以用于临时注释大量代码 */
  
  /// 构造函数文档
  ExampleClass(this._privateField);
  
  /// 方法文档，说明参数和返回值
  /// 
  /// [param1] 参数1的说明
  /// [param2] 参数2的说明
  /// 
  /// 返回值说明
  Future<String> doSomething(String param1, {required String param2}) {
    // 实现代码
    return Future.value('result');
  }
}
```

### 代码结构

```dart
// 1. 导入语句
import 'package:flutter/material.dart';

// 2. 模型类
@JsonSerializable()
class User {
  final String id;
  final String name;
  
  const User({
    required this.id,
    required this.name,
  });
  
  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);
      
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// 3. Provider 类
class UserProvider with ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}

// 4. 服务类
class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() => _instance;
  
  ApiService._internal();
  
  Future<User?> getUser(String id) async {
    // 实现代码
    return null;
  }
}

// 5. UI 组件
class UserWidget extends StatelessWidget {
  const UserWidget({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Text(userProvider.user?.name ?? '');
      },
    );
  }
}
```

## 🛠️ 技术选型规范

### 核心依赖

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # UI 组件
  cupertino_icons: ^1.0.8
  
  # 状态管理
  provider: ^6.1.1
  
  # 网络请求
  http: ^1.1.0
  dio: ^5.4.0
  
  # 本地存储
  shared_preferences: ^2.5.3
  
  # 文件操作
  file_picker: ^6.1.1
  
  # JSON 序列化
  json_annotation: ^4.8.1
  
  # 路由管理
  go_router: ^12.1.3
  
  # UI 增强
  flutter_staggered_grid_view: ^0.7.0
  cached_network_image: ^3.3.0
  flutter_markdown: ^0.6.18
```

### 开发依赖

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  
  # 代码生成
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

## 🎯 设计模式

### 单例模式

```dart
class ApiService {
  Dio? _dio;
  Completer<void>? _initCompleter;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _initDio();
  }
}
```

### 工厂模式

```dart
@JsonSerializable()
class Knowledge {
  factory Knowledge.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeFromJson(json);
      
  Map<String, dynamic> toJson() => _$KnowledgeToJson(this);
}
```

### Provider 模式

```dart
class UserProvider with ChangeNotifier {
  User? _user;
  
  User? get user => _user;
  
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }
}
```

### 策略模式

```dart
// 不同平台的文件下载策略
abstract class DownloadStrategy {
  Future<void> download(String url, String fileName);
}

class WebDownloadStrategy implements DownloadStrategy {
  // Web 平台实现
}

class MobileDownloadStrategy implements DownloadStrategy {
  // 移动平台实现
}
```

## 🎨 UI/UX 规范

### 主题系统

```dart
class AppTheme {
  // 颜色常量
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color surfaceColor = Color(0xFFFFFBFA);
  static const Color textPrimary = Color(0xFF212121);
  
  // 主题配置
  static ThemeData getLightTheme(Color primaryColor) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      // ... 其他配置
    );
  }
}
```

### 组件规范

```dart
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
```

### 路由规范

```dart
class AppRouter {
  static const String knowledge = '/knowledge';
  static const String persona = '/persona';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case knowledge:
        return _createRoute(const KnowledgeScreen(), settings);
      default:
        return _createRoute(
          const Scaffold(body: Center(child: Text('页面不存在'))),
          settings,
        );
    }
  }
  
  static Route<T> _createRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
```

## 🔒 安全规范

### 认证授权

```dart
// 自动添加 Bearer Token
_dio!.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await _clearAuthData();
      }
      handler.next(error);
    },
  ),
);
```

### 数据验证

```dart
@JsonSerializable()
class User {
  @JsonKey(defaultValue: '')
  final String id;
  
  @JsonKey(defaultValue: '')
  final String name;
  
  const User({
    required this.id,
    required this.name,
  });
  
  // 输入验证
  bool get isValid => id.isNotEmpty && name.isNotEmpty;
}
```

### 错误处理

```dart
Future<T> safeApiCall<T>(Future<T> Function() apiCall) async {
  try {
    return await apiCall();
  } on DioException catch (e) {
    throw _handleDioError(e);
  } catch (e) {
    throw ApiException('未知错误: $e');
  }
}
```

## 📱 平台适配

### 条件编译

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformSpecificWidget extends StatelessWidget {
  const PlatformSpecificWidget({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const WebWidget();
    } else {
      return const MobileWidget();
    }
  }
}
```

### 平台差异化实现

```dart
// download_helper.dart
abstract class DownloadHelper {
  factory DownloadHelper() {
    if (kIsWeb) {
      return DownloadHelperWeb();
    }
    return DownloadHelperMobile();
  }
  
  Future<void> download(String url, String fileName);
}
```

## ✅ 最佳实践

### 性能优化

```dart
// 使用 const 构造函数
const MyWidget({super.key});

// 合理使用 const
Widget build(BuildContext context) {
  return const Column(
    children: [
      const HeaderWidget(),
      const ContentWidget(),
    ],
  );
}

// 缓存网络图片
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
);

// 避免不必要的重建
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        return Text(userProvider.user?.name ?? '');
      },
    );
  }
}
```

### 内存管理

```dart
class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late final TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}
```

### 异步操作

```dart
// 使用 async/await
Future<void> loadData() async {
  setState(() => _isLoading = true);
  
  try {
    final data = await apiService.getData();
    setState(() => _data = data);
  } catch (e) {
    // 错误处理
    showErrorDialog(e.toString());
  } finally {
    setState(() => _isLoading = false);
  }
}

// 取消异步操作
class _MyWidgetState extends State<MyWidget> {
  final CancelToken _cancelToken = CancelToken();
  
  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }
  
  Future<void> loadData() async {
    try {
      await apiService.getData(cancelToken: _cancelToken);
    } catch (e) {
      if (!CancelToken.isCancelled(e)) {
        // 处理非取消错误
      }
    }
  }
}
```

### 测试规范

```dart
// 单元测试
void main() {
  group('UserProvider', () {
    late UserProvider userProvider;
    
    setUp(() {
      userProvider = UserProvider();
    });
    
    test('should update user correctly', () {
      // Arrange
      final user = User(id: '1', name: 'Test');
      
      // Act
      userProvider.updateUser(user);
      
      // Assert
      expect(userProvider.user, equals(user));
    });
  });
}

// Widget 测试
void main() {
  testWidgets('should display user name', (WidgetTester tester) async {
    // Arrange
    final userProvider = UserProvider();
    userProvider.updateUser(User(id: '1', name: 'John'));
    
    // Act
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: userProvider,
        child: const UserWidget(),
      ),
    );
    
    // Assert
    expect(find.text('John'), findsOneWidget);
  });
}
```

## 📋 代码审查检查清单

### 代码质量
- [ ] 代码符合命名规范
- [ ] 注释完整且有意义
- [ ] 没有硬编码的常量
- [ ] 适当的错误处理
- [ ] 性能考虑（如 const 构造函数）

### 安全
- [ ] 没有敏感信息泄露
- [ ] 输入验证完整
- [ ] 认证授权正确实现

### 架构
- [ ] 遵循分层架构原则
- [ ] 代码复用最大化
- [ ] 依赖关系清晰

### 测试
- [ ] 关键功能有测试覆盖
- [ ] 测试用例完整
- [ ] 测试通过率高

## 🚀 部署和构建

### 构建脚本

```bash
# 开发环境
flutter run -d chrome

# 生产环境构建
flutter build web --release --dart-define=API_BASE_URL=https://api.example.com

# 代码生成
flutter packages pub run build_runner build
flutter packages pub run build_runner watch  # 监听文件变化
```

### 环境配置

```dart
// 使用编译时定义的环境变量
static const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:9278',
);
```

## 📚 相关文档

- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 语言规范](https://dart.dev/guides/language)
- [Material Design 3](https://m3.material.io/)
- [Provider 状态管理](https://pub.dev/packages/provider)
- [Dio HTTP 客户端](https://pub.dev/packages/dio)

---

**版本**: 1.0.0  
**最后更新**: 2024-12-19  
**维护者**: 开发团队