import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String? email;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    this.email,
    required this.role,
    this.createdAt,
    this.updatedAt,
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
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
      );
    }
  }
  Map<String, dynamic> toJson() => _$UserToJson(this);

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';
  bool get isAdminOrModerator => isAdmin || isModerator;
}
