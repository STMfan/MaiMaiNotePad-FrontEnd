import 'package:json_annotation/json_annotation.dart';

part 'persona.g.dart';

@JsonSerializable()
class Persona {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String description;
  final String? content;
  @JsonKey(name: 'uploader_id', defaultValue: '')
  final String uploaderId;
  final String? author;
  @JsonKey(name: 'author_id')
  final String? authorId;
  @JsonKey(name: 'copyright_owner')
  final String? copyrightOwner;
  @JsonKey(defaultValue: [])
  final List<String> tags;
  @JsonKey(name: 'star_count', defaultValue: 0)
  final int starCount;
  @JsonKey(defaultValue: 0)
  final int stars;
  @JsonKey(name: 'is_public', defaultValue: false)
  final bool isPublic;
  @JsonKey(name: 'file_names', defaultValue: [])
  final List<String> fileNames;
  @JsonKey(name: 'download_url')
  final String? downloadUrl;
  @JsonKey(name: 'preview_url')
  final String? previewUrl;
  final String? version;
  final int? size;
  final int? downloads;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? updatedAt;

  // 添加便利属性
  String get title => name;
  String get authorName => author ?? copyrightOwner ?? uploaderId; // 优先使用作者、版权信息，否则上传者
  String get uploaderName => uploaderId; // 兼容旧代码
  String get copyright => ''; // 兼容旧代码

  Persona({
    required this.id,
    required this.name,
    required this.description,
    this.content,
    required this.uploaderId,
    this.author,
    this.authorId,
    this.copyrightOwner,
    this.tags = const [],
    required this.starCount,
    this.stars = 0,
    required this.isPublic,
    required this.fileNames,
    this.downloadUrl,
    this.previewUrl,
    this.version,
    this.size,
    this.downloads,
    required this.createdAt,
    this.updatedAt,
  });

  factory Persona.fromJson(Map<String, dynamic> json) =>
      _$PersonaFromJson(json);
  Map<String, dynamic> toJson() => _$PersonaToJson(this);

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
class PersonaUploadRequest {
  final String name;
  final String description;
  final List<String> files;
  final Map<String, dynamic> metadata;

  PersonaUploadRequest({
    required this.name,
    required this.description,
    required this.files,
    required this.metadata,
  });

  factory PersonaUploadRequest.fromJson(Map<String, dynamic> json) =>
      _$PersonaUploadRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PersonaUploadRequestToJson(this);
}
