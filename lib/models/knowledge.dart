import 'package:json_annotation/json_annotation.dart';

part 'knowledge.g.dart';

@JsonSerializable()
class Knowledge {
  final String id;
  final String name;
  final String description;
  final String uploaderId;
  final String? copyrightOwner;
  final int starCount;
  final bool isPublic;
  final List<String> fileNames;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 详情页面需要的额外字段
  final String? content;
  final List<String> tags;
  final int downloads;
  final String? downloadUrl;
  final String? previewUrl;
  final String? version;
  final int? size;

  // 添加便利属性
  String get title => name;
  String get authorName => uploaderId; // 实际应用中应该从用户信息获取
  String get author => uploaderId;
  String get authorId => uploaderId;
  int get stars => starCount;
  String get uploaderName => uploaderId; // 兼容旧代码
  String get copyright => copyrightOwner ?? ''; // 兼容旧代码

  Knowledge({
    required this.id,
    required this.name,
    required this.description,
    required this.uploaderId,
    this.copyrightOwner,
    required this.starCount,
    required this.isPublic,
    required this.fileNames,
    required this.createdAt,
    this.updatedAt,
    this.content,
    this.tags = const [],
    this.downloads = 0,
    this.downloadUrl,
    this.previewUrl,
    this.version,
    this.size,
  });

  factory Knowledge.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeFromJson(json);
  Map<String, dynamic> toJson() => _$KnowledgeToJson(this);
}

@JsonSerializable()
class KnowledgeUploadRequest {
  final String name;
  final String description;
  final String? copyrightOwner;
  final List<String> files;
  final Map<String, dynamic> metadata;

  KnowledgeUploadRequest({
    required this.name,
    required this.description,
    this.copyrightOwner,
    required this.files,
    required this.metadata,
  });

  factory KnowledgeUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeUploadRequestFromJson(json);
  Map<String, dynamic> toJson() => _$KnowledgeUploadRequestToJson(this);
}
