import 'package:json_annotation/json_annotation.dart';

part 'knowledge.g.dart';

@JsonSerializable()
class Knowledge {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String description;
  @JsonKey(name: 'uploader_id', defaultValue: '')
  final String uploaderId;
  @JsonKey(name: 'copyright_owner', defaultValue: null)
  final String? copyrightOwner;
  @JsonKey(name: 'star_count', defaultValue: 0)
  final int starCount;
  @JsonKey(name: 'is_public', defaultValue: false)
  final bool isPublic;
  @JsonKey(name: 'is_pending', defaultValue: false)
  final bool isPending;
  @JsonKey(name: 'file_names', defaultValue: [])
  final List<String> fileNames;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? updatedAt;

  // 详情页面需要的额外字段
  final String? content;
  @JsonKey(defaultValue: [])
  final List<String> tags;
  @JsonKey(defaultValue: 0)
  final int downloads;
  @JsonKey(name: 'download_url')
  final String? downloadUrl;
  @JsonKey(name: 'preview_url')
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
    this.isPending = false,
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

  // 辅助方法：处理日期时间解析，支持 null 和字符串格式
  static DateTime _dateTimeFromJson(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is DateTime) {
      return value;
    }
    throw FormatException('Invalid date format: $value');
  }

  static DateTime? _dateTimeFromJsonNullable(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    if (value is DateTime) {
      return value;
    }
    throw FormatException('Invalid date format: $value');
  }
}

@JsonSerializable()
class KnowledgeUploadRequest {
  final String name;
  final String description;
  @JsonKey(name: 'copyright_owner')
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
