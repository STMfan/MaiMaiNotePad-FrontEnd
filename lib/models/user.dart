import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  @JsonKey(name: 'username')
  final String name;
  final String? email;
  final String role;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'avatar_updated_at')
  final DateTime? avatarUpdatedAt;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.avatarUrl,
    this.avatarUpdatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return _$UserFromJson(json);
    } catch (e) {
      // 如果反序列化失败，提供默认值
      return User(
        id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
        name:
            json['name']?.toString() ?? json['username']?.toString() ?? '未知用户',
        email: json['email']?.toString(),
        role:
            json['role']?.toString() ?? json['user_role']?.toString() ?? 'user',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : (json['createdAt'] != null
                ? DateTime.tryParse(json['createdAt'].toString())
                : null),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : (json['updatedAt'] != null
                ? DateTime.tryParse(json['updatedAt'].toString())
                : null),
        avatarUrl: json['avatar_url']?.toString(),
        avatarUpdatedAt: json['avatar_updated_at'] != null
            ? DateTime.tryParse(json['avatar_updated_at'].toString())
            : null,
      );
    }
  }
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';
  bool get isAdminOrModerator => isAdmin || isModerator;
}
