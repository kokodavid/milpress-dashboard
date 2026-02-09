import 'package:flutter/foundation.dart';

import 'course_assessment_model.dart';
import 'assessment_level_model.dart';
import 'assessment_sublevel_model.dart';

@immutable
class AssessmentWithLevels {
  final CourseAssessment assessment;
  final List<AssessmentLevel> levels;

  const AssessmentWithLevels({
    required this.assessment,
    required this.levels,
  });
}

@immutable
class LevelWithSublevels {
  final AssessmentLevel level;
  final List<AssessmentSublevel> sublevels;

  const LevelWithSublevels({
    required this.level,
    required this.sublevels,
  });
}
