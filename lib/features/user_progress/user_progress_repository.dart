import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_progress_models.dart';

class UserProgressRepository {
  final SupabaseClient _client;
  UserProgressRepository(this._client);

  static const courseProgressTable = 'course_progress';
  static const moduleProgressTable = 'module_progress';
  static const lessonProgressTable = 'lesson_progress';

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
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return data.map((e) => LessonProgress.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }
}

// Providers
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
