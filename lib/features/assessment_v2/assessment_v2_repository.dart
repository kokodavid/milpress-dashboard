import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/features/auth/admin_activity_repository.dart';
import 'package:milpress_dashboard/features/auth/activity_actions.dart';

import 'models/course_assessment_model.dart';
import 'models/assessment_level_model.dart';
import 'models/assessment_sublevel_model.dart';
import 'models/assessment_v2_progress_model.dart';
import 'assessment_v2_repository_impl.dart';

// ===========================================================================
// Abstract interface
// ===========================================================================

abstract class AssessmentV2Repository {
  // -- Assessments --
  Future<List<CourseAssessment>> fetchAllAssessments();
  Future<CourseAssessment?> fetchAssessmentById(String id);
  Future<CourseAssessment?> fetchAssessmentByCourseId(String courseId);
  Future<CourseAssessment> createAssessment(CourseAssessmentCreate data);
  Future<void> updateAssessment(String id, CourseAssessmentUpdate data);
  Future<void> deleteAssessment(String id);
  Future<int> countAssessments();

  // -- Levels --
  Future<List<AssessmentLevel>> fetchLevelsForAssessment(String assessmentId);
  Future<AssessmentLevel> createLevel(AssessmentLevelCreate data);
  Future<void> updateLevel(String id, AssessmentLevelUpdate data);
  Future<void> deleteLevel(String id);
  Future<void> reorderLevels(String assessmentId, List<String> orderedIds);

  // -- Sublevels --
  Future<List<AssessmentSublevel>> fetchSublevelsForLevel(String levelId);
  Future<AssessmentSublevel> createSublevel(AssessmentSublevelCreate data);
  Future<void> updateSublevel(String id, AssessmentSublevelUpdate data);
  Future<void> deleteSublevel(String id);
  Future<void> reorderSublevels(String levelId, List<String> orderedIds);

  // -- Progress --
  Future<List<AssessmentV2Progress>> fetchProgressForAssessment(String assessmentId);
  Future<List<AssessmentV2Progress>> fetchProgressForUser(String userId);
  Future<void> resetProgressForUser(String userId, String assessmentId);
}

// ===========================================================================
// Repository provider
// ===========================================================================

final assessmentV2RepositoryProvider = Provider<AssessmentV2Repository>((ref) {
  return AssessmentV2RepositoryImpl();
});

// ===========================================================================
// Read providers
// ===========================================================================

final allAssessmentsProvider =
    FutureProvider<List<CourseAssessment>>((ref) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.fetchAllAssessments();
});

final assessmentByIdProvider =
    FutureProvider.family<CourseAssessment?, String>((ref, id) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.fetchAssessmentById(id);
});

final assessmentByCourseIdProvider =
    FutureProvider.family<CourseAssessment?, String>((ref, courseId) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.fetchAssessmentByCourseId(courseId);
});

final levelsForAssessmentProvider =
    FutureProvider.family<List<AssessmentLevel>, String>(
        (ref, assessmentId) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.fetchLevelsForAssessment(assessmentId);
});

final sublevelsForLevelProvider =
    FutureProvider.family<List<AssessmentSublevel>, String>(
        (ref, levelId) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.fetchSublevelsForLevel(levelId);
});

final progressForAssessmentProvider =
    FutureProvider.family<List<AssessmentV2Progress>, String>(
        (ref, assessmentId) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.fetchProgressForAssessment(assessmentId);
});

final progressForUserProvider =
    FutureProvider.family<List<AssessmentV2Progress>, String>(
        (ref, userId) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.fetchProgressForUser(userId);
});

final assessmentsCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.read(assessmentV2RepositoryProvider);
  return repo.countAssessments();
});

// ===========================================================================
// Mutation controllers — Assessments
// ===========================================================================

