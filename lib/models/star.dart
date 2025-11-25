import 'knowledge.dart';
import 'persona.dart';

enum StarTargetType { knowledge, persona }

extension StarTargetTypeX on StarTargetType {
  String get value => switch (this) {
        StarTargetType.knowledge => 'knowledge',
        StarTargetType.persona => 'persona',
      };

  static StarTargetType? fromValue(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'knowledge':
        return StarTargetType.knowledge;
      case 'persona':
        return StarTargetType.persona;
      default:
        return null;
    }
  }
}

class StarredItem {
  final String starId;
  final StarTargetType targetType;
  final String targetId;
  final DateTime? createdAt;
  final Knowledge? knowledge;
  final Persona? persona;
  final Map<String, dynamic>? raw;

  const StarredItem({
    required this.starId,
    required this.targetType,
    required this.targetId,
    this.createdAt,
    this.knowledge,
    this.persona,
    this.raw,
  });

  bool get isKnowledge => targetType == StarTargetType.knowledge;
  bool get isPersona => targetType == StarTargetType.persona;
  bool get hasDetails => knowledge != null || persona != null;

  String get displayTitle {
    if (knowledge != null) return knowledge!.name;
    if (persona != null) return persona!.name;
    return raw?['title']?.toString() ?? targetId;
  }

  String get displayDescription {
    if (knowledge != null) return knowledge!.description;
    if (persona != null) return persona!.description;
    return raw?['description']?.toString() ?? '暂无描述';
  }

  factory StarredItem.fromJson(Map<String, dynamic> json) {
    final targetType =
        StarTargetTypeX.fromValue(json['target_type']?.toString() ??
            json['type']?.toString()) ??
            StarTargetType.knowledge;
    final targetId =
        json['target_id']?.toString() ?? json['knowledge_id']?.toString() ?? '';

    Knowledge? knowledge;
    Persona? persona;

    if (targetType == StarTargetType.knowledge) {
      final knowledgePayload =
          _pickPayload(json, keys: ['knowledge', 'target', 'target_data']);
      if (knowledgePayload != null) {
        try {
          knowledge = Knowledge.fromJson(
            knowledgePayload.cast<String, dynamic>(),
          );
        } catch (_) {
          // ignore parse error, fallback to raw
        }
      }
    } else {
      final personaPayload =
          _pickPayload(json, keys: ['persona', 'target', 'target_data']);
      if (personaPayload != null) {
        try {
          persona =
              Persona.fromJson(personaPayload.cast<String, dynamic>());
        } catch (_) {
          // ignore parse error
        }
      }
    }

    final createdAtValue = json['created_at'];
    DateTime? createdAt;
    if (createdAtValue is String && createdAtValue.isNotEmpty) {
      createdAt = DateTime.tryParse(createdAtValue);
    }

    final starId =
        json['id']?.toString() ??
            'star_${targetType.value}_${targetId}_${createdAtValue ?? ''}';

    return StarredItem(
      starId: starId,
      targetType: targetType,
      targetId: targetId,
      createdAt: createdAt,
      knowledge: knowledge,
      persona: persona,
      raw: Map<String, dynamic>.from(json),
    );
  }

  static Map<String, dynamic>? _pickPayload(
    Map<String, dynamic> json, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }
    return null;
  }
}


