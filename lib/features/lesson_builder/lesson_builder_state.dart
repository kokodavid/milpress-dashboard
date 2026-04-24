import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/widgets/lesson_steps/step_drafts.dart';
import '../lesson_v2/lesson_v2_models.dart';
import '../lesson_v2/lesson_v2_repository.dart';

// ── Publish status ────────────────────────────────────────────────────────────

enum PublishStatus { idle, publishing, published, error }

// ── Auto-save status ──────────────────────────────────────────────────────────

enum AutoSaveStatus { idle, saving, saved, error }

/// Which step card is active in the flow sidebar (0-indexed).
final lessonBuilderSelectedStepProvider =
    StateProvider.family<int, String>((ref, lessonId) => 0);

/// Tracks whether the latest save succeeded, is in-flight, etc.
final lessonBuilderSaveStatusProvider =
    StateProvider.family<AutoSaveStatus, String>(
        (ref, lessonId) => AutoSaveStatus.idle);

/// Timestamp of the last successful auto-save (used for "saved · Xs ago").
final lessonBuilderSaveTimeProvider =
    StateProvider.family<DateTime?, String>((ref, lessonId) => null);

/// Tracks the in-flight state of the Publish button for a given lesson.
final lessonBuilderPublishStatusProvider =
    StateProvider.family<PublishStatus, String>(
        (ref, lessonId) => PublishStatus.idle);

// ── Drafts notifier ───────────────────────────────────────────────────────────

class LessonDraftsNotifier extends StateNotifier<List<StepDraft>> {
  LessonDraftsNotifier({
    required this.ref,
    required this.lessonId,
    required List<StepDraft> initial,
  }) : super(initial);

  final Ref ref;
  final String lessonId;
  Timer? _debounce;

  /// Call this after mutating a draft's TextEditingControllers in place,
  /// so Riverpod sees the change and the auto-save is scheduled.
  void notifyChanged() {
    state = [...state];
    _scheduleSave();
  }

  /// Swap positions of two steps via a drag-drop reorder gesture.
  void reorderSteps(int oldIndex, int newIndex) {
    final list = [...state];
    if (newIndex > oldIndex) newIndex--;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _reindex(list);
    state = list;
    _scheduleSave();
  }

  /// Append a brand-new blank step draft.
  void addStep(StepDraft draft) {
    draft.position = state.length + 1;
    state = [...state, draft];
    _scheduleSave();
  }

  /// Remove a step by index and keep the selected index in bounds.
  void removeStep(int index) {
    final list = [...state]..removeAt(index);
    _reindex(list);
    state = list;

    final current =
        ref.read(lessonBuilderSelectedStepProvider(lessonId));
    if (current >= list.length && list.isNotEmpty) {
      ref
          .read(lessonBuilderSelectedStepProvider(lessonId).notifier)
          .state = list.length - 1;
    }
    _scheduleSave();
  }

  void _reindex(List<StepDraft> list) {
    for (var i = 0; i < list.length; i++) {
      list[i].position = i + 1;
    }
  }

