import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../lesson_v2/lesson_v2_repository.dart';
import 'delete_lesson_dialog.dart';
import 'edit_lesson_dialog.dart';
import '../state/lessons_list_controller.dart';
import '../../../widgets/app_button.dart';
import 'lesson_steps/step_actions.dart';
import 'lesson_steps/step_details.dart';
import 'lesson_steps/step_dialogs.dart';

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
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                                      .read(selectedLessonIdProvider.notifier)
                                      .state = null;
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
                    const Text('No steps for this lesson'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 160,
                      height: 36,
                      child: AppButton(
                        label: 'Create Steps',
                        backgroundColor: AppColors.primaryColor,
                        onPressed: () async {
                          final created = await showCreateLessonStepsDialog(
                            context: context,
                            ref: ref,
                            lessonId: lesson.id,
                            initialSteps: steps,
                          );
                          if (created == true) {
                            ref.invalidate(lessonByIdProvider(lesson.id));
                          }
                        },
                      ),
                    ),
                  ],
                )
              else ...[
                Column(
                  children: [
                    for (final entry in steps.asMap().entries)
                      StepCard(
                        step: entry.value,
                        onEdit: () => editStep(
                          context,
                          ref,
                          lesson.id,
                          steps,
                          entry.key,
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
                if (steps.length < 4) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 180,
                    height: 36,
                    child: AppButton(
                      label: 'Add More Steps',
                      backgroundColor: AppColors.primaryColor,
                      onPressed: () async {
                        final created = await showCreateLessonStepsDialog(
                          context: context,
                          ref: ref,
                          lessonId: lesson.id,
                          initialSteps: steps,
                        );
                        if (created == true) {
                          ref.invalidate(lessonByIdProvider(lesson.id));
                        }
                      },
                    ),
                  ),
                ],
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
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade700,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
