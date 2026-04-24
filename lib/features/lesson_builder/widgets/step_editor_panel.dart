import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/widgets/lesson_steps/step_drafts.dart';
import '../../content/widgets/lesson_steps/step_type_form_sections.dart';
import '../../lesson_v2/lesson_v2_models.dart';
import '../lesson_builder_state.dart';
import '../lesson_builder_theme.dart';

/// Centre panel of the lesson builder.
///
/// Renders an inline, scrollable editor for the currently active [StepDraft].
/// The step key / required toggle are rendered here; all other field layout
/// is delegated to [buildLessonStepTypeFields] so no form logic is duplicated.
class StepEditorPanel extends ConsumerStatefulWidget {
  const StepEditorPanel({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<StepEditorPanel> createState() => _StepEditorPanelState();
}

class _StepEditorPanelState extends ConsumerState<StepEditorPanel> {
  // Controllers for the step-key field (owned here, not inside the draft,
  // so we can attach an onChanged hook for auto-save triggering).
  // We keep a reference to the last active draft to detect when to re-sync.
  StepDraft? _lastDraft;

  LessonDraftsNotifier get _notifier =>
      ref.read(lessonBuilderDraftsProvider(widget.lessonId).notifier);

  /// Passed to [buildLessonStepTypeFields] — fires on every list mutation
  /// (add / remove phoneme, example, option, …) inside the form.
  void _setStateAndNotify(VoidCallback fn) {
    setState(fn);
    _notifier.notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final drafts = ref.watch(lessonBuilderDraftsProvider(widget.lessonId));
    final activeIndex = ref.watch(
      lessonBuilderSelectedStepProvider(widget.lessonId),
    );

    if (drafts.isEmpty) return const _EmptyEditor();
    final safeIndex = activeIndex.clamp(0, drafts.length - 1);
    final draft = drafts[safeIndex];

    // Detect draft switch so Riverpod's watch refreshes the form.
    if (_lastDraft != draft) _lastDraft = draft;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelHeader(
              draft: draft,
              stepIndex: safeIndex,
              totalSteps: drafts.length,
              onRemove: () => _notifier.removeStep(safeIndex),
            ),
            const SizedBox(height: 16),
            _StepMeta(draft: draft),
            const SizedBox(height: 20),
            _StepKeySection(
              draft: draft,
              onStepKeyChanged: (_) => _notifier.notifyChanged(),
              onRequiredToggled: (value) {
                setState(() => draft.required = value);
                _notifier.notifyChanged();
              },
            ),
            const SizedBox(height: 20),
            _FormSection(
              label: 'Step Configuration',
              child: buildLessonStepTypeFields(
                context: context,
                step: draft,
                setState: _setStateAndNotify,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ───────────────────────────────────────────────────────────

/// Top row: category pill · step count · remove button.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.draft,
    required this.stepIndex,
    required this.totalSteps,
    required this.onRemove,
  });

  final StepDraft draft;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final category = draft.customStepType != null
        ? 'Custom'
        : draft.stepType.category;
    final accent = LessonBuilderTheme.categoryAccent(category);
    final bg = LessonBuilderTheme.categoryBackground(category);

    return Row(
      children: [
        _CategoryPill(label: category, accent: accent, background: bg),
        const SizedBox(width: 12),
        Text(
          'Step ${stepIndex + 1} of $totalSteps',
          style: const TextStyle(
            fontSize: 13,
            color: LessonBuilderTheme.textMuted,
          ),
        ),
        const Spacer(),
        _RemoveButton(onRemove: onRemove),
      ],
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.accent,
    required this.background,
  });

  final String label;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _confirmRemove(context),
      icon: const Icon(Icons.delete_outline, size: 16),
      label: const Text('Remove', style: TextStyle(fontSize: 13)),
      style: TextButton.styleFrom(
        foregroundColor: Colors.red.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove step?'),
        content: const Text(
          'This step will be removed from the lesson flow. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) onRemove();
    });
  }
}

/// Step type name (large) + description subtitle.
class _StepMeta extends StatelessWidget {
  const _StepMeta({required this.draft});

  final StepDraft draft;

  @override
  Widget build(BuildContext context) {
    final name =
        draft.customStepType?.displayName ?? draft.stepType.displayName;
    final description = draft.customStepType?.description.isNotEmpty == true
        ? draft.customStepType!.description
        : draft.stepType.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
            height: 1.2,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: LessonBuilderTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Step key text field + Required toggle, side by side.
class _StepKeySection extends StatelessWidget {
  const _StepKeySection({
    required this.draft,
    required this.onStepKeyChanged,
    required this.onRequiredToggled,
  });

  final StepDraft draft;
  final ValueChanged<String> onStepKeyChanged;
  final ValueChanged<bool> onRequiredToggled;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel(text: 'Step key', required: true),
              const SizedBox(height: 6),
              TextFormField(
                controller: draft.stepKeyCtrl,
                onChanged: onStepKeyChanged,
                decoration: _inputDecoration('e.g. blend_cat'),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Unique identifier used by the mobile app',
                style: TextStyle(
                  fontSize: 11,
                  color: LessonBuilderTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _RequiredToggle(value: draft.required, onChanged: onRequiredToggled),
      ],
    );
  }
}

class _RequiredToggle extends StatelessWidget {
  const _RequiredToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? LessonBuilderTheme.primaryLight : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? LessonBuilderTheme.primary.withOpacity(0.4)
              : LessonBuilderTheme.surfaceBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value ? 'Required' : 'Optional',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: value
                      ? LessonBuilderTheme.primary
                      : LessonBuilderTheme.textMuted,
                ),
              ),
              Text(
                value ? 'Learner must complete' : 'Learner can skip',
                style: const TextStyle(
                  fontSize: 10,
                  color: LessonBuilderTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: LessonBuilderTheme.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// Wraps [child] in a labelled white card — used for the step configuration form.
class _FormSection extends StatelessWidget {
  const _FormSection({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LessonBuilderTheme.textDark,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: LessonBuilderTheme.surfaceBorder),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// Shown when the lesson has no steps yet.
class _EmptyEditor extends StatelessWidget {
  const _EmptyEditor();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No step selected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: LessonBuilderTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a step using the panel on the left.',
            style: TextStyle(fontSize: 13, color: LessonBuilderTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: LessonBuilderTheme.textDark,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: LessonBuilderTheme.primary,
            ),
          ),
      ],
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: LessonBuilderTheme.surfaceBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: LessonBuilderTheme.surfaceBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: const BorderSide(color: LessonBuilderTheme.primary, width: 1.5),
  ),
);
