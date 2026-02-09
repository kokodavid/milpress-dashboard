import 'package:flutter/foundation.dart';

DateTime? _dt(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

@immutable
class AssessmentSublevel {
  final String id;
  final String levelId;
  final String title;
  final String? description;
  final int displayOrder;
  final List<dynamic> questions;
  final int passingScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssessmentSublevel({
    required this.id,
    required this.levelId,
    required this.title,
    this.description,
    required this.displayOrder,
    required this.questions,
    this.passingScore = 70,
    this.createdAt,
    this.updatedAt,
  });

  factory AssessmentSublevel.fromMap(Map<String, dynamic> map) {
    return AssessmentSublevel(
      id: map['id'] as String,
      levelId: map['level_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      displayOrder: map['display_order'] as int,
      questions: (map['questions'] as List?) ?? [],
      passingScore: (map['passing_score'] as int?) ?? 70,
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'level_id': levelId,
        'title': title,
        'description': description,
        'display_order': displayOrder,
        'questions': questions,
        'passing_score': passingScore,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class AssessmentSublevelCreate {
  final String levelId;
  final String title;
  final String? description;
  final int displayOrder;
  final List<dynamic> questions;
  final int passingScore;

  const AssessmentSublevelCreate({
    required this.levelId,
    required this.title,
    this.description,
    required this.displayOrder,
    required this.questions,
    this.passingScore = 70,
  });

  Map<String, dynamic> toInsertMap() => {
        'level_id': levelId,
        'title': title,
        if (description != null) 'description': description,
        'display_order': displayOrder,
        'questions': questions,
        'passing_score': passingScore,
      };
}

class AssessmentSublevelUpdate {
  final String? title;
  final String? description;
  final int? displayOrder;
  final List<dynamic>? questions;
  final int? passingScore;

  const AssessmentSublevelUpdate({
    this.title,
    this.description,
    this.displayOrder,
    this.questions,
    this.passingScore,
  });

  Map<String, dynamic> toUpdateMap() => {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (displayOrder != null) 'display_order': displayOrder,
        if (questions != null) 'questions': questions,
        if (passingScore != null) 'passing_score': passingScore,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
