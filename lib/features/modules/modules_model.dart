class Module {
  final String id;
  final String courseId;
  final int position;
  final int? durationMinutes;
  final bool locked;
  final String? lockMessage;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Module({
    required this.id,
    required this.courseId,
    required this.position,
    this.durationMinutes,
    this.locked = false,
    this.lockMessage,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Module.fromMap(Map<String, dynamic> json) {
    return Module(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      position: (json['position'] as int?) ?? 0,
      durationMinutes: json['duration_minutes'] as int?,
      locked: (json['locked'] as bool?) ?? false,
      lockMessage: json['lock_message'] as String?,
      description: json['description'] as String?,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'position': position,
      'duration_minutes': durationMinutes,
      'locked': locked,
      'lock_message': lockMessage,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Module copyWith({
    String? id,
    String? courseId,
    int? position,
    int? durationMinutes,
    bool? locked,
    String? lockMessage,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Module(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      position: position ?? this.position,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      locked: locked ?? this.locked,
      lockMessage: lockMessage ?? this.lockMessage,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ModuleCreate {
  final String courseId;
  final int position;
  final int? durationMinutes;
  final bool locked;
  final String? lockMessage;
  final String? description;

  ModuleCreate({
    required this.courseId,
    required this.position,
    this.durationMinutes,
    this.locked = false,
    this.lockMessage,
    this.description,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'course_id': courseId,
      'position': position,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'locked': locked,
      if (lockMessage != null) 'lock_message': lockMessage,
      if (description != null) 'description': description,
    };
  }
}

class ModuleUpdate {
  final int? position;
  final int? durationMinutes;
  final bool? locked;
  final String? lockMessage;
  final String? description;

  ModuleUpdate({
    this.position,
    this.durationMinutes,
    this.locked,
    this.lockMessage,
    this.description,
  });

  Map<String, dynamic> toUpdateMap() {
    return {
      if (position != null) 'position': position,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (locked != null) 'locked': locked,
      if (lockMessage != null) 'lock_message': lockMessage,
      if (description != null) 'description': description,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
