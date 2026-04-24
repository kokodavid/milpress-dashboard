import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/widgets/lesson_steps/step_drafts.dart';
import '../../content/widgets/lesson_steps/step_type_picker.dart';
import '../lesson_builder_state.dart';
import '../lesson_builder_theme.dart';
import 'step_flow_card.dart';

/// Left panel of the lesson builder.
///
/// Renders the ordered list of step cards, supports drag-to-reorder,
/// and provides the "+ Add step" entry point via [showStepTypePicker].
class LessonFlowSidebar extends ConsumerWidget {
  const LessonFlowSidebar({super.key, required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(lessonBuilderDraftsProvider(lessonId));
    final activeIndex =
        ref.watch(lessonBuilderSelectedStepProvider(lessonId));

    return Column(
      children: [
        _SidebarHeader(stepCount: drafts.length),
        const Divider(height: 1, color: LessonBuilderTheme.surfaceBorder),
        Expanded(
          child: drafts.isEmpty
              ? const _EmptyState()
              : _StepList(
                  lessonId: lessonId,
                  drafts: drafts,
                  activeIndex: activeIndex,
                  ref: ref,
                ),
        ),
        const Divider(height: 1, color: LessonBuilderTheme.surfaceBorder),
        _AddStepButton(lessonId: lessonId),
      ],
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.stepCount});

  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'LESSON FLOW',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LessonBuilderTheme.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          Text(
            '$stepCount ${stepCount == 1 ? 'step' : 'steps'}',
            style: const TextStyle(
              fontSize: 11,
              color: LessonBuilderTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList({
    required this.lessonId,
    required this.drafts,
    required this.activeIndex,
    required this.ref,
  });

  final String lessonId;
  final List<StepDraft> drafts;
  final int activeIndex;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: drafts.length,
      buildDefaultDragHandles: false, // we provide our own via ReorderableDragStartListener
      proxyDecorator: _proxyDecorator,
      onReorder: (oldIndex, newIndex) => ref
          .read(lessonBuilderDraftsProvider(lessonId).notifier)
          .reorderSteps(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final draft = drafts[index];
        return StepFlowCard(
          key: ValueKey('step_card_${draft.position}_$index'),
          draft: draft,
          index: index,
          isActive: index == activeIndex,
          onTap: () => ref
              .read(lessonBuilderSelectedStepProvider(lessonId).notifier)
              .state = index,
        );
      },
    );
  }

  /// Ghost card shown while dragging — slightly elevated and semi-transparent.
  static Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        child: Opacity(opacity: 0.9, child: child),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No steps yet.\nTap "+ Add step" to get started.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: LessonBuilderTheme.textMuted,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

class _AddStepButton extends ConsumerWidget {
  const _AddStepButton({required this.lessonId});

  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _addStep(context, ref),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add step', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: LessonBuilderTheme.textDark,
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Future<void> _addStep(BuildContext context, WidgetRef ref) async {
    final picked = await showStepTypePicker(context: context);
    if (picked == null) return;

    final notifier =
        ref.read(lessonBuilderDraftsProvider(lessonId).notifier);
    final newPosition =
        ref.read(lessonBuilderDraftsProvider(lessonId)).length + 1;

    final draft = _buildDraft(picked, newPosition);
    notifier.addStep(draft);

    // Auto-select the newly added step
    ref.read(lessonBuilderSelectedStepProvider(lessonId).notifier).state =
        newPosition - 1;
  }

  static StepDraft _buildDraft(PickedStepType picked, int position) {
    if (picked is SystemPickedType) {
      final draft = StepDraft(position: position, stepKey: '');
      draft.stepType = picked.type;
      return draft;
    }

    if (picked is CustomPickedType) {
      final draft = StepDraft(position: position, stepKey: '');
      draft.setCustomType(picked.def);
      return draft;
    }

    // Unreachable — sealed class ensures exhaustive matching
    throw StateError('Unknown PickedStepType: $picked');
  }
}
