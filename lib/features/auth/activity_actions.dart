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
}
