# API 文档

## 概述

本文档描述了 MaiMNP 后端 API 的接口规范。API 基于 FastAPI 框架构建，提供用户管理、知识库管理、人设卡管理、审核管理、消息管理、邮件服务等功能。

## 基础信息

- **基础URL**: `http://localhost:8000`
- **API版本**: v1
- **认证方式**: Bearer Token (JWT)
- **Content-Type**: 支持 `application/json` 和 `application/x-www-form-urlencoded`

## 认证相关接口

### 用户登录
获取访问令牌，支持 JSON 和表单数据格式。

```http
POST /api/token
Content-Type: application/json

{
  "username": "string",
  "password": "string"
}
```

或

```http
POST /api/token
Content-Type: application/x-www-form-urlencoded

username=string&password=string
```

**参数说明**:
- `username` (必填): 用户名
- `password` (必填): 密码

**响应示例**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer"
}
```

**错误响应**:
- `400`: 用户名或密码为空
- `401`: 用户名或密码错误

### 发送验证码
向指定邮箱发送验证码，用于注册验证。

```http
POST /api/send_verification_code
Content-Type: application/x-www-form-urlencoded

email=user@example.com
```

**参数说明**:
- `email` (必填): 接收验证码的邮箱地址

**响应示例**:
```json
{
  "message": "验证码已发送"
}
```

**错误响应**:
- `400`: 邮箱格式无效
- `429`: 请求发送验证码过于频繁
- `500`: 发送验证码失败

### 用户注册
使用邮箱验证码注册新用户。

```http
POST /api/user/register
Content-Type: application/x-www-form-urlencoded

username=newuser&password=pass123&email=user@example.com&verification_code=123456
```

**参数说明**:
- `username` (必填): 用户名，需唯一
- `password` (必填): 密码
- `email` (必填): 邮箱地址
- `verification_code` (必填): 邮箱验证码

**响应示例**:
```json
{
  "success": true,
  "message": "注册成功"
}
```

**错误响应**:
- `400`: 有未填写的字段、验证码错误或已失效、用户名/邮箱已存在
- `500`: 注册失败，系统错误

### 获取当前用户信息
获取当前登录用户的基本信息。

```http
GET /api/users/me
Authorization: Bearer {token}
```

**响应示例**:
```json
{
  "id": "user123",
  "username": "testuser",
  "email": "user@example.com",
  "role": "user"
}
```

**错误响应**:
- `401`: 未授权访问
- `500`: 获取用户信息失败

### 修改密码
修改当前用户的密码。

```http
PUT /api/users/me/password
Authorization: Bearer {token}
Content-Type: application/json

{
  "current_password": "oldpass123",
  "new_password": "newpass123",
  "confirm_password": "newpass123"
}
```

**参数说明**:
- `current_password` (必填): 当前密码
- `new_password` (必填): 新密码
- `confirm_password` (必填): 确认新密码

**响应示例**:
```json
{
  "message": "密码修改成功"
}
```

**错误响应**:
- `400`: 当前密码错误、新密码格式不正确、两次输入的新密码不一致
- `401`: 未授权访问
- `500`: 修改密码失败

### 上传头像
上传当前用户的头像。

```http
POST /api/users/me/avatar
Authorization: Bearer {token}
Content-Type: multipart/form-data

avatar: [文件]
```

**参数说明**:
- `avatar` (必填): 头像文件

**响应示例**:
```json
{
  "message": "头像上传成功",
  "avatar_url": "/api/users/user123/avatar"
}
```

**错误响应**:
- `400`: 文件格式不支持、文件大小超出限制
- `401`: 未授权访问
- `500`: 上传头像失败

### 删除头像
删除当前用户的头像。

```http
DELETE /api/users/me/avatar
Authorization: Bearer {token}
```

**响应示例**:
```json
{
  "message": "头像删除成功"
}
```

**错误响应**:
- `401`: 未授权访问
- `404`: 头像不存在
- `500`: 删除头像失败

## 知识库管理接口

### 上传知识库
上传知识库文件，支持多个文件同时上传。

```http
POST /api/knowledge/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

