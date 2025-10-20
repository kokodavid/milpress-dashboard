class Course {
  final String id;
  final String title;
  final String? description;
  final int? durationInMinutes;
  final int? level;
  final String? type;
  final String? soundUrlOverview;
  final String? soundUrlDetail;
  final bool locked;
  // jsonb column may contain either an object or an array; keep this flexible
  final Object? modules;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Course({
    required this.id,
    required this.title,
    this.description,
    this.durationInMinutes,
    this.level,
    this.type,
    this.soundUrlOverview,
    this.soundUrlDetail,
    this.locked = false,
  this.modules,
    this.createdAt,
    this.updatedAt,
  });

  factory Course.fromMap(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      description: json['description'] as String?,
      durationInMinutes: json['duration_in_minutes'] as int?,
      level: json['level'] as int?,
      type: json['type'] as String?,
      soundUrlOverview: json['sound_url_overview'] as String?,
      soundUrlDetail: json['sound_url_detail'] as String?,
      locked: (json['locked'] as bool?) ?? false,
      // Don't force-cast to Map to avoid type errors when the JSONB is an array
      modules: json['modules'],
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'duration_in_minutes': durationInMinutes,
      'level': level,
      'type': type,
      'sound_url_overview': soundUrlOverview,
      'sound_url_detail': soundUrlDetail,
      'locked': locked,
      'modules': modules,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    int? durationInMinutes,
    int? level,
    String? type,
    String? soundUrlOverview,
    String? soundUrlDetail,
    bool? locked,
    Object? modules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      level: level ?? this.level,
      type: type ?? this.type,
      soundUrlOverview: soundUrlOverview ?? this.soundUrlOverview,
      soundUrlDetail: soundUrlDetail ?? this.soundUrlDetail,
      locked: locked ?? this.locked,
      modules: modules ?? this.modules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CourseCreate {
  final String title;
  final String? description;
  final int? durationInMinutes;
  final int? level;
  final String? type;
  final String? soundUrlOverview;
  final String? soundUrlDetail;
  final bool locked;
  final Object? modules;

  CourseCreate({
    required this.title,
    this.description,
    this.durationInMinutes,
    this.level,
    this.type,
    this.soundUrlOverview,
    this.soundUrlDetail,
    this.locked = false,
    this.modules,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'title': title,
      if (description != null) 'description': description,
      if (durationInMinutes != null) 'duration_in_minutes': durationInMinutes,
      if (level != null) 'level': level,
      if (type != null) 'type': type,
      if (soundUrlOverview != null) 'sound_url_overview': soundUrlOverview,
      if (soundUrlDetail != null) 'sound_url_detail': soundUrlDetail,
      'locked': locked,
      if (modules != null) 'modules': modules,
    };
  }
}

class CourseUpdate {
  final String? title;
  final String? description;
  final int? durationInMinutes;
  final int? level;
  final String? type;
  final String? soundUrlOverview;
  final String? soundUrlDetail;
  final bool? locked;
  final Object? modules;

  CourseUpdate({
    this.title,
    this.description,
    this.durationInMinutes,
    this.level,
    this.type,
    this.soundUrlOverview,
    this.soundUrlDetail,
    this.locked,
    this.modules,
  });

  Map<String, dynamic> toUpdateMap() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (durationInMinutes != null) 'duration_in_minutes': durationInMinutes,
      if (level != null) 'level': level,
      if (type != null) 'type': type,
      if (soundUrlOverview != null) 'sound_url_overview': soundUrlOverview,
      if (soundUrlDetail != null) 'sound_url_detail': soundUrlDetail,
      if (locked != null) 'locked': locked,
      if (modules != null) 'modules': modules,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// Optional convenience type if you want to fetch/join courses with modules in memory
class CourseWithModules {
  final Course course;
  final List<dynamic> modules; // you can replace dynamic with Module after wiring repositories

  CourseWithModules({required this.course, required this.modules});
}
