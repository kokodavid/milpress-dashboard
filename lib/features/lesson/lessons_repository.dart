import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  CreateLessonController(this._repo) : super(const AsyncData<Lesson?>(null));

  Future<Lesson?> create(LessonCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createLesson(data);
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
  return CreateLessonController(repo);
});

class UpdateLessonController extends StateNotifier<AsyncValue<void>> {
  final LessonsRepository _repo;
  UpdateLessonController(this._repo) : super(const AsyncData(null));

  Future<void> update(String id, LessonUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateLesson(id, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateLessonProvider = StateNotifierProvider<UpdateLessonController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonsRepositoryProvider);
  return UpdateLessonController(repo);
});

class DeleteLessonController extends StateNotifier<AsyncValue<void>> {
  final LessonsRepository _repo;
  DeleteLessonController(this._repo) : super(const AsyncData(null));

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteLesson(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final deleteLessonProvider = StateNotifierProvider<DeleteLessonController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonsRepositoryProvider);
  return DeleteLessonController(repo);
});

// Total count of lessons
final lessonsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(lessonsRepositoryProvider);
  return repo.countLessons();
});