files: [文件1, 文件2, ...]
name: 知识库名称
description: 知识库描述
copyright_owner: 版权所有者（可选）
```

**参数说明**:
- `files` (必填): 知识库文件列表，至少需要上传一个文件
- `name` (必填): 知识库名称
- `description` (必填): 知识库描述
- `copyright_owner` (可选): 版权所有者信息

**响应示例**:
```json
{
  "id": "kb123",
  "name": "我的知识库",
  "description": "这是一个测试知识库",
  "uploader_id": "user123",
  "copyright_owner": "版权所有者",
  "star_count": 0,
  "is_public": false,
  "is_pending": true,
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T00:00:00"
}
```

**错误响应**:
- `400`: 名称和描述不能为空、至少需要上传一个文件
- `401`: 未授权访问
- `500`: 上传知识库失败

### 获取公开知识库列表
获取所有已审核通过的公开知识库列表，支持分页、搜索、筛选和排序。

```http
GET /api/knowledge/public?page=1&page_size=20&name=&uploader_id=&sort_by=created_at&sort_order=desc
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `page_size` (可选): 每页数量，范围1-100，默认为20
- `name` (可选): 按名称搜索，支持模糊匹配
- `uploader_id` (可选): 按上传者ID筛选
- `sort_by` (可选): 排序字段，可选值：`created_at`、`updated_at`、`star_count`，默认为 `created_at`
- `sort_order` (可选): 排序顺序，可选值：`asc`、`desc`，默认为 `desc`

**响应示例**:
```json
{
  "items": [
    {
      "id": "kb123",
      "name": "公开知识库",
      "description": "这是一个公开的知识库",
      "uploader_id": "user123",
      "copyright_owner": "版权所有者",
      "star_count": 10,
      "is_public": true,
      "is_pending": false,
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 100,
  "page": 1,
  "page_size": 20
}
```

**错误响应**:
- `400`: 查询参数无效（如page_size超出范围）
- `500`: 获取公开知识库失败

### 获取知识库内容
获取指定知识库的详细内容。

