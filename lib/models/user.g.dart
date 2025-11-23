// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  name: json['username'] as String,
  email: json['email'] as String?,
  role: json['role'] as String,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  avatarUrl: json['avatar_url'] as String?,
  avatarUpdatedAt: json['avatar_updated_at'] == null
      ? null
      : DateTime.parse(json['avatar_updated_at'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'username': instance.name,
  'email': instance.email,
  'role': instance.role,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'avatar_url': instance.avatarUrl,
  'avatar_updated_at': instance.avatarUpdatedAt?.toIso8601String(),
};
