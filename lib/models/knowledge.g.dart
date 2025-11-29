// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'knowledge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Knowledge _$KnowledgeFromJson(Map<String, dynamic> json) => Knowledge(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      uploaderId: json['uploader_id'] as String? ?? '',
      copyrightOwner: json['copyright_owner'] as String?,
      starCount: (json['star_count'] as num?)?.toInt() ?? 0,
      isPublic: json['is_public'] as bool? ?? false,
      isPending: json['is_pending'] as bool? ?? false,
      fileNames: (json['file_names'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => KnowledgeFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: Knowledge._dateTimeFromJson(json['created_at']),
      updatedAt: Knowledge._dateTimeFromJsonNullable(json['updated_at']),
      author: json['author'] as String?,
      authorId: json['author_id'] as String?,
      content: json['content'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      downloadUrl: json['download_url'] as String?,
      previewUrl: json['preview_url'] as String?,
      version: json['version'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );

Map<String, dynamic> _$KnowledgeToJson(Knowledge instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'uploader_id': instance.uploaderId,
      'copyright_owner': instance.copyrightOwner,
      'star_count': instance.starCount,
      'is_public': instance.isPublic,
      'is_pending': instance.isPending,
      'file_names': instance.fileNames,
      'files': instance.files.map((e) => e.toJson()).toList(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'author': instance.author,
      'author_id': instance.authorId,
      'content': instance.content,
      'tags': instance.tags,
      'downloads': instance.downloads,
      'download_url': instance.downloadUrl,
      'preview_url': instance.previewUrl,
      'version': instance.version,
      'size': instance.size,
    };

KnowledgeFile _$KnowledgeFileFromJson(Map<String, dynamic> json) =>
    KnowledgeFile(
      fileId: json['file_id'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$KnowledgeFileToJson(KnowledgeFile instance) =>
    <String, dynamic>{
      'file_id': instance.fileId,
      'original_name': instance.originalName,
      'file_size': instance.fileSize,
    };

KnowledgeUploadRequest _$KnowledgeUploadRequestFromJson(
  Map<String, dynamic> json,
) => KnowledgeUploadRequest(
  name: json['name'] as String,
  description: json['description'] as String,
  copyrightOwner: json['copyright_owner'] as String?,
  files: (json['files'] as List<dynamic>).map((e) => e as String).toList(),
  metadata: json['metadata'] as Map<String, dynamic>,
);

Map<String, dynamic> _$KnowledgeUploadRequestToJson(
  KnowledgeUploadRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'copyright_owner': instance.copyrightOwner,
  'files': instance.files,
  'metadata': instance.metadata,
};
