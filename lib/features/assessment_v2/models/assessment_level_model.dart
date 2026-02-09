import 'package:flutter/foundation.dart';

DateTime? _dt(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

@immutable
class AssessmentLevel {
  final String id;
  final String assessmentId;
  final String title;
  final String? description;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssessmentLevel({
    required this.id,
    required this.assessmentId,
    required this.title,
    this.description,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory AssessmentLevel.fromMap(Map<String, dynamic> map) {
    return AssessmentLevel(
      id: map['id'] as String,
      assessmentId: map['assessment_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      displayOrder: map['display_order'] as int,
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'assessment_id': assessmentId,
        'title': title,
        'description': description,
        'display_order': displayOrder,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class AssessmentLevelCreate {
  final String assessmentId;
  final String title;
  final String? description;
  final int displayOrder;

  const AssessmentLevelCreate({
    required this.assessmentId,
    required this.title,
    this.description,
    required this.displayOrder,
  });

  Map<String, dynamic> toInsertMap() => {
        'assessment_id': assessmentId,
        'title': title,
        if (description != null) 'description': description,
        'display_order': displayOrder,
      };
}

class AssessmentLevelUpdate {
  final String? title;
  final String? description;
  final int? displayOrder;

  const AssessmentLevelUpdate({
    this.title,
    this.description,
    this.displayOrder,
  });

  Map<String, dynamic> toUpdateMap() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (displayOrder != null) 'display_order': displayOrder,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
