import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../course/course_models.dart';
import '../../course/course_repository.dart';

// Holds the currently selected course id for the Lessons list screen
final selectedCourseIdProvider = StateProvider<String?>((ref) => null);

// Resolves the selected Course (or null) as an AsyncValue using existing repository
final selectedCourseProvider = Provider<AsyncValue<Course?>>((ref) {
  final id = ref.watch(selectedCourseIdProvider);
  if (id == null) {
    return const AsyncData<Course?>(null);
  }
  return ref.watch(courseByIdProvider(id));
});

// Selection for lesson detail pane
final selectedLessonIdProvider = StateProvider<String?>((ref) => null);
