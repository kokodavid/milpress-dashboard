import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_progress_models.dart';

class UserProgressRepository {
  final SupabaseClient _client;
  UserProgressRepository(this._client);

  static const courseProgressTable = 'course_progress';
  static const moduleProgressTable = 'module_progress';
  static const lessonProgressTable = 'lesson_completion';
  static const assignmentProgressTable = 'course_assessment_progress';

  Future<List<CourseProgress>> fetchCourseProgress(String userId) async {
    final List data = await _client
        .from(courseProgressTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => CourseProgress.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<ModuleProgress>> fetchModuleProgress(String userId) async {
    final List data = await _client
        .from(moduleProgressTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => ModuleProgress.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<List<LessonProgress>> fetchLessonProgress(String userId) async {
    final List data = await _client
        .from(lessonProgressTable)
        .select()
        .eq('user_id', userId);
    return data.map((e) => LessonProgress.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  /// Deletes a single course's progress for [userId] including all child records.
  /// Order: lesson_completion → module_progress → course_progress.
  Future<void> deleteCourseProgressById(String courseProgressId) async {
    await _client
        .from(lessonProgressTable)
        .delete()
        .eq('course_progress_id', courseProgressId);

    await _client
        .from(moduleProgressTable)
        .delete()
        .eq('course_progress_id', courseProgressId);

    await _client
        .from(courseProgressTable)
        .delete()
        .eq('id', courseProgressId);
  }

  /// Deletes a single lesson completion record by its own [id].
  Future<void> deleteLessonProgressById(String lessonProgressId) async {
    await _client
        .from(lessonProgressTable)
        .delete()
        .eq('id', lessonProgressId);
  }

  /// Deletes ALL progress records for [userId] across every progress table.
  /// Order matters — delete child records before parent course_progress.
  Future<void> resetAllProgressForUser(String userId) async {
    await _client
        .from(lessonProgressTable)
        .delete()
        .eq('user_id', userId);

    await _client
        .from(moduleProgressTable)
        .delete()
        .eq('user_id', userId);

    await _client
        .from(assignmentProgressTable)
        .delete()
        .eq('user_id', userId);

    await _client
        .from(courseProgressTable)
        .delete()
        .eq('user_id', userId);
  }
}

// ── Read providers ────────────────────────────────────────────────────────────

final userProgressRepositoryProvider = Provider<UserProgressRepository>((ref) {
  final client = Supabase.instance.client;
  return UserProgressRepository(client);
});

final courseProgressForUserProvider = FutureProvider.family<List<CourseProgress>, String>((ref, userId) async {
  final repo = ref.watch(userProgressRepositoryProvider);
  return repo.fetchCourseProgress(userId);
});

final moduleProgressForUserProvider = FutureProvider.family<List<ModuleProgress>, String>((ref, userId) async {
  final repo = ref.watch(userProgressRepositoryProvider);
  return repo.fetchModuleProgress(userId);
});

final lessonProgressForUserProvider = FutureProvider.family<List<LessonProgress>, String>((ref, userId) async {
  final repo = ref.watch(userProgressRepositoryProvider);
  return repo.fetchLessonProgress(userId);
});

// ── Reset progress controller ─────────────────────────────────────────────────

class ResetUserProgressController extends StateNotifier<AsyncValue<void>> {
  final UserProgressRepository _repo;

  ResetUserProgressController(this._repo) : super(const AsyncData(null));

  Future<bool> reset(String userId) async {
    state = const AsyncLoading();
    try {
      await _repo.resetAllProgressForUser(userId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final resetUserProgressProvider =
    StateNotifierProvider.autoDispose<ResetUserProgressController, AsyncValue<void>>((ref) {
  final repo = ref.watch(userProgressRepositoryProvider);
  return ResetUserProgressController(repo);
});

// ── Delete single course progress ─────────────────────────────────────────────

class DeleteCourseProgressController extends StateNotifier<AsyncValue<void>> {
  final UserProgressRepository _repo;
  DeleteCourseProgressController(this._repo) : super(const AsyncData(null));

  Future<bool> delete(String courseProgressId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteCourseProgressById(courseProgressId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final deleteCourseProgressProvider =
    StateNotifierProvider.autoDispose<DeleteCourseProgressController, AsyncValue<void>>((ref) {
  final repo = ref.watch(userProgressRepositoryProvider);
  return DeleteCourseProgressController(repo);
});

// ── Delete single lesson progress ─────────────────────────────────────────────

class DeleteLessonProgressController extends StateNotifier<AsyncValue<void>> {
  final UserProgressRepository _repo;
  DeleteLessonProgressController(this._repo) : super(const AsyncData(null));

  Future<bool> delete(String lessonProgressId) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteLessonProgressById(lessonProgressId);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final deleteLessonProgressProvider =
    StateNotifierProvider.autoDispose<DeleteLessonProgressController, AsyncValue<void>>((ref) {
  final repo = ref.watch(userProgressRepositoryProvider);
  return DeleteLessonProgressController(repo);
});
