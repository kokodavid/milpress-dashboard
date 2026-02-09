import 'package:flutter/foundation.dart';

DateTime? _dt(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

@immutable
class AssessmentV2Progress {
  final String id;
  final String userId;
  final String sublevelId;
  final String assessmentId;
  final int? score;
  final int? maxScore;
  final bool isPassed;
  final int attempts;
  final Map<String, dynamic>? answers;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AssessmentV2Progress({
    required this.id,
    required this.userId,
    required this.sublevelId,
    required this.assessmentId,
    this.score,
    this.maxScore,
    this.isPassed = false,
    this.attempts = 0,
    this.answers,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  double get scorePercent {
    if (maxScore == null || maxScore == 0 || score == null) return 0.0;
    return (score! / maxScore!).clamp(0.0, 1.0);
  }

  factory AssessmentV2Progress.fromMap(Map<String, dynamic> map) {
    return AssessmentV2Progress(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      sublevelId: map['sublevel_id'] as String,
      assessmentId: map['assessment_id'] as String,
      score: map['score'] as int?,
      maxScore: map['max_score'] as int?,
      isPassed: (map['is_passed'] as bool?) ?? false,
      attempts: (map['attempts'] as int?) ?? 0,
      answers: (map['answers'] as Map?)?.cast<String, dynamic>(),
      startedAt: _dt(map['started_at']),
      completedAt: _dt(map['completed_at']),
      createdAt: _dt(map['created_at']),
      updatedAt: _dt(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'sublevel_id': sublevelId,
        'assessment_id': assessmentId,
        'score': score,
        'max_score': maxScore,
        'is_passed': isPassed,
        'attempts': attempts,
        'answers': answers,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
