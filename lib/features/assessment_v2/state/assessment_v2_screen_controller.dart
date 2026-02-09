import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../course/course_models.dart';
import '../../course/course_repository.dart';

final assessmentSelectedCourseIdProvider =
    StateProvider<String?>((ref) => null);

final assessmentSelectedCourseProvider = Provider<AsyncValue<Course?>>((ref) {
  final id = ref.watch(assessmentSelectedCourseIdProvider);
  if (id == null) return const AsyncData<Course?>(null);
  return ref.watch(courseByIdProvider(id));
});

final selectedLevelIdProvider = StateProvider<String?>((ref) => null);

final selectedSublevelIdProvider = StateProvider<String?>((ref) => null);
