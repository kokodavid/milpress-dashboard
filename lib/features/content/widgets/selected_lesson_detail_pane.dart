import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../lesson_v2/lesson_v2_models.dart';
import '../../lesson_v2/lesson_v2_repository.dart';
import 'delete_lesson_dialog.dart';
import 'edit_lesson_dialog.dart';
import '../state/lessons_list_controller.dart';
import 'lesson_steps/step_actions.dart';
import 'lesson_steps/step_details.dart';

// ── Premium toggle colours ────────────────────────────────────────────────────
const _kPremiumColor = Color(0xFFE85D04); // matches AppColors.primaryColor

class SelectedLessonDetailPane extends ConsumerWidget {
  const SelectedLessonDetailPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLessonId = ref.watch(selectedLessonIdProvider);

    if (selectedLessonId == null) {
      return const _EmptyDetailPlaceholder();
    }

    final lessonAsync = ref.watch(lessonByIdProvider(selectedLessonId));

    return lessonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Failed to load lesson: $e'),
        ),
      ),
      data: (detail) {
        if (detail == null) return const _EmptyDetailPlaceholder();
        final lesson = detail.lesson;
        final steps = detail.steps;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MetaChip(
                              icon: Icons.list_alt,
                              label: 'Order ${lesson.displayOrder}',
                            ),
                            const SizedBox(width: 12),
                            _MetaChip(
                              icon: Icons.category,
                              label: lesson.lessonType.name,
                            ),
                            const SizedBox(width: 12),
                            if (lesson.isPremium)
                              _MetaChip(
                                icon: Icons.lock_rounded,
                                label: 'Premium',
                                color: _kPremiumColor,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Premium toggle ──────────────────────────────────
                      _PremiumToggle(lesson: lesson),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              showEditLessonDialog(
                                context: context,
                                ref: ref,
                                lesson: lesson,
                                onUpdated: () {
                                  ref.invalidate(lessonByIdProvider(lesson.id));
                                  ref.invalidate(
                                    lessonsForModuleProvider(lesson.moduleId),
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/edit_pencil.png',
                                    width: 16,
                                    height: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              showDeleteLessonDialog(
                                context: context,
                                ref: ref,
                                lesson: lesson,
                                onDeleted: () {
                                  ref.invalidate(
                                    lessonsForModuleProvider(lesson.moduleId),
                                  );
                                  ref
                                          .read(
                                            selectedLessonIdProvider.notifier,
                                          )
                                          .state =
                                      null;
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Lesson Steps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (steps.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No steps for this lesson yet.'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.go('/lessons/${lesson.id}/steps'),
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text(
                              'Continue to Steps',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else ...[
                Column(
                  children: [
                    for (final entry in steps.asMap().entries)
                      StepCard(
                        step: entry.value,
                        onEdit: () => context.go(
                          '/lessons/${lesson.id}/steps?step=${entry.key}',
                        ),
                        onDelete: () => deleteStep(
                          context,
                          ref,
                          lesson.id,
                          steps,
                          entry.key,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.go('/lessons/${lesson.id}/steps'),
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text(
                          'Continue to Steps',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'Select a lesson to view details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Colors.blueGrey.shade700;
    final bg = color != null
        ? color!.withOpacity(0.08)
        : Colors.blueGrey.shade50;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: color != null
            ? Border.all(color: color!.withOpacity(0.3))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _PremiumToggle — inline switch that flips is_premium on the lesson
// =============================================================================
class _PremiumToggle extends ConsumerStatefulWidget {
  final NewLesson lesson;
  const _PremiumToggle({required this.lesson});

  @override
  ConsumerState<_PremiumToggle> createState() => _PremiumToggleState();
}

class _PremiumToggleState extends ConsumerState<_PremiumToggle> {
  late bool _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.lesson.isPremium;
  }

  @override
  void didUpdateWidget(_PremiumToggle old) {
    super.didUpdateWidget(old);
    if (old.lesson.id != widget.lesson.id) {
      _value = widget.lesson.isPremium;
    }
  }

  Future<void> _toggle(bool next) async {
    setState(() {
      _value = next;
      _saving = true;
    });
    try {
      await ref
          .read(togglePremiumProvider.notifier)
          .toggle(widget.lesson.id, newValue: next);
      // Refresh the detail pane so the badge and chip update
      ref.invalidate(lessonByIdProvider(widget.lesson.id));
      ref.invalidate(lessonsForModuleProvider(widget.lesson.moduleId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next
                  ? '"${widget.lesson.title}" marked as Premium'
                  : '"${widget.lesson.title}" set to Free',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() => _value = !next);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update premium status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _value ? 'Mark as Free' : 'Mark as Premium',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: _value
              ? _kPremiumColor.withOpacity(0.08)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _value
                ? _kPremiumColor.withOpacity(0.4)
                : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 15,
              color: _value ? _kPremiumColor : Colors.grey.shade500,
            ),
            const SizedBox(width: 6),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _value ? _kPremiumColor : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            _saving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _value ? _kPremiumColor : Colors.grey.shade400,
                      ),
                    ),
                  )
                : Switch.adaptive(
                    value: _value,
                    onChanged: _toggle,
                    activeColor: _kPremiumColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
          ],
        ),
      ),
    );
  }
}
