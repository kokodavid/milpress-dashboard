import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/features/auth/admin_activity_repository.dart';
import 'package:milpress_dashboard/features/auth/activity_actions.dart';

import 'lesson_v2_models.dart';
import 'lesson_v2_repository_impl.dart';

abstract class LessonV2Repository {
  Future<List<NewLesson>> fetchLessonsForModule(String moduleId);
  Future<LessonWithSteps?> fetchLessonById(String lessonId);
  Future<NewLesson> createLessonWithSteps(
    NewLessonCreate lesson,
    List<LessonStepInput> steps,
  );
  Future<void> updateLesson(String id, NewLessonUpdate update);
  Future<void> updateSteps(String lessonId, List<LessonStepInput> steps);
  Future<void> deleteLesson(String id);
  Future<void> reorderLessons(String moduleId, List<String> orderedLessonIds);
  Future<int> countLessons();
  Future<int> countLessonsForCourse(String courseId);
}

final lessonV2RepositoryProvider = Provider<LessonV2Repository>((ref) {
  return LessonV2RepositoryImpl();
});

final lessonsForModuleProvider =
    FutureProvider.family<List<NewLesson>, String>((ref, moduleId) async {
  final repo = ref.read(lessonV2RepositoryProvider);
  return repo.fetchLessonsForModule(moduleId);
});

final lessonByIdProvider =
    FutureProvider.family<LessonWithSteps?, String>((ref, lessonId) async {
  final repo = ref.read(lessonV2RepositoryProvider);
  return repo.fetchLessonById(lessonId);
});

final stepsForLessonProvider =
    FutureProvider.family<List<LessonStep>, String>((ref, lessonId) async {
  final repo = ref.read(lessonV2RepositoryProvider);
  final detail = await repo.fetchLessonById(lessonId);
  return detail?.steps ?? const [];
});

class SaveLessonController extends StateNotifier<AsyncValue<NewLesson?>> {
  final LessonV2Repository _repo;
  final Ref _ref;

  SaveLessonController(this._repo, this._ref)
      : super(const AsyncData<NewLesson?>(null));

  Future<NewLesson?> create(NewLessonCreate lesson, List<LessonStepInput> steps) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createLessonWithSteps(lesson, steps);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonCreated,
        targetType: 'lesson',
        targetId: created.id,
        details: {
          'title': created.title,
          'display_order': created.displayOrder,
          'module_id': created.moduleId,
          'lesson_type': created.lessonType.name,
        },
      );
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> update(String id, NewLessonUpdate update) async {
    state = const AsyncLoading();
    try {
      await _repo.updateLesson(id, update);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonUpdated,
        targetType: 'lesson',
        targetId: id,
        details: update.toUpdateMap(),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateSteps(String lessonId, List<LessonStepInput> steps) async {
    state = const AsyncLoading();
    try {
      await _repo.updateSteps(lessonId, steps);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonUpdated,
        targetType: 'lesson',
        targetId: lessonId,
        details: {
          'steps_updated': steps.length,
        },
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final saveLessonProvider =
    StateNotifierProvider<SaveLessonController, AsyncValue<NewLesson?>>((ref) {
  final repo = ref.watch(lessonV2RepositoryProvider);
  return SaveLessonController(repo, ref);
});

class DeleteLessonController extends StateNotifier<AsyncValue<void>> {
  final LessonV2Repository _repo;
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

final deleteLessonProvider =
    StateNotifierProvider<DeleteLessonController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonV2RepositoryProvider);
  return DeleteLessonController(repo, ref);
});

final lessonsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(lessonV2RepositoryProvider);
  return repo.countLessons();
});

final lessonsCountForCourseProvider =
    FutureProvider.family<int, String>((ref, courseId) async {
  final repo = ref.watch(lessonV2RepositoryProvider);
  return repo.countLessonsForCourse(courseId);
});
