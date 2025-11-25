# 麦麦笔记本 (MaiMNP)

麦麦笔记本是一个基于Flutter开发的MaiBot非官方内容分享平台，支持知识库和人设卡的上传、浏览、审核和管理功能。

## 🌟 项目特色

- **跨平台支持**: 支持Android、iOS、Web、Windows、macOS和Linux
- **现代化UI**: 采用Material Design 3设计，支持亮色/暗色主题切换
- **响应式布局**: 适配不同屏幕尺寸，支持桌面端和移动端
- **完整功能**: 用户认证、内容管理、审核系统、消息功能
- **高性能**: 使用Provider状态管理，优化用户体验

## 📱 主要功能

### 用户功能
- ✅ 用户注册/登录（支持邮箱验证）
- ✅ 个人资料管理
- ✅ 主题切换（亮色/暗色模式）
- ✅ 响应式布局适配
- ✅ “我的内容”管理入口（知识库/人设卡分页筛选、删除）

### 内容管理
- ✅ 知识库上传和管理
- ✅ 人设卡上传和管理  
- ✅ 文件选择和批量上传
- ✅ 内容详情查看
- ✅ Star/取消Star功能
- ✅ 文件级下载/删除（管理员/上传者）

### 审核系统
- ✅ 待审核内容列表
- ✅ 审核通过/拒绝操作
- ✅ 权限管理（用户/审核员/管理员）

### 消息系统
- ✅ 用户间消息发送
- ✅ 消息列表查看
- ✅ 已读/未读状态管理

## 🛠 技术栈

### 核心技术
- **Flutter**: 跨平台UI框架
- **Dart**: 编程语言
- **Provider**: 状态管理
- **Dio**: 网络请求库

### 主要依赖
```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.1          # 状态管理
  dio: ^5.4.0               # 网络请求
  shared_preferences: ^2.5.3 # 本地存储
  file_picker: ^6.1.1       # 文件选择
  json_annotation: ^4.8.1   # JSON序列化
  go_router: ^12.1.3        # 路由管理
  animations: ^2.1.0        # 动画效果
```

## 🚀 快速开始

### 环境要求
- Flutter SDK: ^3.9.2
- Dart SDK: ^3.9.2
- Android Studio / Xcode / VS Code

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/STMfan/MaiMaiNotePad-FrontEnd.git
cd MaiMaiNotePad-FrontEnd
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行项目**
```bash
# 运行在Chrome浏览器（生产环境，默认地址）
flutter run -d chrome

# 运行在Chrome浏览器（开发环境，本地地址）
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9278

# 运行在Android设备
flutter run -d android

# 运行在iOS设备（需要Mac和Xcode）
flutter run -d ios
```

### 构建发布

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS（需要Mac和Xcode）
flutter build ios --release

# Web
flutter build web --release
```

### 启动构建好的Web项目

构建完成后，静态文件会生成在 `build/web/` 目录下。可以通过以下方式启动：

**方法1：使用启动脚本（推荐）**
```bash
# Windows
scripts\serve.bat

# Linux/Mac
chmod +x scripts/serve.sh
./scripts/serve.sh
```

**方法2：使用Python HTTP服务器**
```bash
# 进入构建目录
cd build/web

# Python 3
python3 -m http.server 8000

# Python 2 (如果只有Python 2)
python -m SimpleHTTPServer 8000
```

**方法3：使用Node.js http-server**
```bash
# 需要先安装: npm install -g http-server
npx http-server build/web -p 8000
```

**方法4：使用Flutter serve（会重新构建）**
```bash
flutter run -d chrome --release
```

启动后，在浏览器中访问 `http://localhost:8000` 即可查看应用。

**注意**：
- 确保后端服务器已启动并可访问
- 如果构建时指定了API地址，确保该地址可访问
- 生产环境部署时，建议使用专业的Web服务器（如Nginx、Apache等）

## 📋 API文档

项目使用RESTful API与后端通信，完整的API文档请参考后端项目的 [API.md](../MaiMaiNotePad-BackEnd/docs/API.md)。

### 基础配置
- **API地址**: 可配置，默认为 `http://127.0.0.1:9278`（开发环境）
- **认证方式**: Bearer Token (JWT)
- **支持格式**: JSON 和表单数据

### 最新更新（2025-11-25）

**新增/更新接口支持**：
- `GET /api/knowledge/{kb_id}/starred` - 检查知识库Star状态
- `GET /api/persona/{pc_id}/starred` - 检查人设卡Star状态
- `GET /api/user/stars?include_details={bool}&type={all|knowledge|persona}&sort_by&sort_order&page&page_size` - 获取用户Star记录，支持分页、排序、返回详情
- `GET /api/knowledge/public` / `GET /api/persona/public` - 支持分页、名称/标签/上传者筛选、排序
- `GET /api/knowledge/user/{id}` / `GET /api/persona/user/{id}` - 用户内容分页、筛选、排序
- `DELETE /api/knowledge/{knowledgeId}/{fileId}` - 删除单个知识库文件
- `PUT /api/persona/{id}` - 更新人设卡名称/描述/版权方

