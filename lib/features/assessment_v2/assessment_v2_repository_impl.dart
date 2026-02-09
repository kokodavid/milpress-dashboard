import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/course_assessment_model.dart';
import 'models/assessment_level_model.dart';
import 'models/assessment_sublevel_model.dart';
import 'models/assessment_v2_progress_model.dart';
import 'assessment_v2_repository.dart';

class AssessmentV2RepositoryImpl implements AssessmentV2Repository {
  final SupabaseClient _client;

  AssessmentV2RepositoryImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  static const String assessmentsTable = 'course_assessments';
  static const String levelsTable = 'assessment_levels';
  static const String sublevelsTable = 'assessment_sublevels';
  static const String progressTable = 'assessment_v2_progress';

  // =========================================================================
  // Assessments
  // =========================================================================

  @override
  Future<List<CourseAssessment>> fetchAllAssessments() async {
    final List data = await _client
        .from(assessmentsTable)
        .select()
        .order('created_at', ascending: false);
    return data
        .map((e) => CourseAssessment.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CourseAssessment?> fetchAssessmentById(String id) async {
    final data = await _client
        .from(assessmentsTable)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return CourseAssessment.fromMap(data);
  }

  @override
  Future<CourseAssessment?> fetchAssessmentByCourseId(String courseId) async {
    final data = await _client
        .from(assessmentsTable)
        .select()
        .eq('course_id', courseId)
        .maybeSingle();
    if (data == null) return null;
    return CourseAssessment.fromMap(data);
  }

  @override
  Future<CourseAssessment> createAssessment(CourseAssessmentCreate data) async {
    final List result = await _client
        .from(assessmentsTable)
        .insert(data.toInsertMap())
        .select();
    return CourseAssessment.fromMap(result.first as Map<String, dynamic>);
  }

  @override
  Future<void> updateAssessment(String id, CourseAssessmentUpdate data) async {
    await _client
        .from(assessmentsTable)
        .update(data.toUpdateMap())
        .eq('id', id);
  }

  @override
  Future<void> deleteAssessment(String id) async {
    await _client.from(assessmentsTable).delete().eq('id', id);
  }

  @override
  Future<int> countAssessments() async {
    final List data = await _client.from(assessmentsTable).select('id');
    return data.length;
  }

  // =========================================================================
  // Levels
  // =========================================================================

  @override
  Future<List<AssessmentLevel>> fetchLevelsForAssessment(
      String assessmentId) async {
    final List data = await _client
        .from(levelsTable)
        .select()
        .eq('assessment_id', assessmentId)
        .order('display_order', ascending: true);
    return data
        .map((e) => AssessmentLevel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AssessmentLevel> createLevel(AssessmentLevelCreate data) async {
    final List result =
        await _client.from(levelsTable).insert(data.toInsertMap()).select();
    return AssessmentLevel.fromMap(result.first as Map<String, dynamic>);
  }

  @override
  Future<void> updateLevel(String id, AssessmentLevelUpdate data) async {
    await _client.from(levelsTable).update(data.toUpdateMap()).eq('id', id);
  }

  @override
  Future<void> deleteLevel(String id) async {
    await _client.from(levelsTable).delete().eq('id', id);
  }

  @override
  Future<void> reorderLevels(
      String assessmentId, List<String> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final updates = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedIds.length; i++) {
      updates.add({
        'id': orderedIds[i],
        'assessment_id': assessmentId,
        'display_order': i + 1,
      });
    }
    await _client.from(levelsTable).upsert(updates, onConflict: 'id');
  }

  // =========================================================================
  // Sublevels
  // =========================================================================

  @override
  Future<List<AssessmentSublevel>> fetchSublevelsForLevel(
      String levelId) async {
    final List data = await _client
        .from(sublevelsTable)
        .select()
        .eq('level_id', levelId)
        .order('display_order', ascending: true);
    return data
        .map((e) => AssessmentSublevel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AssessmentSublevel> createSublevel(
      AssessmentSublevelCreate data) async {
    final List result =
        await _client.from(sublevelsTable).insert(data.toInsertMap()).select();
    return AssessmentSublevel.fromMap(result.first as Map<String, dynamic>);
  }

  @override
  Future<void> updateSublevel(String id, AssessmentSublevelUpdate data) async {
    await _client.from(sublevelsTable).update(data.toUpdateMap()).eq('id', id);
  }

  @override
  Future<void> deleteSublevel(String id) async {
    await _client.from(sublevelsTable).delete().eq('id', id);
  }

  @override
  Future<void> reorderSublevels(
      String levelId, List<String> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final updates = <Map<String, dynamic>>[];
    for (var i = 0; i < orderedIds.length; i++) {
      updates.add({
        'id': orderedIds[i],
        'level_id': levelId,
        'display_order': i + 1,
      });
    }
    await _client.from(sublevelsTable).upsert(updates, onConflict: 'id');
  }

  // =========================================================================
  // Progress
  // =========================================================================

  @override
  Future<List<AssessmentV2Progress>> fetchProgressForAssessment(
      String assessmentId) async {
    final List data = await _client
        .from(progressTable)
        .select()
        .eq('assessment_id', assessmentId)
        .order('created_at', ascending: true);
    return data
        .map((e) => AssessmentV2Progress.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AssessmentV2Progress>> fetchProgressForUser(
      String userId) async {
    final List data = await _client
        .from(progressTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return data
        .map((e) => AssessmentV2Progress.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> resetProgressForUser(
      String userId, String assessmentId) async {
    await _client
        .from(progressTable)
        .delete()
        .eq('user_id', userId)
        .eq('assessment_id', assessmentId);
  }
}
