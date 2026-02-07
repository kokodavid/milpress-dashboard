import 'package:supabase_flutter/supabase_flutter.dart';

import 'lesson_v2_models.dart';
import 'lesson_v2_repository.dart';

class LessonV2RepositoryImpl implements LessonV2Repository {
  final SupabaseClient _client;

  LessonV2RepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String lessonsTable = 'new_lessons';
  static const String stepsTable = 'lesson_steps';

  @override
  Future<List<NewLesson>> fetchLessonsForModule(String moduleId) async {
    final List data = await _client
        .from(lessonsTable)
        .select()
        .eq('module_id', moduleId)
        .order('display_order', ascending: true);
    return data.map((e) => NewLesson.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<LessonWithSteps?> fetchLessonById(String lessonId) async {
    final lessonData =
        await _client.from(lessonsTable).select().eq('id', lessonId).maybeSingle();
    if (lessonData == null) return null;
    final lesson = NewLesson.fromMap(lessonData);
    final List stepsData = await _client
        .from(stepsTable)
        .select()
        .eq('lesson_id', lessonId)
        .order('position', ascending: true);
    final steps =
        stepsData.map((e) => LessonStep.fromMap(e as Map<String, dynamic>)).toList();
    return LessonWithSteps(lesson: lesson, steps: steps);
  }

  @override
  Future<NewLesson> createLessonWithSteps(
    NewLessonCreate lesson,
    List<LessonStepInput> steps,
  ) async {
    final List data =
        await _client.from(lessonsTable).insert(lesson.toInsertMap()).select();
    final created = NewLesson.fromMap(data.first as Map<String, dynamic>);
    if (steps.isNotEmpty) {
      final inserts = steps.map((s) => s.toInsertMap(created.id)).toList();
      await _client.from(stepsTable).insert(inserts);
    }
    return created;
  }

  @override
  Future<void> updateLesson(String id, NewLessonUpdate update) async {
    await _client.from(lessonsTable).update(update.toUpdateMap()).eq('id', id);
  }

  @override
  Future<void> updateSteps(String lessonId, List<LessonStepInput> steps) async {
    await _client.from(stepsTable).delete().eq('lesson_id', lessonId);
    if (steps.isEmpty) return;
    final inserts = steps.map((s) => s.toInsertMap(lessonId)).toList();
    await _client.from(stepsTable).insert(inserts);
  }

  @override
  Future<void> deleteLesson(String id) async {
    await _client.from(lessonsTable).delete().eq('id', id);
  }

  @override
  Future<void> reorderLessons(
    String moduleId,
    List<String> orderedLessonIds,
  ) async {
    if (orderedLessonIds.isEmpty) return;
    final updates = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedLessonIds.length; i++) {
      updates.add({
        'id': orderedLessonIds[i],
        'module_id': moduleId,
        'display_order': i + 1,
      });
    }
    await _client.from(lessonsTable).upsert(updates, onConflict: 'id');
  }

  @override
  Future<int> countLessons() async {
    final List data = await _client.from(lessonsTable).select('id');
    return data.length;
  }

  @override
  Future<int> countLessonsForCourse(String courseId) async {
    final List mods =
        await _client.from('modules').select('id').eq('course_id', courseId);
    if (mods.isEmpty) return 0;
    final moduleIds = mods.map((e) => (e as Map)['id']).toList();
    final inList = '(${moduleIds.map((id) => '"$id"').join(',')})';
    final List lessons = await _client
        .from(lessonsTable)
        .select('id')
        .filter('module_id', 'in', inList);
    return lessons.length;
  }
}
