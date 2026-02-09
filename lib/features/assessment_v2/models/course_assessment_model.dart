import 'package:flutter/foundation.dart';

DateTime? _dt(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

@immutable
class CourseAssessment {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourseAssessment({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CourseAssessment.fromMap(Map<String, dynamic> map) {
    return CourseAssessment(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isActive: (map['is_active'] as bool?) ?? true,
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'course_id': courseId,
        'title': title,
        'description': description,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class CourseAssessmentCreate {
  final String courseId;
  final String title;
  final String? description;
  final bool isActive;

  const CourseAssessmentCreate({
    required this.courseId,
    required this.title,
    this.description,
    this.isActive = true,
  });

  Map<String, dynamic> toInsertMap() => {
        'course_id': courseId,
        'title': title,
        if (description != null) 'description': description,
        'is_active': isActive,
      };
}

class CourseAssessmentUpdate {
  final String? title;
  final String? description;
  final bool? isActive;

  const CourseAssessmentUpdate({
    this.title,
    this.description,
    this.isActive,
  });

  Map<String, dynamic> toUpdateMap() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (isActive != null) 'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
