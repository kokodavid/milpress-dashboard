import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lesson_models.dart';


// Query object for future flexibility (filtering, sorting, pagination)
class LessonsQuery {
  final String? moduleId;
  final String? search;
  final int? limit;
  final int? offset;
  final String? orderBy;
  final bool ascending;

  const LessonsQuery({
    this.moduleId,
    this.search,
    this.limit,
    this.offset,
    this.orderBy,
    this.ascending = true,
  });
}

class LessonsRepository {
  final SupabaseClient _client;
  LessonsRepository(this._client);

  static const String table = 'lessons';

  Future<List<Lesson>> getLessonsForModule(String moduleId) async {
    final List data = await _client
        .from(table)
        .select()
        .eq('module_id', moduleId)
        .order('position', ascending: true);
    return data.map((e) => Lesson.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Lesson?> getLessonById(String id) async {
    final data = await _client.from(table).select().eq('id', id).maybeSingle();
    if (data == null) return null;
    return Lesson.fromMap(data);
  }

  Future<Lesson> createLesson(LessonCreate input) async {
    final List data = await _client.from(table).insert(input.toInsertMap()).select();
    return Lesson.fromMap(data.first as Map<String, dynamic>);
  }

  Future<void> updateLesson(String id, LessonUpdate update) async {
    await _client.from(table).update(update.toUpdateMap()).eq('id', id);
  }

  Future<void> deleteLesson(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<int> countLessons() async {
    final List data = await _client.from(table).select('id');
    return data.length;
  }
}

final lessonsRepositoryProvider = Provider<LessonsRepository>((ref) {
  final client = Supabase.instance.client;
  return LessonsRepository(client);
});
