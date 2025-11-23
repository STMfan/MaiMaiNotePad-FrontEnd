# API地址配置修改方案

## 问题描述
当前项目中硬编码了后端API地址 `http://localhost:9278`，需要改为可配置的方式，支持生产环境地址 `http://hk-2.lcf.im:10103`。

## 方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **方案一：直接修改** | 简单直接，无需配置 | 不够灵活，切换环境需改代码 | 单一生产环境 |
| **方案二：编译时配置** | 无需依赖，支持多环境 | 需要修改构建命令 | 需要区分开发/生产环境 |
| **方案三：环境变量包** | 最灵活，运行时读取 | 需要添加依赖 | 需要频繁切换环境 |

---

## 方案一：直接修改默认值（最简单）

### 修改内容

**文件：`lib/constants/app_constants.dart`**

```dart
// 修改前
static const String apiBaseUrl = 'http://localhost:9278';

// 修改后
static const String apiBaseUrl = 'http://hk-2.lcf.im:10103';
```

**文件：`lib/screens/user/profile_tab_content.dart`**

```dart
// 修改前（第125行）
hintText: '例如: http://localhost:8000',

// 修改后
hintText: '例如: http://hk-2.lcf.im:10103',
```

### 优点
- ✅ 实现简单，只需修改2处
- ✅ 无需额外配置
- ✅ 立即生效

### 缺点
- ❌ 不够灵活，切换环境需要修改代码
- ❌ 开发和生产环境使用同一地址

---

## 方案二：使用编译时配置（推荐）⭐

### 实现步骤

#### 1. 修改 `lib/constants/app_constants.dart`

```dart
class AppConstants {
  // 应用信息
  static const String appName = '麦麦笔记本';
  static const String appShortName = 'MaiMNP';
  static const String appVersion = '1.0.0';

  // API配置 - 使用编译时定义，默认值为生产环境
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://hk-2.lcf.im:10103',
  );
  static const String apiBaseUrlKey = 'api_base_url';

  // ... 其他常量保持不变
}
```

#### 2. 修改构建命令

**开发环境（本地）：**
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9278
```

**生产环境（默认）：**
```bash
flutter run -d chrome
# 或
flutter build web --release
```

**Android构建：**
```bash
# 开发环境
flutter build apk --debug --dart-define=API_BASE_URL=http://localhost:9278

# 生产环境
flutter build apk --release
```

**Web构建：**
```bash
# 开发环境
flutter build web --dart-define=API_BASE_URL=http://localhost:9278

# 生产环境
flutter build web --release
```

#### 3. 可选：创建构建脚本

**`scripts/build_dev.sh` (Linux/Mac)**
```bash
#!/bin/bash
flutter build web --dart-define=API_BASE_URL=http://localhost:9278
```

**`scripts/build_prod.sh` (Linux/Mac)**
```bash
#!/bin/bash
flutter build web --release
```

**`scripts/build_dev.bat` (Windows)**
```batch
@echo off
flutter build web --dart-define=API_BASE_URL=http://localhost:9278
```

**`scripts/build_prod.bat` (Windows)**
```batch
@echo off
flutter build web --release
```

### 优点
- ✅ 无需额外依赖
- ✅ 编译时确定，性能好
- ✅ 支持多环境配置
- ✅ 代码中无硬编码地址

### 缺点
- ❌ 需要修改构建命令
- ❌ 不同环境需要不同的构建命令

---

## 方案三：使用环境变量包（最灵活）

### 实现步骤

#### 1. 添加依赖

**修改 `pubspec.yaml`：**
```yaml
dependencies:
  # ... 现有依赖
  flutter_dotenv: ^5.1.0  # 添加这行
```

然后运行：
```bash
flutter pub get
```

#### 2. 创建环境配置文件

**创建 `.env` 文件（根目录）：**
```env
API_BASE_URL=http://hk-2.lcf.im:10103
```

**创建 `.env.dev` 文件（开发环境）：**
```env
API_BASE_URL=http://localhost:9278
```

**创建 `.env.example` 文件（示例）：**
```env
API_BASE_URL=http://hk-2.lcf.im:10103
```

#### 3. 修改 `lib/constants/app_constants.dart`

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // 应用信息
  static const String appName = '麦麦笔记本';
  static const String appShortName = 'MaiMNP';
  static const String appVersion = '1.0.0';

  // API配置 - 从环境变量读取，如果未加载则使用默认值
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://hk-2.lcf.im:10103';
  static const String apiBaseUrlKey = 'api_base_url';

  // ... 其他常量保持不变
}
```

#### 4. 修改 `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';  // 添加这行
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
// ... 其他导入

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 加载环境变量（根据构建模式选择不同的文件）
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // 如果加载失败，使用默认值
    print('Warning: Failed to load .env file: $e');
  }
  
  runApp(const MyApp());
}
```

#### 5. 更新 `.gitignore`

确保 `.gitignore` 包含：
```
.env
.env.local
.env.*.local
```

但保留 `.env.example` 用于文档。

#### 6. 修改构建配置（可选）

如果需要根据构建模式加载不同的环境文件，可以在 `main.dart` 中：

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 根据编译模式选择环境文件
  const bool isProduction = bool.fromEnvironment('dart.vm.product');
  final envFile = isProduction ? '.env' : '.env.dev';
  
  try {
    await dotenv.load(fileName: envFile);
  } catch (e) {
    print('Warning: Failed to load $envFile: $e');
  }
  
  runApp(const MyApp());
}
```

### 优点
- ✅ 最灵活，运行时读取
- ✅ 配置集中管理
- ✅ 支持多环境配置文件
- ✅ 无需修改构建命令

### 缺点
- ❌ 需要添加依赖包
- ❌ 需要管理多个配置文件
- ❌ 运行时读取，性能略低于编译时

---

## 推荐方案

**建议使用方案二（编译时配置）**，原因：
1. ✅ 无需额外依赖，保持项目轻量
2. ✅ 编译时确定，性能更好
3. ✅ 代码中无硬编码，更专业
4. ✅ 支持多环境，灵活性足够

---

## 实施建议

### 立即修改（必须）
1. 修改 `app_constants.dart` 中的默认值为生产环境地址
2. 修改 `profile_tab_content.dart` 中的提示文本

### 后续优化（可选）
1. 实施方案二，使用编译时配置
2. 创建构建脚本，简化构建命令
3. 更新文档，说明如何配置不同环境

---

## 修改检查清单

- [ ] 修改 `lib/constants/app_constants.dart` 中的 `apiBaseUrl`
- [ ] 修改 `lib/screens/user/profile_tab_content.dart` 中的提示文本
- [ ] 测试应用启动时能正确连接到后端
- [ ] 测试用户手动配置服务器地址功能
- [ ] 更新 README.md 中的API地址说明（如适用）
- [ ] 更新构建文档（如果使用方案二或三）

---

## 测试验证

修改后，请验证以下功能：

1. **默认连接**：应用启动后，未手动配置时应该连接到新的默认地址
2. **手动配置**：在用户设置中可以手动修改服务器地址
3. **地址保存**：修改后的地址应该正确保存到 SharedPreferences
4. **地址读取**：重启应用后，保存的地址应该正确加载