  void _scheduleSave() {
    _debounce?.cancel();
    ref
        .read(lessonBuilderSaveStatusProvider(lessonId).notifier)
        .state = AutoSaveStatus.saving;
    _debounce = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _save() async {
    try {
      final inputs = state.map((d) => d.toInput()).toList();
      await ref.read(lessonV2RepositoryProvider).updateSteps(lessonId, inputs);
      ref
          .read(lessonBuilderSaveStatusProvider(lessonId).notifier)
          .state = AutoSaveStatus.saved;
      ref
          .read(lessonBuilderSaveTimeProvider(lessonId).notifier)
          .state = DateTime.now();
    } catch (_) {
      ref
          .read(lessonBuilderSaveStatusProvider(lessonId).notifier)
          .state = AutoSaveStatus.error;
    }
  }

  /// Cancels any pending auto-save debounce and immediately flushes all
  /// drafts via [publishLesson], which writes the correct [step_type] for
  /// every step including newly-added ones.
  Future<void> publish() async {
    _debounce?.cancel();
    ref
        .read(lessonBuilderPublishStatusProvider(lessonId).notifier)
        .state = PublishStatus.publishing;
    try {
      final inputs = state.map((d) => d.toInput()).toList();
      await ref.read(publishLessonProvider.notifier).publish(lessonId, inputs);
      // Keep auto-save indicator in sync.
      ref
          .read(lessonBuilderSaveStatusProvider(lessonId).notifier)
          .state = AutoSaveStatus.saved;
      ref
          .read(lessonBuilderSaveTimeProvider(lessonId).notifier)
          .state = DateTime.now();
      ref
          .read(lessonBuilderPublishStatusProvider(lessonId).notifier)
          .state = PublishStatus.published;
    } catch (_) {
      ref
          .read(lessonBuilderPublishStatusProvider(lessonId).notifier)
          .state = PublishStatus.error;
      rethrow;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/// The live list of [StepDraft]s for a given lesson, keyed by lessonId.
///
/// Initialised from [lessonByIdProvider] which is guaranteed to be cached by
/// the time the screen pre-warms this provider — ensuring existing steps are
/// always pre-populated when entering the builder from the lesson detail pane.
final lessonBuilderDraftsProvider = StateNotifierProvider.family<
    LessonDraftsNotifier, List<StepDraft>, String>((ref, lessonId) {
  final lessonAsync = ref.read(lessonByIdProvider(lessonId));
  final steps = lessonAsync.valueOrNull?.steps ?? const <LessonStep>[];
  final drafts = steps.map((s) => StepDraft.fromStep(s)).toList();
  return LessonDraftsNotifier(
    ref: ref,
    lessonId: lessonId,
    initial: drafts,
  );
});

// ── Completion helper (plain function — StepDraft is not equatable) ───────────

/// Returns a 0.0–1.0 completion ratio for the given draft based on how many
/// of its key fields are filled in. Used to drive the sidebar progress bars.
double computeStepCompletion(StepDraft draft) {
  int total = 0;
  int filled = 0;

  void check(String text) {
    total++;
    if (text.trim().isNotEmpty) filled++;
  }

  // Fields common to all step types
  check(draft.stepKeyCtrl.text);
  check(draft.titleCtrl.text);

  switch (draft.stepType) {
    case LessonStepType.introduction:
      check(draft.displayTextCtrl.text);
      check(draft.audioBaseUrlCtrl.text);
      break;

    case LessonStepType.demonstration:
      check(draft.feedbackTitleCtrl.text);
      total++;
      if (draft.imageUrlCtrls.isNotEmpty) filled++;
      break;

    case LessonStepType.blending:
      check(draft.instructionCtrl.text);
      check(draft.instructionAudioCtrl.text);
      total++;
      if (draft.blendingExamples.isNotEmpty) filled++;
      break;

    case LessonStepType.practice:
      check(draft.instructionCtrl.text);
      total++;
      if (draft.practiceItems.isNotEmpty) filled++;
      break;

    case LessonStepType.assessment:
      check(draft.promptCtrl.text);
      total++;
      if (draft.assessmentOptions.isNotEmpty) filled++;
      break;

    case LessonStepType.soundDiscrimination:
      check(draft.titleAudioCtrl.text);
      check(draft.targetSoundCtrl.text);
      total++;
      if (draft.soundDiscriminationItems.isNotEmpty) filled++;
      break;

    case LessonStepType.missingLetters:
      check(draft.missingLettersInstructionCtrl.text);
      total++;
      if (draft.missingLettersActivities.isNotEmpty) filled++;
      break;

    case LessonStepType.practiceGame:
      check(draft.practiceGameInstructionCtrl.text);
      check(draft.practiceGameTargetSoundCtrl.text);
      break;

    default:
      check(draft.instructionCtrl.text);
      break;
  }

  return total == 0 ? 0.0 : (filled / total).clamp(0.0, 1.0);
}