```http
GET /api/knowledge/{kb_id}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID

**响应示例**:
```json
{
  "content": "知识库内容...",
  "metadata": {
    "file_count": 2,
    "total_size": 1024
  }
}
```

**错误响应**:
- `404`: 知识库不存在
- `500`: 获取知识库内容失败

### 获取用户的知识库列表
获取指定用户上传的所有知识库。

```http
GET /api/knowledge/user/{user_id}
Authorization: Bearer {token}
```

**参数说明**:
- `user_id` (路径参数): 用户ID

**响应示例**:
```json
[
  {
    "id": "kb123",
    "name": "我的知识库",
    "description": "用户知识库描述",
    "uploader_id": "user123",
    "copyright_owner": "版权所有者",
    "star_count": 5,
    "is_public": false,
    "is_pending": true,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

**错误响应**:
- `403`: 没有权限查看其他用户的上传记录
- `401`: 未授权访问
- `500`: 获取用户知识库失败

### Star/取消Star知识库
对知识库进行Star或取消Star操作（如果已Star则取消，否则添加Star）。

```http
POST /api/knowledge/{kb_id}/star
Authorization: Bearer {token}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID

**响应示例**:
```json
{
  "message": "Star成功"
}
```

或

```json
{
  "message": "取消Star成功"
}
```

**错误响应**:
- `404`: 知识库不存在
- `409`: 已经Star过了
- `401`: 未授权访问
- `500`: Star知识库失败

### 取消Star知识库（独立接口）
专门用于取消Star知识库。

```http
DELETE /api/knowledge/{kb_id}/star
Authorization: Bearer {token}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID

**响应示例**:
```json
{
  "message": "取消Star成功"
}
```

**错误响应**:
- `404`: 知识库不存在或未找到Star记录
- `401`: 未授权访问
- `500`: 取消Star知识库失败

### 检查知识库Star状态
检查指定知识库是否已被当前用户Star。

```http
GET /api/knowledge/{kb_id}/starred
Authorization: Bearer {token}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID

**响应示例**:
```json
{
  "starred": true
}
```

**错误响应**:
- `401`: 未授权访问
- `404`: 知识库不存在
- `500`: 检查Star状态失败

### 更新知识库信息
修改知识库的基本信息（名称、描述、版权所有者等）。

```http
PUT /api/knowledge/{kb_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "更新后的知识库名称",
  "description": "更新后的描述",
  "copyright_owner": "版权所有者"
}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID
- `name` (可选): 知识库名称
- `description` (可选): 知识库描述
- `copyright_owner` (可选): 版权所有者

**响应示例**:
```json
{
  "id": "kb123",
  "name": "更新后的知识库名称",
  "description": "更新后的描述",
  "uploader_id": "user123",
  "copyright_owner": "版权所有者",
  "star_count": 5,
  "is_public": true,
  "is_pending": false,
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T01:00:00"
}
```

**错误响应**:
- `400`: 没有提供要更新的字段
- `401`: 未授权访问
- `403`: 没有权限修改此知识库（只有上传者和管理员可以修改）
- `404`: 知识库不存在
- `500`: 修改知识库失败

### 删除知识库
删除整个知识库及其所有文件。

```http
DELETE /api/knowledge/{kb_id}
Authorization: Bearer {token}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID

**响应示例**:
```json
{
  "message": "知识库删除成功"
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限删除此知识库（只有上传者和管理员可以删除）
- `404`: 知识库不存在
- `500`: 删除知识库失败

## 人设卡管理接口

### 上传人设卡
上传人设卡文件，支持多个文件同时上传。

```http
POST /api/persona/upload
Authorization: Bearer {token}
Content-Type: multipart/form-data

files: [文件1, 文件2, ...]
name: 人设卡名称
description: 人设卡描述
copyright_owner: 版权所有者（可选）
```

**参数说明**:
- `files` (必填): 人设卡文件列表，至少需要上传一个文件
- `name` (必填): 人设卡名称
- `description` (必填): 人设卡描述
- `copyright_owner` (可选): 版权所有者信息

**响应示例**:
```json
{
  "id": "pc123",
  "name": "我的人设卡",
  "description": "这是一个测试人设卡",
  "uploader_id": "user123",
  "copyright_owner": "版权所有者",
  "star_count": 0,
  "is_public": false,
  "is_pending": true,
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T00:00:00"
}
```

**错误响应**:
- `400`: 名称和描述不能为空、至少需要上传一个文件
- `401`: 未授权访问
- `500`: 上传人设卡失败

### 获取公开人设卡列表
获取所有已审核通过的公开人设卡列表，支持分页、搜索、筛选和排序。

```http
GET /api/persona/public?page=1&page_size=20&name=&uploader_id=&sort_by=created_at&sort_order=desc
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `page_size` (可选): 每页数量，范围1-100，默认为20
- `name` (可选): 按名称搜索，支持模糊匹配
- `uploader_id` (可选): 按上传者ID筛选
- `sort_by` (可选): 排序字段，可选值：`created_at`、`updated_at`、`star_count`，默认为 `created_at`
- `sort_order` (可选): 排序顺序，可选值：`asc`、`desc`，默认为 `desc`

**响应示例**:
```json
{
  "items": [
    {
      "id": "pc123",
      "name": "公开人设卡",
      "description": "这是一个公开的人设卡",
      "uploader_id": "user123",
      "copyright_owner": "版权所有者",
      "star_count": 8,
      "is_public": true,
      "is_pending": false,
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 50,
  "page": 1,
  "page_size": 20
}
```

**错误响应**:
- `400`: 查询参数无效（如page_size超出范围）
- `500`: 获取公开人设卡失败

### 获取人设卡内容
获取指定人设卡的详细内容。

```http
GET /api/persona/{pc_id}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID

**响应示例**:
```json
{
  "content": "人设卡内容...",
  "metadata": {
    "file_count": 1,
    "total_size": 512
  }
}
```

**错误响应**:
- `404`: 人设卡不存在
- `500`: 获取人设卡内容失败

### 获取用户的人设卡列表
获取指定用户上传的所有人设卡。

```http
GET /api/persona/user/{user_id}
Authorization: Bearer {token}
```

**参数说明**:
- `user_id` (路径参数): 用户ID

**响应示例**:
```json
[
  {
    "id": "pc123",
    "name": "我的人设卡",
    "description": "用户人设卡描述",
    "uploader_id": "user123",
    "copyright_owner": "版权所有者",
    "star_count": 3,
    "is_public": false,
    "is_pending": true,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

**错误响应**:
- `403`: 没有权限查看其他用户的上传记录
- `401`: 未授权访问
- `500`: 获取用户人设卡失败

### Star/取消Star人设卡
对人设卡进行Star或取消Star操作（如果已Star则取消，否则添加Star）。

```http
POST /api/persona/{pc_id}/star
Authorization: Bearer {token}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID

**响应示例**:
```json
{
  "message": "Star成功"
}
```

或

```json
{
  "message": "取消Star成功"
}
```

**错误响应**:
- `404`: 人设卡不存在
- `409`: Star失败
- `401`: 未授权访问
- `500`: Star人设卡失败

### 取消Star人设卡（独立接口）
专门用于取消Star人设卡。

```http
DELETE /api/persona/{pc_id}/star
Authorization: Bearer {token}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID

**响应示例**:
```json
{
  "message": "取消Star成功"
}
```

**错误响应**:
- `404`: 人设卡不存在或未找到Star记录
- `401`: 未授权访问
- `500`: 取消Star人设卡失败

### 检查人设卡Star状态
检查指定人设卡是否已被当前用户Star。

```http
GET /api/persona/{pc_id}/starred
Authorization: Bearer {token}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID

**响应示例**:
```json
{
  "starred": true
}
```

**错误响应**:
- `401`: 未授权访问
- `404`: 人设卡不存在
- `500`: 检查Star状态失败

### 更新人设卡信息
修改人设卡的基本信息（名称、描述、版权所有者等）。

```http
PUT /api/persona/{pc_id}
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "更新后的人设卡名称",
  "description": "更新后的描述",
  "copyright_owner": "版权所有者"
}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID
- `name` (可选): 人设卡名称
- `description` (可选): 人设卡描述
- `copyright_owner` (可选): 版权所有者

**响应示例**:
```json
{
  "id": "pc123",
  "name": "更新后的人设卡名称",
  "description": "更新后的描述",
  "uploader_id": "user123",
  "copyright_owner": "版权所有者",
  "star_count": 3,
  "is_public": true,
  "is_pending": false,
  "created_at": "2024-01-01T00:00:00",
  "updated_at": "2024-01-01T01:00:00"
}
```

**错误响应**:
- `400`: 名称和描述不能为空
- `401`: 未授权访问
- `403`: 没有权限修改此人设卡（只有上传者和管理员可以修改）
- `404`: 人设卡不存在
- `500`: 修改人设卡失败

### 删除人设卡
删除整个人设卡及其所有文件。

```http
DELETE /api/persona/{pc_id}
Authorization: Bearer {token}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID

**响应示例**:
```json
{
  "message": "人设卡删除成功"
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限删除此人设卡（只有上传者和管理员可以删除）
- `404`: 人设卡不存在
- `500`: 删除人设卡失败

## 用户Star记录接口

### 获取用户Star的知识库和人设卡
获取当前用户Star的所有公开知识库和人设卡。

```http
GET /api/user/stars?include_details=false
Authorization: Bearer {token}
```

**查询参数说明**:
- `include_details` (可选): 是否包含完整详情，默认为 `false`

**响应示例**（include_details=false）:
```json
[
  {
    "id": "star123",
    "type": "knowledge",
    "target_id": "kb123",
    "name": "我的知识库",
    "description": "知识库描述",
    "star_count": 10,
    "created_at": "2024-01-01T00:00:00"
  },
  {
    "id": "star456",
    "type": "persona",
    "target_id": "pc123",
    "name": "我的人设卡",
    "description": "人设卡描述",
    "star_count": 5,
    "created_at": "2024-01-01T00:00:00"
  }
]
```

**响应示例**（include_details=true）:
返回Star记录的同时包含知识库/人设卡的完整信息（包括文件列表、元数据等）。

**错误响应**:
- `401`: 未授权访问
- `500`: 获取用户Star记录失败

## 审核管理接口

### 获取待审核知识库
获取所有待审核的知识库列表，支持分页、搜索、筛选和排序（需要admin或moderator权限）。

```http
GET /api/review/knowledge/pending?page=1&page_size=20&name=&uploader_id=&sort_by=created_at&sort_order=desc
Authorization: Bearer {token}
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `page_size` (可选): 每页数量，范围1-100，默认为20
- `name` (可选): 按名称搜索，支持模糊匹配
- `uploader_id` (可选): 按上传者ID筛选
- `sort_by` (可选): 排序字段，可选值：`created_at`、`updated_at`、`star_count`，默认为 `created_at`
- `sort_order` (可选): 排序顺序，可选值：`asc`、`desc`，默认为 `desc`

**响应示例**:
```json
{
  "items": [
    {
      "id": "kb123",
      "name": "待审核知识库",
      "description": "待审核的知识库",
      "uploader_id": "user123",
      "copyright_owner": "上传者",
      "star_count": 0,
      "is_public": false,
      "is_pending": true,
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 10,
  "page": 1,
  "page_size": 20
}
```

**错误响应**:
- `400`: 查询参数无效
- `403`: 没有审核权限
- `401`: 未授权访问
- `500`: 获取待审核知识库失败

### 获取待审核人设卡
获取所有待审核的人设卡列表，支持分页、搜索、筛选和排序（需要admin或moderator权限）。

```http
GET /api/review/persona/pending?page=1&page_size=20&name=&uploader_id=&sort_by=created_at&sort_order=desc
Authorization: Bearer {token}
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `page_size` (可选): 每页数量，范围1-100，默认为20
- `name` (可选): 按名称搜索，支持模糊匹配
- `uploader_id` (可选): 按上传者ID筛选
- `sort_by` (可选): 排序字段，可选值：`created_at`、`updated_at`、`star_count`，默认为 `created_at`
- `sort_order` (可选): 排序顺序，可选值：`asc`、`desc`，默认为 `desc`

**响应示例**:
```json
{
  "items": [
    {
      "id": "pc123",
      "name": "待审核人设卡",
      "description": "待审核的人设卡",
      "uploader_id": "user123",
      "copyright_owner": "上传者",
      "star_count": 0,
      "is_public": false,
      "is_pending": true,
      "created_at": "2024-01-01T00:00:00",
      "updated_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 5,
  "page": 1,
  "page_size": 20
}
```

**错误响应**:
- `400`: 查询参数无效
- `403`: 没有审核权限
- `401`: 未授权访问
- `500`: 获取待审核人设卡失败

### 审核通过知识库
审核通过指定的知识库（需要admin或moderator权限）。

```http
POST /api/review/knowledge/{kb_id}/approve
Authorization: Bearer {token}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID

**响应示例**:
```json
{
  "message": "审核通过"
}
```

**错误响应**:
- `403`: 没有审核权限
- `401`: 未授权访问
- `404`: 知识库不存在
- `500`: 审核知识库失败

### 审核拒绝知识库
审核拒绝指定的知识库，并发送拒绝通知（需要admin或moderator权限）。

```http
POST /api/review/knowledge/{kb_id}/reject
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "拒绝原因"
}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID
- `reason` (请求体): 拒绝原因

**响应示例**:
```json
{
  "message": "审核拒绝，已发送通知"
}
```

**错误响应**:
- `403`: 没有审核权限
- `401`: 未授权访问
- `404`: 知识库不存在
- `500`: 审核知识库失败

### 审核通过人设卡
审核通过指定的人设卡（需要admin或moderator权限）。

```http
POST /api/review/persona/{pc_id}/approve
Authorization: Bearer {token}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID

**响应示例**:
```json
{
  "message": "审核通过"
}
```

**错误响应**:
- `403`: 没有审核权限
- `401`: 未授权访问
- `404`: 人设卡不存在
- `500`: 审核人设卡失败

### 审核拒绝人设卡
审核拒绝指定的人设卡，并发送拒绝通知（需要admin或moderator权限）。

```http
POST /api/review/persona/{pc_id}/reject
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "拒绝原因"
}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID
- `reason` (请求体): 拒绝原因

**响应示例**:
```json
{
  "message": "审核拒绝，已发送通知"
}
```

**错误响应**:
- `403`: 没有审核权限
- `401`: 未授权访问
- `404`: 人设卡不存在
- `500`: 审核人设卡失败

## 消息管理接口

### 发送消息
向指定用户发送消息，支持单发、群发和广播。

```http
POST /api/messages/send
Authorization: Bearer {token}
Content-Type: application/json

{
  "title": "消息标题（可选）",
  "content": "你好，这是一条测试消息",
  "recipient_id": "user456",
  "recipient_ids": ["user456", "user789"],
  "message_type": "direct",
  "summary": "消息摘要（可选）",
  "broadcast_scope": "all_users"
}
```

**参数说明**:
- `title` (可选): 消息标题
- `content` (必填): 消息内容
- `recipient_id` (可选): 单个接收者用户ID
- `recipient_ids` (可选): 多个接收者用户ID数组
- `message_type` (可选): 消息类型，可选值：`direct`（私信）、`announcement`（公告），默认为 `direct`
- `summary` (可选): 消息摘要
- `broadcast_scope` (可选): 广播范围，可选值：`all_users`（所有用户）

**响应示例**:
```json
{
  "message_id": "msg123",
  "status": "sent"
}
```

**错误响应**:
- `400`: 消息内容不能为空、接收者ID不能为空
- `404`: 接收者不存在
- `401`: 未授权访问
- `500`: 发送消息失败

### 获取消息列表
获取当前用户的消息列表，可指定与特定用户的对话。

```http
GET /api/messages?other_user_id=user456&limit=50&offset=0
Authorization: Bearer {token}
```

**查询参数说明**:
- `other_user_id` (可选): 指定对话用户的ID，不指定则获取所有消息
- `limit` (可选): 返回消息数量限制，默认50，范围1-100
- `offset` (可选): 偏移量，默认0

**响应示例**:
```json
[
  {
    "id": "msg123",
    "sender_id": "user456",
    "title": "",
    "content": "你好，这是一条测试消息",
    "is_read": false,
    "created_at": "2024-01-01T00:00:00"
  }
]
```

**错误响应**:
- `400`: limit必须在1-100之间、offset不能为负数
- `401`: 未授权访问
- `500`: 获取消息列表失败

### 获取消息详情
获取指定消息的详细信息。

```http
GET /api/messages/{message_id}
Authorization: Bearer {token}
```

**参数说明**:
- `message_id` (路径参数): 消息ID

**响应示例**:
```json
{
  "id": "msg123",
  "sender_id": "user456",
  "recipient_id": "user123",
  "title": "消息标题",
  "content": "消息内容",
  "is_read": false,
  "created_at": "2024-01-01T00:00:00"
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限查看此消息
- `404`: 消息不存在
- `500`: 获取消息详情失败

### 标记消息为已读
将指定消息标记为已读状态。

```http
POST /api/messages/{message_id}/read
Authorization: Bearer {token}
```

**参数说明**:
- `message_id` (路径参数): 消息ID

**响应示例**:
```json
{
  "status": "success",
  "message": "消息已标记为已读"
}
```

**错误响应**:
- `404`: 消息不存在
- `403`: 没有权限标记此消息为已读（非接收者）
- `401`: 未授权访问
- `500`: 标记消息已读失败

### 删除消息
删除指定的消息。

```http
DELETE /api/messages/{message_id}
Authorization: Bearer {token}
```

**参数说明**:
- `message_id` (路径参数): 消息ID

**响应示例**:
```json
{
  "message": "消息删除成功"
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限删除此消息
- `404`: 消息不存在
- `500`: 删除消息失败

### 批量删除消息
批量删除多条消息。

```http
POST /api/messages/batch-delete
Authorization: Bearer {token}
Content-Type: application/json

["msg123", "msg456", "msg789"]
```

**参数说明**:
- 请求体: 消息ID数组

**响应示例**:
```json
{
  "message": "批量删除成功",
  "deleted_count": 3
}
```

**错误响应**:
- `400`: 消息ID列表为空或格式错误
- `401`: 未授权访问
- `500`: 批量删除失败

## 管理员接口

### 获取广播消息历史
获取所有广播消息的历史记录（需要admin或moderator权限）。

```http
GET /api/admin/broadcast-messages?page=1&limit=50
Authorization: Bearer {token}
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `limit` (可选): 每页数量，默认50

**响应示例**:
```json
{
  "items": [
    {
      "id": "msg123",
      "title": "系统公告",
      "content": "这是一条系统公告",
      "sender_id": "admin",
      "created_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 10,
  "page": 1,
  "limit": 50
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限
- `500`: 获取广播消息失败

### 获取用户列表
获取所有用户列表，支持分页和搜索（需要admin权限）。

```http
GET /api/admin/users?page=1&limit=20&search=&role=
Authorization: Bearer {token}
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `limit` (可选): 每页数量，默认20
- `search` (可选): 搜索关键词（用户名或邮箱）
- `role` (可选): 按角色筛选（user/moderator/admin）

**响应示例**:
```json
{
  "items": [
    {
      "id": "user123",
      "username": "testuser",
      "email": "user@example.com",
      "role": "user",
      "created_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 100,
  "page": 1,
  "limit": 20
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限
- `500`: 获取用户列表失败

### 创建新用户
创建新用户（需要admin权限）。

```http
POST /api/admin/users
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "newuser",
  "email": "newuser@example.com",
  "password": "password123",
  "role": "user"
}
```

**参数说明**:
- `username` (必填): 用户名
- `email` (必填): 邮箱地址
- `password` (必填): 密码
- `role` (必填): 用户角色（user/moderator/admin）

**响应示例**:
```json
{
  "id": "user456",
  "username": "newuser",
  "email": "newuser@example.com",
  "role": "user",
  "created_at": "2024-01-01T00:00:00"
}
```

**错误响应**:
- `400`: 用户名或邮箱已存在、参数格式错误
- `401`: 未授权访问
- `403`: 没有权限
- `500`: 创建用户失败

### 更新用户角色
更新指定用户的角色（需要admin权限）。

```http
PUT /api/admin/users/{user_id}/role
Authorization: Bearer {token}
Content-Type: application/json

{
  "role": "moderator"
}
```

**参数说明**:
- `user_id` (路径参数): 用户ID
- `role` (必填): 新角色（user/moderator/admin）

**响应示例**:
```json
{
  "message": "用户角色更新成功",
  "user_id": "user123",
  "new_role": "moderator"
}
```

**错误响应**:
- `400`: 角色值无效
- `401`: 未授权访问
- `403`: 没有权限
- `404`: 用户不存在
- `500`: 更新用户角色失败

### 删除用户
删除指定用户（需要admin权限）。

```http
DELETE /api/admin/users/{user_id}
Authorization: Bearer {token}
```

**参数说明**:
- `user_id` (路径参数): 用户ID

**响应示例**:
```json
{
  "message": "用户删除成功"
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限
- `404`: 用户不存在
- `500`: 删除用户失败

### 获取所有知识库（管理员）
获取所有知识库，包括待审核和已审核的（需要admin权限）。

```http
GET /api/admin/knowledge/all?page=1&limit=20&status=&search=
Authorization: Bearer {token}
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `limit` (可选): 每页数量，默认20
- `status` (可选): 按状态筛选（pending/approved/rejected）
- `search` (可选): 搜索关键词

**响应示例**:
```json
{
  "items": [
    {
      "id": "kb123",
      "name": "知识库",
      "description": "描述",
      "uploader_id": "user123",
      "is_pending": false,
      "is_public": true,
      "created_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 50,
  "page": 1,
  "limit": 20
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限
- `500`: 获取知识库列表失败

### 获取所有人设卡（管理员）
获取所有人设卡，包括待审核和已审核的（需要admin权限）。

```http
GET /api/admin/persona/all?page=1&limit=20&status=&search=
Authorization: Bearer {token}
```

**查询参数说明**:
- `page` (可选): 页码，从1开始，默认为1
- `limit` (可选): 每页数量，默认20
- `status` (可选): 按状态筛选（pending/approved/rejected）
- `search` (可选): 搜索关键词

**响应示例**:
```json
{
  "items": [
    {
      "id": "pc123",
      "name": "人设卡",
      "description": "描述",
      "uploader_id": "user123",
      "is_pending": false,
      "is_public": true,
      "created_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 30,
  "page": 1,
  "limit": 20
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限
- `500`: 获取人设卡列表失败

### 退回知识库
将已审核通过的知识库退回为待审核状态（需要admin权限）。

```http
POST /api/admin/knowledge/{kb_id}/revert
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "退回原因（可选）"
}
```

**参数说明**:
- `kb_id` (路径参数): 知识库ID
- `reason` (可选): 退回原因

**响应示例**:
```json
{
  "message": "知识库已退回为待审核状态"
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限
- `404`: 知识库不存在
- `500`: 退回知识库失败

### 退回人设卡
将已审核通过的人设卡退回为待审核状态（需要admin权限）。

```http
POST /api/admin/persona/{pc_id}/revert
Authorization: Bearer {token}
Content-Type: application/json

{
  "reason": "退回原因（可选）"
}
```

**参数说明**:
- `pc_id` (路径参数): 人设卡ID
- `reason` (可选): 退回原因

**响应示例**:
```json
{
  "message": "人设卡已退回为待审核状态"
}
```

**错误响应**:
- `401`: 未授权访问
- `403`: 没有权限
- `404`: 人设卡不存在
- `500`: 退回人设卡失败

## 邮件服务接口

### 发送邮件
发送邮件到指定邮箱（需要管理员权限）。

```http
POST /api/email/send
Authorization: Bearer {token}
Content-Type: application/json

{
  "receiver": "user@example.com",
  "subject": "测试邮件",
  "content": "这是一封测试邮件"
}
```

**参数说明**:
- `receiver` (必填): 接收者邮箱地址
- `subject` (必填): 邮件主题
- `content` (必填): 邮件内容

**响应示例**:
```json
{
  "message": "邮件发送成功"
}
```

**错误响应**:
- `403`: 没有权限
- `401`: 未授权访问
- `500`: 邮件发送失败

### 获取邮箱配置
获取当前的邮箱服务配置信息（需要管理员权限）。

```http
GET /api/email/config
Authorization: Bearer {token}
```

**响应示例**:
```json
{
  "mail_host": "smtp.example.com",
  "mail_user": "sender@example.com",
  "mail_port": 587,
  "mail_pwd": "******"
}
```

**错误响应**:
- `403`: 没有权限
- `401`: 未授权访问
- `500`: 获取配置失败

### 更新邮箱配置
更新邮箱服务配置（需要管理员权限）。

```http
PUT /api/email/config
Authorization: Bearer {token}
Content-Type: application/json

{
  "mail_host": "smtp.newserver.com",
  "mail_user": "newsender@example.com",
  "mail_port": 587,
  "mail_pwd": "newpassword"
}
```

**参数说明**:
- `mail_host` (必填): SMTP服务器地址
- `mail_user` (必填): 邮箱用户名
- `mail_port` (必填): SMTP端口
- `mail_pwd` (必填): 邮箱密码

**响应示例**:
```json
{
  "message": "邮箱配置更新成功"
}
```

**错误响应**:
- `403`: 没有权限
- `401`: 未授权访问
- `500`: 更新配置失败

## 错误响应格式

所有错误响应都遵循以下格式：

```json
{
  "detail": "错误描述信息"
}
```

## 权限要求说明

### 角色权限
- **user**: 普通用户，可以上传、查看自己的内容
- **moderator**: 审核员，可以审核内容
- **admin**: 管理员，拥有所有权限

### 接口权限要求
- **公开接口**: 不需要认证，如 `/api/knowledge/public`
- **用户认证**: 需要登录，如 `/api/users/me`
- **审核权限**: 需要 moderator 或 admin 角色
- **管理权限**: 需要 admin 角色

## 常见错误码

| 状态码 | 描述 |
|--------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权访问 |
| 403 | 禁止访问（权限不足） |
| 404 | 资源不存在 |
| 409 | 资源冲突（如重复Star） |
| 422 | 请求验证失败 |
| 429 | 请求过于频繁 |
| 500 | 服务器内部错误 |

## 限流说明

API 实施了请求限流，每个 IP 地址每分钟最多可以请求 100 次。

## 版本控制

API 版本通过 URL 路径进行控制，当前版本为 v1。未来版本将保持向后兼容性。

## 开发工具

### 在线文档

启动服务器后，可以通过以下地址访问交互式 API 文档：

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### 测试

项目包含完整的测试套件，位于 `tests` 目录。运行测试：

```bash
pytest tests/
```

## 数据模型

### 用户模型

```json
{
  "id": "string",
  "username": "string",
  "email": "string",
  "role": "user|moderator|admin",
  "created_at": "datetime"
}
```

### 知识库模型

```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "uploader_id": "string",
  "copyright_owner": "string|null",
  "star_count": "integer",
  "is_public": "boolean",
  "is_pending": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### 人设卡模型

```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "uploader_id": "string",
  "copyright_owner": "string|null",
  "star_count": "integer",
  "is_public": "boolean",
  "is_pending": "boolean",
  "created_at": "datetime",
  "updated_at": "datetime"
}
```

### 消息模型

```json
{
  "id": "string",
  "sender_id": "string",
  "recipient_id": "string",
  "title": "string",
  "content": "string",
  "is_read": "boolean",
  "created_at": "datetime"
}
```

### Star 模型

```json
{
  "id": "string",
  "user_id": "string",
  "target_id": "string",
  "target_type": "knowledge|persona",
  "created_at": "datetime"
}
```

### 邮件配置模型

```json
{
  "mail_host": "string",
  "mail_user": "string",
  "mail_port": "integer",
  "mail_pwd": "string"
}
```