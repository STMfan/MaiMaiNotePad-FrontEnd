import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  final String id;
  final String title;
  final String content;
  final String? summary; // 消息简介，可选
  @JsonKey(name: 'message_type')
  final String type; // system, notification, review_result, direct, announcement
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  @JsonKey(name: 'sender_id')
  final String? senderId;
  @JsonKey(name: 'recipient_id')
  final String? recipientId;
  @JsonKey(name: 'broadcast_scope')
  final String? broadcastScope;

  Message({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.senderId,
    this.recipientId,
    this.broadcastScope,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