**体验与安全**：
- 新增 SessionStore 全局 401 回调，自动跳转登录并清理本地 Session
- 登录页错误信息解析优化，展示 requestId/详情以便排障
- 详情页支持文件级下载/删除、收藏计数实时更新
- 收藏页支持分页、排序、就地取消收藏

**性能优化**：
- Star状态检查：从获取所有Star记录 → 单次API调用
- "我的收藏"页面：从 1+N 次请求 → 1 次请求（使用 `includeDetails=true` + 分页）
- 公开列表：支持分页加载，减少初始加载时间

详细更新内容请参考 [CHANGELOG.md](docs/CHANGELOG.md)。

### 环境配置

项目支持通过编译时参数配置不同的API地址：

**开发环境（本地开发）：**
```bash
# 运行
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9278

# 构建
flutter build web --dart-define=API_BASE_URL=http://localhost:9278
```

**生产环境（默认）：**
```bash
# 运行（使用默认生产地址）
flutter run -d chrome

# 构建
flutter build web --release
```

**使用构建脚本（推荐）：**
```bash
# Windows
scripts\run_dev.bat      # 开发环境运行
scripts\build_dev.bat    # 开发环境构建
scripts\build_prod.bat   # 生产环境构建

# Linux/Mac
chmod +x scripts/*.sh
./scripts/run_dev.sh     # 开发环境运行
./scripts/build_dev.sh   # 开发环境构建
./scripts/build_prod.sh  # 生产环境构建
```

**注意**：管理员用户可以在应用内通过"服务器设置"功能动态修改API地址，无需重新编译。

### 主要接口
- 🔐 用户认证（登录/注册/验证）
- 📚 知识库管理（上传/浏览/Star/分页）
- 👤 人设卡管理（上传/浏览/Star/分页）
- ⭐ Star功能（状态检查、收藏列表）
- ✅ 审核管理（待审核/通过/拒绝/分页）
- 💬 消息管理（发送/接收/已读/分页）
- 📧 邮件服务（配置/发送）

## 🎨 项目结构

```
lib/
├── constants/          # 应用常量
├── models/            # 数据模型
├── providers/         # 状态管理
├── screens/           # 页面组件
├── services/          # 业务服务
├── utils/             # 工具类
└── widgets/           # 自定义组件
```

## 🔧 开发指南

### 代码规范
- 遵循Flutter官方代码规范
- 使用`flutter analyze`进行静态代码分析
- 使用`dart format`格式化代码

### 状态管理
- 使用Provider进行状态管理
- 分离业务逻辑和UI组件
- 合理使用Consumer和Selector优化性能

### 网络请求
- 使用Dio进行HTTP请求
- 统一错误处理
- 支持多种响应格式

### 主题配置
- 支持亮色/暗色主题切换
- 使用Material Design 3设计系统
- 可自定义主题色彩

## 📸 界面预览

### 移动端界面
- 登录页面：简洁的登录表单，支持错误提示
- 主页面：底部导航栏，包含知识库、人设卡、消息、个人中心
- 知识库页面：卡片式布局，支持搜索和筛选
- 个人中心：用户信息、Star列表、设置选项

### 桌面端界面
- 左侧边栏导航
- 响应式布局适配
- 更大的内容展示区域
- 优化的交互体验

## 🐛 常见问题

### Q: 登录失败怎么办？
A: 检查后端服务是否正常运行，确认API地址配置正确，查看详细的错误信息。

### Q: 文件上传失败？
A: 确认文件格式是否符合要求（知识库：txt/json，人设卡：toml），检查网络连接。

### Q: 如何修改API地址？
A: 有两种方式：
1. **编译时配置**：使用 `--dart-define=API_BASE_URL=地址` 参数（推荐用于开发/生产环境切换）
2. **运行时配置**：管理员用户可以在应用的"服务器设置"中动态修改（无需重新编译）

### Q: 如何区分开发和生产环境？
A: 使用构建脚本或编译参数：
- 开发环境：`flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9278`
- 生产环境：`flutter run -d chrome`（使用默认地址）

## 🤝 贡献指南

欢迎提交Issue和Pull Request来改进项目！

### 开发流程
1. Fork项目到个人仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [Flutter](https://flutter.dev/) - 优秀的跨平台框架
- [MaiBot](https://maimai.cn/) - 灵感来源
- 所有贡献者和支持者

## 📞 联系方式

- 项目地址: [https://github.com/STMfan/MaiMaiNotePad-FrontEnd](https://github.com/STMfan/MaiMaiNotePad-FrontEnd)
- 问题反馈: [提交Issue](https://github.com/STMfan/MaiMaiNotePad-FrontEnd/issues)

---

⭐ 如果这个项目对你有帮助，请给个Star支持一下！

