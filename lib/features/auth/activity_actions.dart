/// Central definitions of admin activity action strings.
/// Keeps logs consistent across the app.
class ActivityActions {
  // Course actions
  static const String courseCreated = 'course_created';
  static const String courseUpdated = 'course_updated';
  static const String courseDeleted = 'course_deleted';
  static const String courseLocked = 'course_locked';
  static const String courseUnlocked = 'course_unlocked';

  // Future extension for modules & lessons
  static const String moduleCreated = 'module_created';
  static const String moduleUpdated = 'module_updated';
  static const String moduleDeleted = 'module_deleted';

  static const String lessonCreated = 'lesson_created';
  static const String lessonUpdated = 'lesson_updated';
  static const String lessonDeleted = 'lesson_deleted';

  // Lesson quiz actions
  static const String lessonQuizCreated = 'lesson_quiz_created';
  static const String lessonQuizUpdated = 'lesson_quiz_updated';
  static const String lessonQuizDeleted = 'lesson_quiz_deleted';

  // Assessment V2 actions
  static const String assessmentV2Created = 'assessment_v2_created';
  static const String assessmentV2Updated = 'assessment_v2_updated';
  static const String assessmentV2Deleted = 'assessment_v2_deleted';

  static const String assessmentLevelCreated = 'assessment_level_created';
  static const String assessmentLevelUpdated = 'assessment_level_updated';
  static const String assessmentLevelDeleted = 'assessment_level_deleted';

  static const String assessmentSublevelCreated = 'assessment_sublevel_created';
  static const String assessmentSublevelUpdated = 'assessment_sublevel_updated';
  static const String assessmentSublevelDeleted = 'assessment_sublevel_deleted';
}