class SaveAssessmentController
    extends StateNotifier<AsyncValue<CourseAssessment?>> {
  final AssessmentV2Repository _repo;
  final Ref _ref;

  SaveAssessmentController(this._repo, this._ref)
      : super(const AsyncData<CourseAssessment?>(null));

  Future<CourseAssessment?> create(CourseAssessmentCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createAssessment(data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentV2Created,
        targetType: 'course_assessment',
        targetId: created.id,
        details: {
          'course_id': created.courseId,
          'title': created.title,
        },
      );
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> update(String id, CourseAssessmentUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateAssessment(id, data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentV2Updated,
        targetType: 'course_assessment',
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

final saveAssessmentProvider = StateNotifierProvider<SaveAssessmentController,
    AsyncValue<CourseAssessment?>>((ref) {
  final repo = ref.watch(assessmentV2RepositoryProvider);
  return SaveAssessmentController(repo, ref);
});

class DeleteAssessmentController extends StateNotifier<AsyncValue<void>> {
  final AssessmentV2Repository _repo;
  final Ref _ref;

  DeleteAssessmentController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> delete(String id, {Map<String, dynamic>? details}) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteAssessment(id);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentV2Deleted,
        targetType: 'course_assessment',
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

final deleteAssessmentProvider =
    StateNotifierProvider<DeleteAssessmentController, AsyncValue<void>>((ref) {
  final repo = ref.watch(assessmentV2RepositoryProvider);
  return DeleteAssessmentController(repo, ref);
});

// ===========================================================================
// Mutation controllers — Levels
// ===========================================================================

class SaveLevelController
    extends StateNotifier<AsyncValue<AssessmentLevel?>> {
  final AssessmentV2Repository _repo;
  final Ref _ref;

  SaveLevelController(this._repo, this._ref)
      : super(const AsyncData<AssessmentLevel?>(null));

  Future<AssessmentLevel?> create(AssessmentLevelCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createLevel(data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentLevelCreated,
        targetType: 'assessment_level',
        targetId: created.id,
        details: {
          'assessment_id': created.assessmentId,
          'title': created.title,
          'display_order': created.displayOrder,
        },
      );
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> update(String id, AssessmentLevelUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateLevel(id, data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentLevelUpdated,
        targetType: 'assessment_level',
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

final saveLevelProvider =
    StateNotifierProvider<SaveLevelController, AsyncValue<AssessmentLevel?>>(
        (ref) {
  final repo = ref.watch(assessmentV2RepositoryProvider);
  return SaveLevelController(repo, ref);
});

class DeleteLevelController extends StateNotifier<AsyncValue<void>> {
  final AssessmentV2Repository _repo;
  final Ref _ref;

  DeleteLevelController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> delete(String id, {Map<String, dynamic>? details}) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteLevel(id);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentLevelDeleted,
        targetType: 'assessment_level',
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

final deleteLevelProvider =
    StateNotifierProvider<DeleteLevelController, AsyncValue<void>>((ref) {
  final repo = ref.watch(assessmentV2RepositoryProvider);
  return DeleteLevelController(repo, ref);
});

// ===========================================================================
// Mutation controllers — Sublevels
// ===========================================================================

class SaveSublevelController
    extends StateNotifier<AsyncValue<AssessmentSublevel?>> {
  final AssessmentV2Repository _repo;
  final Ref _ref;

  SaveSublevelController(this._repo, this._ref)
      : super(const AsyncData<AssessmentSublevel?>(null));

  Future<AssessmentSublevel?> create(AssessmentSublevelCreate data) async {
    state = const AsyncLoading();
    try {
      final created = await _repo.createSublevel(data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentSublevelCreated,
        targetType: 'assessment_sublevel',
        targetId: created.id,
        details: {
          'level_id': created.levelId,
          'title': created.title,
          'display_order': created.displayOrder,
          'questions_count': created.questions.length,
          'passing_score': created.passingScore,
        },
      );
      state = AsyncData(created);
      return created;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> update(String id, AssessmentSublevelUpdate data) async {
    state = const AsyncLoading();
    try {
      await _repo.updateSublevel(id, data);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentSublevelUpdated,
        targetType: 'assessment_sublevel',
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

final saveSublevelProvider = StateNotifierProvider<SaveSublevelController,
    AsyncValue<AssessmentSublevel?>>((ref) {
  final repo = ref.watch(assessmentV2RepositoryProvider);
  return SaveSublevelController(repo, ref);
});

class DeleteSublevelController extends StateNotifier<AsyncValue<void>> {
  final AssessmentV2Repository _repo;
  final Ref _ref;

  DeleteSublevelController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> delete(String id, {Map<String, dynamic>? details}) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteSublevel(id);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentSublevelDeleted,
        targetType: 'assessment_sublevel',
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

final deleteSublevelProvider =
    StateNotifierProvider<DeleteSublevelController, AsyncValue<void>>((ref) {
  final repo = ref.watch(assessmentV2RepositoryProvider);
  return DeleteSublevelController(repo, ref);
});

// ===========================================================================
// Progress reset controller
// ===========================================================================

class ResetProgressController extends StateNotifier<AsyncValue<void>> {
  final AssessmentV2Repository _repo;
  final Ref _ref;

  ResetProgressController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> reset(String userId, String assessmentId) async {
    state = const AsyncLoading();
    try {
      await _repo.resetProgressForUser(userId, assessmentId);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.assessmentV2Updated,
        targetType: 'assessment_v2_progress',
        targetId: assessmentId,
        details: {
          'user_id': userId,
          'action': 'progress_reset',
        },
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final resetProgressProvider =
    StateNotifierProvider<ResetProgressController, AsyncValue<void>>((ref) {
  final repo = ref.watch(assessmentV2RepositoryProvider);
  return ResetProgressController(repo, ref);
});
