import 'package:flutter/material.dart';

import '../../content/widgets/lesson_steps/step_drafts.dart';
import '../../lesson_v2/lesson_v2_models.dart';
import '../lesson_builder_state.dart';
import '../lesson_builder_theme.dart';

/// A single step card in the Lesson Flow sidebar.
///
/// Shows: drag handle · position badge · type icon · title/key · completion bar.
/// Active card gets an orange left border and tinted background.
///
/// Must be wrapped in a [ReorderableListView] child with a [ValueKey].
class StepFlowCard extends StatelessWidget {
  const StepFlowCard({
    super.key,
    required this.draft,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  final StepDraft draft;
  final int index;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: _cardDecoration(isActive),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActiveBar(isActive: isActive),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardHeader(draft: draft, index: index),
                    const SizedBox(height: 6),
                    _CompletionBar(completion: computeStepCompletion(draft)),
                  ],
                ),
              ),
            ),
            // Drag handle — wired to ReorderableListView
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: isActive
                      ? LessonBuilderTheme.primary
                      : LessonBuilderTheme.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _cardDecoration(bool active) => BoxDecoration(
        color: active
            ? LessonBuilderTheme.primaryLight
            : LessonBuilderTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? LessonBuilderTheme.primary
              : LessonBuilderTheme.surfaceBorder,
          width: active ? 1.5 : 1,
        ),
      );
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

/// Thin orange left bar shown only on the active card.
class _ActiveBar extends StatelessWidget {
  const _ActiveBar({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? LessonBuilderTheme.primary : Colors.transparent,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
      ),
    );
  }
}

/// Position badge + type icon badge + step label row.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.draft, required this.index});

  final StepDraft draft;
  final int index;

  @override
  Widget build(BuildContext context) {
    final category = draft.customStepType != null
        ? 'Custom'
        : draft.stepType.category;
    final accent = LessonBuilderTheme.categoryAccent(category);
    final bg = LessonBuilderTheme.categoryBackground(category);
    final icon = draft.customStepType != null
        ? Icons.extension
        : draft.stepType.icon;
    final label = _stepLabel(draft);
    final sublabel = _stepSublabel(draft);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Position badge
        _Badge(
          label: '${index + 1}',
          color: accent,
          background: bg,
        ),
        const SizedBox(width: 8),
        // Type icon badge
        _IconBadge(icon: icon, color: accent, background: bg),
        const SizedBox(width: 8),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (sublabel.isNotEmpty)
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: LessonBuilderTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Primary label: title if filled, else step key, else type name.
  static String _stepLabel(StepDraft draft) {
    final title = draft.titleCtrl.text.trim();
    if (title.isNotEmpty) return title;
    final key = draft.stepKeyCtrl.text.trim();
    if (key.isNotEmpty) return key;
    if (draft.customStepType != null) return draft.customStepType!.displayName;
    return draft.stepType.displayName;
  }

  /// Subtitle: step key when we're already showing the title above.
  static String _stepSublabel(StepDraft draft) {
    final title = draft.titleCtrl.text.trim();
    if (title.isEmpty) return '';
    return draft.stepKeyCtrl.text.trim();
  }
}

/// Small rounded square with a number.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Small rounded square with an icon.
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}

/// Thin coloured progress bar for completion %.
class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.completion});

  final double completion;

  @override
  Widget build(BuildContext context) {
    final color = completion >= 1.0
        ? Colors.green.shade400
        : LessonBuilderTheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: completion,
        minHeight: 3,
        backgroundColor: LessonBuilderTheme.surfaceBorder,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
