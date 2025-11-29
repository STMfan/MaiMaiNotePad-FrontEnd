import 'package:json_annotation/json_annotation.dart';

part 'knowledge.g.dart';

@JsonSerializable()
class KnowledgeFile {
  @JsonKey(name: 'file_id', defaultValue: '')
  final String fileId;
  @JsonKey(name: 'original_name', defaultValue: '')
  final String originalName;
  @JsonKey(name: 'file_size', defaultValue: 0)
  final int fileSize;

  const KnowledgeFile({
    required this.fileId,
    required this.originalName,
    required this.fileSize,
  });

  factory KnowledgeFile.fromJson(Map<String, dynamic> json) =>
      _$KnowledgeFileFromJson(json);
  Map<String, dynamic> toJson() => _$KnowledgeFileToJson(this);
}

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
  @JsonKey(defaultValue: [])
  final List<KnowledgeFile> files;
  @JsonKey(name: 'created_at', fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @JsonKey(name: 'updated_at', fromJson: _dateTimeFromJsonNullable)
  final DateTime? updatedAt;
  final String? author;
  @JsonKey(name: 'author_id')
  final String? authorId;

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
  String get authorName => author ?? copyrightOwner ?? uploaderId;
  String get resolvedAuthorId => authorId ?? uploaderId;
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
    this.files = const [],
    required this.createdAt,
    this.updatedAt,
    this.author,
    this.authorId,
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

  Knowledge copyWith({
    String? id,
    String? name,
    String? description,
    String? uploaderId,
    String? copyrightOwner,
    int? starCount,
    bool? isPublic,
    bool? isPending,
    List<String>? fileNames,
    List<KnowledgeFile>? files,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? author,
    String? authorId,
    String? content,
    List<String>? tags,
    int? downloads,
    String? downloadUrl,
    String? previewUrl,
    String? version,
    int? size,
  }) {
    return Knowledge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      uploaderId: uploaderId ?? this.uploaderId,
      copyrightOwner: copyrightOwner ?? this.copyrightOwner,
      starCount: starCount ?? this.starCount,
      isPublic: isPublic ?? this.isPublic,
      isPending: isPending ?? this.isPending,
      fileNames: fileNames ?? this.fileNames,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      downloads: downloads ?? this.downloads,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      version: version ?? this.version,
      size: size ?? this.size,
    );
  }

  // 辅助方法：处理日期时间解析，支持 null 和字符串格式
  static DateTime _dateTimeFromJson(dynamic value) {
    // ignore: avoid_print
    print('📅 _dateTimeFromJson: 解析日期时间值: $value (类型: ${value?.runtimeType})');
    
    if (value == null) {
      // ignore: avoid_print
      print('📅 _dateTimeFromJson: 值为 null，返回当前时间');
      return DateTime.now();
    }
    if (value is String) {
      try {
        final parsed = DateTime.parse(value);
        // ignore: avoid_print
        print('📅 _dateTimeFromJson: 成功解析字符串 "$value" -> $parsed');
        return parsed;
      } catch (e) {
        // ignore: avoid_print
        print('❌ _dateTimeFromJson: 解析日期字符串失败: "$value"');
        // ignore: avoid_print
        print('错误: $e');
        rethrow;
      }
    }
    if (value is DateTime) {
      // ignore: avoid_print
      print('📅 _dateTimeFromJson: 值已经是 DateTime 类型: $value');
      return value;
    }
    // ignore: avoid_print
    print('❌ _dateTimeFromJson: 无效的日期格式: $value (类型: ${value.runtimeType})');
    throw FormatException('Invalid date format: $value');
  }

  static DateTime? _dateTimeFromJsonNullable(dynamic value) {
    // ignore: avoid_print
    print('📅 _dateTimeFromJsonNullable: 解析日期时间值: $value (类型: ${value?.runtimeType})');
    
    if (value == null) {
      // ignore: avoid_print
      print('📅 _dateTimeFromJsonNullable: 值为 null，返回 null');
      return null;
    }
    if (value is String) {
      try {
        final parsed = DateTime.parse(value);
        // ignore: avoid_print
        print('📅 _dateTimeFromJsonNullable: 成功解析字符串 "$value" -> $parsed');
        return parsed;
      } catch (e) {
        // ignore: avoid_print
        print('❌ _dateTimeFromJsonNullable: 解析日期字符串失败: "$value"');
        // ignore: avoid_print
        print('错误: $e');
        rethrow;
      }
    }
    if (value is DateTime) {
      // ignore: avoid_print
      print('📅 _dateTimeFromJsonNullable: 值已经是 DateTime 类型: $value');
      return value;
    }
    // ignore: avoid_print
    print('❌ _dateTimeFromJsonNullable: 无效的日期格式: $value (类型: ${value.runtimeType})');
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
