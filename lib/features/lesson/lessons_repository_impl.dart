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

  Future<int> countLessonsForCourse(String courseId) async {
    // Fetch module ids for the course
    final List mods = await _client.from('modules').select('id').eq('course_id', courseId);
    if (mods.isEmpty) return 0;
    final moduleIds = mods.map((e) => (e as Map)['id']).toList();
    // Count lessons whose module_id is in those modules
  // Build Postgrest IN() filter string: ("id1","id2",...)
  final inList = '(${moduleIds.map((id) => '"$id"').join(',')})';
  final List lessons = await _client
    .from(table)
    .select('id')
    .filter('module_id', 'in', inList);
    return lessons.length;
  }
}

final lessonsRepositoryProvider = Provider<LessonsRepository>((ref) {
  final client = Supabase.instance.client;
  return LessonsRepository(client);
});
