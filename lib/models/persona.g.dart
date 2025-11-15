// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persona.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Persona _$PersonaFromJson(Map<String, dynamic> json) => Persona(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  content: json['content'] as String?,
  uploaderId: json['uploaderId'] as String,
  author: json['author'] as String?,
  authorId: json['authorId'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  starCount: (json['starCount'] as num).toInt(),
  stars: (json['stars'] as num?)?.toInt() ?? 0,
  isPublic: json['isPublic'] as bool,
  fileNames: (json['fileNames'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  downloadUrl: json['downloadUrl'] as String?,
  previewUrl: json['previewUrl'] as String?,
  version: json['version'] as String?,
  size: (json['size'] as num?)?.toInt(),
  downloads: (json['downloads'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PersonaToJson(Persona instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'content': instance.content,
  'uploaderId': instance.uploaderId,
  'author': instance.author,
  'authorId': instance.authorId,
  'tags': instance.tags,
  'starCount': instance.starCount,
  'stars': instance.stars,
  'isPublic': instance.isPublic,
  'fileNames': instance.fileNames,
  'downloadUrl': instance.downloadUrl,
  'previewUrl': instance.previewUrl,
  'version': instance.version,
  'size': instance.size,
  'downloads': instance.downloads,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

PersonaUploadRequest _$PersonaUploadRequestFromJson(
  Map<String, dynamic> json,
) => PersonaUploadRequest(
  name: json['name'] as String,
  description: json['description'] as String,
  files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
  metadata: json['metadata'] as Map<String, dynamic>,
);

Map<String, dynamic> _$PersonaUploadRequestToJson(
  PersonaUploadRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'files': instance.files,
  'metadata': instance.metadata,
};
