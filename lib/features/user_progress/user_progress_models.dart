import 'package:flutter/foundation.dart';

@immutable
class CourseProgress {
  final String id;
  final String userId;
  final String courseId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? currentModuleId;
  final String? currentLessonId;
  final bool? isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseProgress({
    required this.id,
    required this.userId,
    required this.courseId,
    this.startedAt,
    this.completedAt,
    this.currentModuleId,
    this.currentLessonId,
    this.isCompleted,
    this.createdAt,
    this.updatedAt,
  });

  double get completionPercent => isCompleted == true ? 1.0 : _inferPercent();

  double _inferPercent() {
    // Placeholder: we will refine using module/lesson progress aggregation.
    if (startedAt == null) return 0.0;
    return 0.3; // basic heuristic until aggregated data applied
  }

  factory CourseProgress.fromMap(Map<String, dynamic> map) {
    return CourseProgress(
      id: map['id'] as String,
      userId: (map['user_id'] ?? map['auth_user_id']) as String, // in case naming differs
      courseId: map['course_id'] as String,
      startedAt: _dt(map['started_at']),
      completedAt: _dt(map['completed_at']),
      currentModuleId: map['current_module_id'] as String?,
      currentLessonId: map['current_lesson_id'] as String?,
      isCompleted: map['is_completed'] as bool?,
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
    );
  }
}

@immutable
class ModuleProgress {
  final String id;
  final String userId;
  final String moduleId;
  final String? courseProgressId;
  final String? status; // e.g., in_progress, completed
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? averageScore;
  final int? totalLessons;
  final int? completedLessons;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ModuleProgress({
    required this.id,
    required this.userId,
    required this.moduleId,
    this.courseProgressId,
    this.status,
    this.startedAt,
    this.completedAt,
    this.averageScore,
    this.totalLessons,
    this.completedLessons,
    this.createdAt,
    this.updatedAt,
  });

  double get completionPercent {
    if (totalLessons == null || totalLessons == 0) return 0.0;
    final completed = completedLessons ?? 0;
    return (completed / totalLessons!).clamp(0.0, 1.0);
  }

  factory ModuleProgress.fromMap(Map<String, dynamic> map) {
    return ModuleProgress(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      moduleId: map['module_id'] as String,
      courseProgressId: map['course_progress_id'] as String?,
      status: map['status'] as String?,
      startedAt: _dt(map['started_at']),
      completedAt: _dt(map['completed_at']),
      averageScore: (map['average_score'] as num?)?.toDouble(),
      totalLessons: map['total_lessons'] as int?,
      completedLessons: map['completed_lessons'] as int?,
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
    );
  }
}

@immutable
class LessonProgress {
  final String id;
  final String userId;
  final String lessonId;
  final String? courseProgressId;
  final String? status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? videoProgress; // 0.0 - 1.0
  final double? quizScore; // 0 - 100?
  final DateTime? quizAttemptedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LessonProgress({
    required this.id,
    required this.userId,
    required this.lessonId,
    this.courseProgressId,
    this.status,
    this.startedAt,
    this.completedAt,
    this.videoProgress,
    this.quizScore,
    this.quizAttemptedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => completedAt != null || status == 'completed';

  factory LessonProgress.fromMap(Map<String, dynamic> map) {
    return LessonProgress(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      lessonId: map['lesson_id'] as String,
      courseProgressId: map['course_progress_id'] as String?,
      status: map['status'] as String?,
      startedAt: _dt(map['started_at']),
      completedAt: _dt(map['completed_at']),
      videoProgress: (map['video_progress'] as num?)?.toDouble(),
      quizScore: (map['quiz_score'] as num?)?.toDouble(),
      quizAttemptedAt: _dt(map['quiz_attempted_at']),
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
    );
  }
}

DateTime? _dt(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
