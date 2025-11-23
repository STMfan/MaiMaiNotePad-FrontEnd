// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  summary: json['summary'] as String?,
  type: json['message_type'] as String,
  isRead: json['is_read'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  readAt: json['read_at'] == null
      ? null
      : DateTime.parse(json['read_at'] as String),
  senderId: json['sender_id'] as String?,
  recipientId: json['recipient_id'] as String?,
  broadcastScope: json['broadcast_scope'] as String?,
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'summary': instance.summary,
  'message_type': instance.type,
  'is_read': instance.isRead,
  'created_at': instance.createdAt.toIso8601String(),
  'read_at': instance.readAt?.toIso8601String(),
  'sender_id': instance.senderId,
  'recipient_id': instance.recipientId,
  'broadcast_scope': instance.broadcastScope,
};
