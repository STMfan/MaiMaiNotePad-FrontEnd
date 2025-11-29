// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'persona.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Persona _$PersonaFromJson(Map<String, dynamic> json) => Persona(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  content: json['content'] as String?,
  uploaderId: json['uploader_id'] as String? ?? '',
  author: json['author'] as String?,
  authorId: json['author_id'] as String?,
  copyrightOwner: json['copyright_owner'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  starCount: (json['star_count'] as num?)?.toInt() ?? 0,
  stars: (json['stars'] as num?)?.toInt() ?? 0,
  isPublic: json['is_public'] as bool? ?? false,
  fileNames:
      (json['file_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  downloadUrl: json['download_url'] as String?,
  previewUrl: json['preview_url'] as String?,
  version: json['version'] as String?,
  size: (json['size'] as num?)?.toInt(),
  downloads: (json['downloads'] as num?)?.toInt(),
  createdAt: Persona._dateTimeFromJson(json['created_at']),
  updatedAt: Persona._dateTimeFromJsonNullable(json['updated_at']),
);

Map<String, dynamic> _$PersonaToJson(Persona instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'content': instance.content,
  'uploader_id': instance.uploaderId,
  'author': instance.author,
  'author_id': instance.authorId,
  'copyright_owner': instance.copyrightOwner,
  'tags': instance.tags,
  'star_count': instance.starCount,
  'stars': instance.stars,
  'is_public': instance.isPublic,
  'file_names': instance.fileNames,
  'download_url': instance.downloadUrl,
  'preview_url': instance.previewUrl,
  'version': instance.version,
  'size': instance.size,
  'downloads': instance.downloads,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
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
