import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:milpress_dashboard/features/auth/admin_activity_repository.dart';
import 'package:milpress_dashboard/features/auth/activity_actions.dart';

import 'lesson_quiz_model.dart';

class LessonQuizRepository {
  final SupabaseClient _client;
  LessonQuizRepository(this._client);

  static const String table = 'lesson_quiz';

  Future<List<LessonQuiz>> getQuizzesForLesson(String lessonId) async {
    final List data = await _client
        .from(table)
        .select()
        .eq('lesson_id', lessonId)
        .order('created_at', ascending: true);
    return data.map((e) => LessonQuiz.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<LessonQuiz> createQuiz(LessonQuizCreate input) async {
    final List data = await _client.from(table).insert(input.toInsertMap()).select();
    return LessonQuiz.fromMap(data.first as Map<String, dynamic>);
  }

  Future<void> updateQuiz(String id, LessonQuizUpdate update) async {
    await _client.from(table).update(update.toUpdateMap()).eq('id', id);
  }

  Future<void> deleteQuiz(String id) async {
    await _client.from(table).delete().eq('id', id);
  }
}

final lessonQuizRepositoryProvider = Provider<LessonQuizRepository>((ref) {
  final client = Supabase.instance.client;
  return LessonQuizRepository(client);
});

final quizzesForLessonProvider = FutureProvider.family<List<LessonQuiz>, String>((ref, lessonId) async {
  final repo = ref.watch(lessonQuizRepositoryProvider);
  return repo.getQuizzesForLesson(lessonId);
});

// Mutation controllers
class CreateLessonQuizController extends StateNotifier<AsyncValue<LessonQuiz?>> {
  final LessonQuizRepository _repo;
  final Ref _ref;
  CreateLessonQuizController(this._repo, this._ref)
      : super(const AsyncData<LessonQuiz?>(null));

  Future<LessonQuiz?> create(LessonQuizCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createQuiz(data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonQuizCreated,
        targetType: 'lesson_quiz',
        targetId: created.id,
        details: {
          'lesson_id': created.lessonId,
          if (created.questionType != null) 'question_type': created.questionType,
          if (created.stage != null) 'stage': created.stage,
          if (created.difficultyLevel != null) 'difficulty_level': created.difficultyLevel,
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

final createLessonQuizProvider = StateNotifierProvider<CreateLessonQuizController, AsyncValue<LessonQuiz?>>((ref) {
  final repo = ref.watch(lessonQuizRepositoryProvider);
  return CreateLessonQuizController(repo, ref);
});

class UpdateLessonQuizController extends StateNotifier<AsyncValue<void>> {
  final LessonQuizRepository _repo;
  final Ref _ref;
  UpdateLessonQuizController(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> update(String id, LessonQuizUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateQuiz(id, data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonQuizUpdated,
        targetType: 'lesson_quiz',
        targetId: id,
        details: data.toUpdateMap(),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateLessonQuizProvider = StateNotifierProvider<UpdateLessonQuizController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonQuizRepositoryProvider);
  return UpdateLessonQuizController(repo, ref);
});

class DeleteLessonQuizController extends StateNotifier<AsyncValue<void>> {
  final LessonQuizRepository _repo;
  final Ref _ref;
  DeleteLessonQuizController(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> delete(String id, {Map<String, dynamic>? details}) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteQuiz(id);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.lessonQuizDeleted,
        targetType: 'lesson_quiz',
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

final deleteLessonQuizProvider = StateNotifierProvider<DeleteLessonQuizController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonQuizRepositoryProvider);
  return DeleteLessonQuizController(repo, ref);
});
