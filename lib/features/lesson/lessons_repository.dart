import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/features/auth/admin_activity_repository.dart';
import 'package:milpress_dashboard/features/auth/activity_actions.dart';
import 'lesson_models.dart';
import 'lessons_repository_impl.dart';

// Provider to fetch lessons for a given module
final lessonsForModuleProvider = FutureProvider.family<List<Lesson>, String>((ref, moduleId) async {
  final repo = ref.read(lessonsRepositoryProvider);
  return repo.getLessonsForModule(moduleId);
});

// Provider to fetch a single lesson by id
final lessonByIdProvider = FutureProvider.family<Lesson?, String>((ref, id) async {
  final repo = ref.read(lessonsRepositoryProvider);
  return repo.getLessonById(id);
});

// Mutation notifiers
class CreateLessonController extends StateNotifier<AsyncValue<Lesson?>> {
  final LessonsRepository _repo;
  final Ref _ref;
  CreateLessonController(this._repo, this._ref)
      : super(const AsyncData<Lesson?>(null));

  Future<Lesson?> create(LessonCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createLesson(data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonCreated,
        targetType: 'lesson',
        targetId: created.id,
        details: {
          'title': created.title,
          'position': created.position,
          'module_id': created.moduleId,
          if (created.durationMinutes != null)
            'duration_minutes': created.durationMinutes,
          if (created.level != null) 'level': created.level,
        },
      );
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createLessonProvider = StateNotifierProvider<CreateLessonController, AsyncValue<Lesson?>>((ref) {
  final repo = ref.watch(lessonsRepositoryProvider);
  return CreateLessonController(repo, ref);
});

class UpdateLessonController extends StateNotifier<AsyncValue<void>> {
  final LessonsRepository _repo;
  final Ref _ref;
  UpdateLessonController(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> update(String id, LessonUpdate data) async {
    state = const AsyncLoading();
    try {
      // Fetch old values before updating
      final oldLesson = await _repo.getLessonById(id);
      final changes = <String, dynamic>{};
      
      // Track what changed
      if (data.title != null && data.title != oldLesson?.title) {
        changes['title_old'] = oldLesson?.title;
        changes['title_new'] = data.title;
      }
      if (data.durationMinutes != null && data.durationMinutes != oldLesson?.durationMinutes) {
        changes['duration_minutes_old'] = oldLesson?.durationMinutes;
        changes['duration_minutes_new'] = data.durationMinutes;
      }
      if (data.position != null && data.position != oldLesson?.position) {
        changes['position_old'] = oldLesson?.position;
        changes['position_new'] = data.position;
      }
      
      await _repo.updateLesson(id, data);
      
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonUpdated,
        targetType: 'lesson',
        targetId: id,
        details: changes,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateLessonProvider = StateNotifierProvider<UpdateLessonController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonsRepositoryProvider);
  return UpdateLessonController(repo, ref);
});

class DeleteLessonController extends StateNotifier<AsyncValue<void>> {
  final LessonsRepository _repo;
  final Ref _ref;
  DeleteLessonController(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> delete(String id, {Map<String, dynamic>? details}) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteLesson(id);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonDeleted,
        targetType: 'lesson',
        targetId: id,
        details: details,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final deleteLessonProvider = StateNotifierProvider<DeleteLessonController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonsRepositoryProvider);
  return DeleteLessonController(repo, ref);
});

// Total count of lessons
final lessonsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(lessonsRepositoryProvider);
  return repo.countLessons();
});

// Total lessons for a course
final lessonsCountForCourseProvider = FutureProvider.family<int, String>((ref, courseId) async {
  final repo = ref.watch(lessonsRepositoryProvider);
  return repo.countLessonsForCourse(courseId);
});
