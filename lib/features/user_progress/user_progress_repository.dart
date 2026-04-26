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
  /// lesson_completion has no course_progress_id column — we resolve lesson IDs
  /// via modules first, then delete by (user_id, lesson_id).
  /// Order: lesson_completion → module_progress → course_progress.
  Future<void> deleteCourseProgressById(
    String courseProgressId, {
    required String userId,
    required String courseId,
  }) async {
    // 1. Resolve all lesson IDs that belong to this course.
    final List mods = await _client
        .from('modules')
        .select('id')
        .eq('course_id', courseId);

    if (mods.isNotEmpty) {
      final moduleIds = mods.map((e) => (e as Map)['id']).toList();
      final inList = '(${moduleIds.map((id) => '"$id"').join(',')})';
      final List lessonRows = await _client
          .from('new_lessons')
          .select('id')
          .filter('module_id', 'in', inList);

      if (lessonRows.isNotEmpty) {
        final lessonIds = lessonRows.map((e) => (e as Map)['id']).toList();
        final lessonsInList = '(${lessonIds.map((id) => '"$id"').join(',')})';
        // 2. Delete lesson_completion rows by (user_id, lesson_id).
        await _client
            .from(lessonProgressTable)
            .delete()
            .eq('user_id', userId)
            .filter('lesson_id', 'in', lessonsInList);
      }
    }

    // 3. Delete module_progress — this table does have course_progress_id.
    await _client
        .from(moduleProgressTable)
        .delete()
        .eq('course_progress_id', courseProgressId);

    // 4. Delete the course_progress record itself.
    await _client
        .from(courseProgressTable)
        .delete()
        .eq('id', courseProgressId);
  }

  /// Deletes a single lesson completion record.
  /// Uses [lessonProgressId] when non-empty; otherwise falls back to
  /// [userId] + [lessonId] composite key.
  Future<void> deleteLessonProgressById(
    String lessonProgressId, {
    String? userId,
    String? lessonId,
  }) async {
    if (lessonProgressId.isNotEmpty) {
      await _client
          .from(lessonProgressTable)
          .delete()
          .eq('id', lessonProgressId);
    } else if (userId != null && lessonId != null) {
      await _client
          .from(lessonProgressTable)
          .delete()
          .eq('user_id', userId)
          .eq('lesson_id', lessonId);
    } else {
      throw ArgumentError(
        'Either lessonProgressId or both userId and lessonId must be provided.',
      );
    }
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

  Future<bool> delete(
    String courseProgressId, {
    required String userId,
    required String courseId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteCourseProgressById(
        courseProgressId,
        userId: userId,
        courseId: courseId,
      );
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

  Future<bool> delete(
    String lessonProgressId, {
    String? userId,
    String? lessonId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteLessonProgressById(
        lessonProgressId,
        userId: userId,
        lessonId: lessonId,
      );
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
