import 'package:json_annotation/json_annotation.dart';

part 'persona.g.dart';

@JsonSerializable()
class Persona {
  final String id;
  final String name;
  final String description;
  final String? content;
  final String uploaderId;
  final String? author;
  final String? authorId;
  final List<String> tags;
  final int starCount;
  final int stars;
  final bool isPublic;
  final List<String> fileNames;
  final String? downloadUrl;
  final String? previewUrl;
  final String? version;
  final int? size;
  final int? downloads;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 添加便利属性
  String get title => name;
  String get authorName => author ?? uploaderId; // 优先使用author，否则使用uploaderId
  String get uploaderName => authorName; // 兼容旧代码
  String get copyright => ''; // 兼容旧代码

  Persona({
    required this.id,
    required this.name,
    required this.description,
    this.content,
    required this.uploaderId,
    this.author,
    this.authorId,
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
