import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  CreateLessonQuizController(this._repo) : super(const AsyncData<LessonQuiz?>(null));

  Future<LessonQuiz?> create(LessonQuizCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createQuiz(data);
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
  return CreateLessonQuizController(repo);
});

class UpdateLessonQuizController extends StateNotifier<AsyncValue<void>> {
  final LessonQuizRepository _repo;
  UpdateLessonQuizController(this._repo) : super(const AsyncData(null));

  Future<void> update(String id, LessonQuizUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateQuiz(id, data);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateLessonQuizProvider = StateNotifierProvider<UpdateLessonQuizController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonQuizRepositoryProvider);
  return UpdateLessonQuizController(repo);
});

class DeleteLessonQuizController extends StateNotifier<AsyncValue<void>> {
  final LessonQuizRepository _repo;
  DeleteLessonQuizController(this._repo) : super(const AsyncData(null));

  Future<void> delete(String id) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteQuiz(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final deleteLessonQuizProvider = StateNotifierProvider<DeleteLessonQuizController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lessonQuizRepositoryProvider);
  return DeleteLessonQuizController(repo);
});
