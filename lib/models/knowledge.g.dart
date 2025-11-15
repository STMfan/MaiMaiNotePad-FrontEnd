// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Knowledge _$KnowledgeFromJson(Map<String, dynamic> json) => Knowledge(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  uploaderId: json['uploaderId'] as String,
  copyrightOwner: json['copyrightOwner'] as String?,
  starCount: (json['starCount'] as num).toInt(),
  isPublic: json['isPublic'] as bool,
  fileNames: (json['fileNames'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  content: json['content'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  downloads: (json['downloads'] as num?)?.toInt() ?? 0,
  downloadUrl: json['downloadUrl'] as String?,
  previewUrl: json['previewUrl'] as String?,
  version: json['version'] as String?,
  size: (json['size'] as num?)?.toInt(),
);

Map<String, dynamic> _$KnowledgeToJson(Knowledge instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'uploaderId': instance.uploaderId,
  'copyrightOwner': instance.copyrightOwner,
  'starCount': instance.starCount,
  'isPublic': instance.isPublic,
  'fileNames': instance.fileNames,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'content': instance.content,
  'tags': instance.tags,
  'downloads': instance.downloads,
  'downloadUrl': instance.downloadUrl,
  'previewUrl': instance.previewUrl,
  'version': instance.version,
  'size': instance.size,
};

KnowledgeUploadRequest _$KnowledgeUploadRequestFromJson(
  Map<String, dynamic> json,
) => KnowledgeUploadRequest(
  name: json['name'] as String,
  description: json['description'] as String,
  copyrightOwner: json['copyrightOwner'] as String?,
  files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
  metadata: json['metadata'] as Map<String, dynamic>,
);

Map<String, dynamic> _$KnowledgeUploadRequestToJson(
  KnowledgeUploadRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'copyrightOwner': instance.copyrightOwner,
  'files': instance.files,
  'metadata': instance.metadata,
};
