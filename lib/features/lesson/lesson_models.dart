class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String? content;
  final int position;
  final String? videoUrl;
  final String? audioUrl;
  final int? durationMinutes;
  final String? thumbnails;
  final String? category;
  final String? level;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.position,
    this.content,
    this.videoUrl,
    this.audioUrl,
    this.durationMinutes,
    this.thumbnails,
    this.category,
    this.level,
    this.createdAt,
    this.updatedAt,
  });

  factory Lesson.fromMap(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      moduleId: json['module_id'] as String,
      title: (json['title'] ?? '') as String,
      content: json['content'] as String?,
      position: (json['position'] as int?) ?? 0,
      videoUrl: json['video_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      thumbnails: json['thumbnails'] as String?,
      category: json['category'] as String?,
      level: json['level'] as String?,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'content': content,
      'position': position,
      'video_url': videoUrl,
      'audio_url': audioUrl,
      'duration_minutes': durationMinutes,
      'thumbnails': thumbnails,
      'category': category,
      'level': level,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Lesson copyWith({
    String? id,
    String? moduleId,
    String? title,
    String? content,
    int? position,
    String? videoUrl,
    String? audioUrl,
    int? durationMinutes,
    String? thumbnails,
    String? category,
    String? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Lesson(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      content: content ?? this.content,
      position: position ?? this.position,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      thumbnails: thumbnails ?? this.thumbnails,
      category: category ?? this.category,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LessonCreate {
  final String moduleId;
  final String title;
  final int position;
  final String? content;
  final String? videoUrl;
  final String? audioUrl;
  final int? durationMinutes;
  final String? thumbnails;
  final String? category;
  final String? level;

  LessonCreate({
    required this.moduleId,
    required this.title,
    required this.position,
    this.content,
    this.videoUrl,
    this.audioUrl,
    this.durationMinutes,
    this.thumbnails,
    this.category,
    this.level,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'module_id': moduleId,
      'title': title,
      'position': position,
      if (content != null) 'content': content,
      if (videoUrl != null) 'video_url': videoUrl,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (thumbnails != null) 'thumbnails': thumbnails,
      if (category != null) 'category': category,
      if (level != null) 'level': level,
    };
  }
}

class LessonUpdate {
  final String? title;
  final int? position;
  final String? content;
  final String? videoUrl;
  final String? audioUrl;
  final int? durationMinutes;
  final String? thumbnails;
  final String? category;
  final String? level;

  LessonUpdate({
    this.title,
    this.position,
    this.content,
    this.videoUrl,
    this.audioUrl,
    this.durationMinutes,
    this.thumbnails,
    this.category,
    this.level,
  });

  Map<String, dynamic> toUpdateMap() {
    return {
      if (title != null) 'title': title,
      if (position != null) 'position': position,
      if (content != null) 'content': content,
      if (videoUrl != null) 'video_url': videoUrl,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (thumbnails != null) 'thumbnails': thumbnails,
      if (category != null) 'category': category,
      if (level != null) 'level': level,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
