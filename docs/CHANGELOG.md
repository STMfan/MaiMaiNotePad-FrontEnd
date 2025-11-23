# 修改日志 (CHANGELOG)

## 2025-11-23 - API接口优化和性能提升

### 更新内容

本次更新主要针对API调用优化和性能提升，适配后端新增接口和功能增强：

#### 1. Star功能性能优化

**问题描述：**
- 之前检查Star状态需要获取所有Star记录，然后在前端遍历查找，效率低下
- "我的收藏"页面需要多次API调用（1次获取Star列表 + N次获取详情）

**优化方案：**
- 使用新的Star状态检查接口，单次API调用即可获取状态
- 使用增强的用户Star记录接口，支持一次性获取完整详情

**修改位置：**
- 文件：`lib/services/api_service.dart`
- 方法：
  - `isKnowledgeStarred()`: 第454-478行
  - `isPersonaStarred()`: 第480-504行
  - `getUserStars()`: 第316-380行

**修改前：**
```dart
// 需要获取所有Star记录，然后遍历查找
Future<bool> isKnowledgeStarred(String id) async {
  final stars = await getUserStars(token);
  return stars.any((star) => star['target_id'] == id && star['type'] == 'knowledge');
}
```

**修改后：**
```dart
// 使用专门的Star状态检查接口
Future<bool> isKnowledgeStarred(String knowledgeId, String? token) async {
  if (token == null) return false;
  final response = await get('/api/knowledge/$knowledgeId/starred');
  final responseData = response.data is Map && response.data.containsKey('data')
      ? response.data['data']
      : response.data;
  return responseData['starred'] as bool? ?? false;
}
```

**性能提升：**
- Star状态检查：从获取所有Star记录（可能数百条）→ 单次API调用
- "我的收藏"页面：从 1+N 次请求 → 1 次请求（使用 `includeDetails=true`）

**使用位置：**
- `lib/screens/knowledge/detail_screen.dart`: 第55行
- `lib/screens/persona/detail_screen.dart`: 第64行
- `lib/screens/user/stars_screen.dart`: 第49行

---

#### 2. 用户Star记录接口增强支持

**接口**：`GET /api/user/stars`

**新增参数支持**：
- `includeDetails`: 是否包含完整详情（可选，默认false）

**功能说明：**
- 当 `includeDetails=true` 时，后端返回Star记录的同时包含知识库/人设卡的完整信息
- 前端无需再为每个Star记录单独调用详情接口

**修改位置：**
- 文件：`lib/services/api_service.dart`
- 方法：`getUserStars()`: 第316-380行

**修改前：**
```dart
// 只能获取Star记录列表，需要单独获取每个详情
Future<Map<String, dynamic>> getUserStars(String token) async {
  final response = await get('/api/user/stars');
  // 需要为每个Star记录单独调用详情接口
  for (var id in knowledgeIds) {
    final kb = await getKnowledgeDetail(id, token);
    knowledgeItems.add(kb);
  }
}
```

**修改后：**
```dart
// 支持一次性获取完整详情
Future<Map<String, dynamic>> getUserStars(String token, {bool includeDetails = false}) async {
  final response = await get('/api/user/stars?include_details=$includeDetails');
  // 如果包含详情，直接解析；否则保持向后兼容
  if (includeDetails) {
    final kb = Knowledge.fromJson(star);
    knowledgeItems.add(kb);
  }
}
```

**使用位置：**
- `lib/screens/user/stars_screen.dart`: 第49行（使用 `includeDetails: true`）

---

#### 3. 公开列表分页支持

**接口**：
- `GET /api/knowledge/public`
- `GET /api/persona/public`

**新增参数支持**：
- `page`: 页码（默认1）
- `page_size`: 每页数量（默认20）
- `name`: 按名称搜索（可选）
- `uploader_id`: 按上传者ID筛选（可选）
- `sort_by`: 排序字段（`created_at`、`updated_at`、`star_count`，默认`created_at`）
- `sort_order`: 排序顺序（`asc`、`desc`，默认`desc`）

**功能说明：**
- 后端接口现在支持分页、搜索、筛选和排序
- 前端已实现分页响应模型 `PaginatedResponse<T>`

**修改位置：**
- 文件：`lib/services/api_service.dart`
- 方法：
  - `getPublicKnowledge()`: 第544-573行
  - `getPublicPersonas()`: 第576-605行

**实现代码：**
```dart
Future<PaginatedResponse<Knowledge>> getPublicKnowledge({
  int page = 1,
  int pageSize = 20,
  String? name,
  String? uploaderId,
  String sortBy = 'created_at',
  String sortOrder = 'desc',
}) async {
  final response = await get(
    '/api/knowledge/public',
    queryParameters: {
      'page': page,
      'page_size': pageSize,
      if (name != null) 'name': name,
      if (uploaderId != null) 'uploader_id': uploaderId,
      'sort_by': sortBy,
      'sort_order': sortOrder,
    },
  );
  return PaginatedResponse.fromJson(
    response.data,
    (json) => Knowledge.fromJson(json),
  );
}
```

**使用位置：**
- `lib/screens/knowledge/knowledge_screen.dart`: 第83行
- `lib/screens/persona/persona_screen.dart`: 第85行

**响应格式：**
```json
{
  "items": [...],
  "total": 100,
  "page": 1,
  "page_size": 20
}
```

---

#### 4. 待审核列表分页支持

**接口**：
- `GET /api/review/knowledge/pending`
- `GET /api/review/persona/pending`

**新增参数支持**：
- 与公开列表相同的分页、搜索、筛选和排序参数

**修改位置：**
- 文件：`lib/services/api_service.dart`
- 方法：
  - `getPendingKnowledge()`: 第789-823行
  - `getPendingPersonas()`: 第826-855行

**使用位置：**
- `lib/screens/admin/review_tab_content.dart`: 审核管理页面

---

### 影响范围

**新增/修改的API方法**：
- `isKnowledgeStarred()` - 使用新接口 `/api/knowledge/{id}/starred`
- `isPersonaStarred()` - 使用新接口 `/api/persona/{id}/starred`
- `getUserStars()` - 支持 `includeDetails` 参数
- `getPublicKnowledge()` - 支持分页、搜索、筛选、排序参数
- `getPublicPersonas()` - 支持分页、搜索、筛选、排序参数
- `getPendingKnowledge()` - 支持分页、搜索、筛选、排序参数
- `getPendingPersonas()` - 支持分页、搜索、筛选、排序参数

**新增数据模型**：
- `PaginatedResponse<T>` - 分页响应模型（`lib/models/paginated_response.dart`）

**修改的页面**：
- `lib/screens/knowledge/detail_screen.dart` - 使用新的Star状态检查接口
- `lib/screens/persona/detail_screen.dart` - 使用新的Star状态检查接口
- `lib/screens/user/stars_screen.dart` - 使用增强的用户Star记录接口
- `lib/screens/knowledge/knowledge_screen.dart` - 使用分页接口
- `lib/screens/persona/persona_screen.dart` - 使用分页接口

### 性能提升总结

1. **Star状态检查**：
   - 之前：获取所有Star记录（可能数百条），然后遍历查找
   - 现在：单次API调用 `/api/knowledge/{id}/starred` 或 `/api/persona/{id}/starred`
   - 提升：从 O(n) 次网络请求 → O(1) 次网络请求

2. **"我的收藏"页面**：
   - 之前：1次获取Star列表 + N次获取详情（N为Star数量）
   - 现在：1次获取Star列表（包含详情）
   - 提升：从 1+N 次请求 → 1 次请求

3. **公开列表加载**：
   - 之前：一次性获取所有数据（可能数千条）
   - 现在：支持分页加载，按需获取
   - 提升：减少初始加载时间，提升用户体验

### 相关文件

- `lib/services/api_service.dart` - API服务实现
- `lib/models/paginated_response.dart` - 分页响应模型
- `lib/screens/knowledge/detail_screen.dart` - 知识库详情页面
- `lib/screens/persona/detail_screen.dart` - 人设卡详情页面
- `lib/screens/user/stars_screen.dart` - 用户Star列表页面
- `lib/screens/knowledge/knowledge_screen.dart` - 知识库列表页面
- `lib/screens/persona/persona_screen.dart` - 人设卡列表页面

---

## 2025-11-22 - 核心服务层优化和功能增强

### 更新内容

#### 1. API服务异步初始化优化

**问题描述：**
- Dio初始化在构造函数中同步执行，可能导致SharedPreferences读取延迟
- Token获取可能不准确

**优化方案：**
- 将Dio初始化改为异步，使用Completer确保初始化完成
- Token动态获取，每次请求时重新读取SharedPreferences

**修改位置：**
- 文件：`lib/services/api_service.dart`
- 方法：
  - `_initDio()`: 异步初始化
  - `_getToken()`: 动态获取Token

**关键代码：**
```dart
Future<void> _initDio() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  // ... 初始化逻辑
}

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}
```

---

#### 2. 数据模型扩展

**Knowledge模型新增字段**：
- `fileNames: List<String>` - 文件名称列表
- `content: String?` - 知识库内容
- `tags: List<String>` - 标签列表
- `downloads: int` - 下载次数
- `downloadUrl: String?` - 下载URL
- `previewUrl: String?` - 预览图URL
- `version: String?` - 版本号
- `size: int?` - 文件总大小

**Persona模型新增字段**：
- `content: String?` - 人设卡内容
- `author: String?` - 作者名称
- `authorId: String?` - 作者ID
- `tags: List<String>` - 标签列表
- `stars: int` - Star数量
- `fileNames: List<String>` - 文件名称列表
- `downloadUrl: String?` - 下载URL
- `previewUrl: String?` - 预览图URL
- `version: String?` - 版本号
- `size: int?` - 文件总大小

**修改位置：**
- `lib/models/knowledge.dart`
- `lib/models/persona.dart`

---

#### 3. 管理员功能增强

**上传管理页面重构**：
- 优化数据加载逻辑
- 改进错误处理
- 增强用户体验

**概览页面优化**：
- 添加统计数据展示
- 优化布局和样式

**审核页面改进**：
- 优化审核流程
- 改进UI交互

**修改位置：**
- `lib/screens/admin/upload_management_tab_content.dart`
- `lib/screens/admin/overview_tab_content.dart`
- `lib/screens/admin/review_tab_content.dart`

---

#### 4. 消息系统优化

**API调用优化**：
- 添加 `getUserMessages()` 方法，支持分页参数
- 添加 `markMessageAsRead()` 方法
- 优化错误处理逻辑

**功能改进**：
- 改进消息列表显示
- 优化已读/未读状态管理

**修改位置：**
- `lib/services/api_service.dart`
- `lib/screens/messages/message_screen.dart`

---

### 相关文件

- `lib/services/api_service.dart` - API服务实现
- `lib/models/knowledge.dart` - 知识库模型
- `lib/models/persona.dart` - 人设卡模型
- `lib/screens/admin/` - 管理员相关页面
- `lib/screens/messages/` - 消息相关页面


