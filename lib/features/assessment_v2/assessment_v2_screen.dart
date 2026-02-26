import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../course/course_repository.dart';
import 'assessment_v2_repository.dart';
import 'create_assessment_form.dart';
import 'create_level_form.dart';
import 'create_sublevel_form.dart';
import 'edit_level_form.dart';
import 'edit_sublevel_form.dart';
import 'models/assessment_level_model.dart';
import 'models/assessment_sublevel_model.dart';
import 'state/assessment_v2_screen_controller.dart';

class AssessmentV2Screen extends ConsumerWidget {
  const AssessmentV2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Left pane – course selector + levels list
          SizedBox(
            width: 380,
            child: Column(
              children: [
                // Course selection card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select course',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          const _AssessmentCourseDropdown(),
                        ],
                      ),
                    ),
                  ),
                ),
                // Levels list card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Levels',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Expanded(child: _LevelsListPane()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right pane – detail
          const Expanded(child: _AssessmentDetailPane()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Course dropdown (assessment-specific state)
// ---------------------------------------------------------------------------

class _AssessmentCourseDropdown extends ConsumerWidget {
  const _AssessmentCourseDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const query = CoursesQuery(limit: 100, orderBy: 'title', ascending: true);
    final coursesAsync = ref.watch(coursesListProvider(query));
    final selectedId = ref.watch(assessmentSelectedCourseIdProvider);

    return coursesAsync.when(
      data: (courses) {
        final items = courses
            .map(
              (c) => DropdownMenuItem<String>(
                value: c.id,
                child: Text(c.title, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList();

        return DropdownButtonFormField<String>(
          initialValue: selectedId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          hint: const Text('Select course'),
          items: items,
          onChanged: (value) {
            ref.read(assessmentSelectedCourseIdProvider.notifier).state = value;
            ref.read(selectedLevelIdProvider.notifier).state = null;
            ref.read(selectedSublevelIdProvider.notifier).state = null;
          },
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: const Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading courses…'),
          ],
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            const Expanded(child: Text('Failed to load courses')),
            TextButton.icon(
              onPressed: () => ref.refresh(coursesListProvider(query)),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Levels list – shows levels for the selected course's assessment
// ---------------------------------------------------------------------------

class _LevelsListPane extends ConsumerStatefulWidget {
  const _LevelsListPane();

  @override
  ConsumerState<_LevelsListPane> createState() => _LevelsListPaneState();
}

class _LevelsListPaneState extends ConsumerState<_LevelsListPane> {
  final Set<String> _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final courseId = ref.watch(assessmentSelectedCourseIdProvider);
    if (courseId == null) {
      return const Center(
        child: Text(
          'Select a course to view assessment levels',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final assessmentAsync = ref.watch(assessmentByCourseIdProvider(courseId));

    return assessmentAsync.when(
      data: (assessment) {
        if (assessment == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No assessment for this course',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Dialog(
                            insetPadding: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: CreateAssessmentForm(
                                onCreated: () {
                                  ref.invalidate(allAssessmentsProvider);
                                  ref.invalidate(
                                    assessmentByCourseIdProvider(courseId),
                                  );
                                  ref
                                          .read(
                                            selectedLevelIdProvider.notifier,
                                          )
                                          .state =
                                      null;
                                  ref
                                          .read(
                                            selectedSublevelIdProvider.notifier,
                                          )
                                          .state =
                                      null;
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Assessment created'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Assessment'),
                ),
              ],
            ),
          );
        }

        // We have an assessment – show its levels
        final levelsAsync = ref.watch(
          levelsForAssessmentProvider(assessment.id),
        );

        return levelsAsync.when(
          data: (levels) {
            final maxDisplayOrder = levels.isEmpty
                ? 0
                : levels
                      .map((level) => level.displayOrder)
                      .reduce((a, b) => a > b ? a : b);
            final nextDisplayOrder = maxDisplayOrder + 1;

            void openCreateLevelDialog() {
              showDialog(
                context: context,
                builder: (_) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Dialog(
                      insetPadding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: CreateLevelForm(
                          assessmentId: assessment.id,
                          initialDisplayOrder: nextDisplayOrder,
                          onCreated: (createdLevel) {
                            ref.invalidate(
                              levelsForAssessmentProvider(assessment.id),
                            );
                            ref.read(selectedLevelIdProvider.notifier).state =
                                createdLevel.id;
                            ref
                                    .read(selectedSublevelIdProvider.notifier)
                                    .state =
                                null;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Level created')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            void openEditLevelDialog(AssessmentLevel level) {
              showDialog(
                context: context,
                builder: (_) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Dialog(
                      insetPadding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: EditLevelForm(
                          level: level,
                          onUpdated: () {
                            ref.invalidate(
                              levelsForAssessmentProvider(assessment.id),
                            );
                            ref.read(selectedLevelIdProvider.notifier).state =
                                level.id;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Level updated')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            Future<void> deleteLevel(AssessmentLevel level) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete level'),
                  content: Text(
                    'Delete "${level.title}" and all its sublevels?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;

              try {
                await ref
                    .read(deleteLevelProvider.notifier)
                    .delete(
                      level.id,
                      details: {
                        'assessment_id': assessment.id,
                        'title': level.title,
                        'display_order': level.displayOrder,
                      },
                    );
                ref.invalidate(levelsForAssessmentProvider(assessment.id));
                ref.invalidate(sublevelsForLevelProvider(level.id));

                if (ref.read(selectedLevelIdProvider) == level.id) {
                  ref.read(selectedLevelIdProvider.notifier).state = null;
                  ref.read(selectedSublevelIdProvider.notifier).state = null;
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Level deleted')));
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete level: $e')),
                );
              }
            }

            if (levels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'No levels yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: openCreateLevelDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Level'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: levels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final isExpanded = _expanded.contains(level.id);

                      return _LevelCard(
                        level: level,
                        isExpanded: isExpanded,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            if (expanded) {
                              _expanded.add(level.id);
                            } else {
                              _expanded.remove(level.id);
                            }
                          });

                          if (expanded) {
                            if (ref.read(selectedLevelIdProvider) != level.id) {
                              ref
                                      .read(selectedSublevelIdProvider.notifier)
                                      .state =
                                  null;
                            }
                            ref.read(selectedLevelIdProvider.notifier).state =
                                level.id;
                          } else if (ref.read(selectedLevelIdProvider) ==
                              level.id) {
                            ref.read(selectedLevelIdProvider.notifier).state =
                                null;
                            ref
                                    .read(selectedSublevelIdProvider.notifier)
                                    .state =
                                null;
                          }
                        },
                        onEdit: () => openEditLevelDialog(level),
                        onDelete: () => deleteLevel(level),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: openCreateLevelDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Level'),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ---------------------------------------------------------------------------
// Level card
// ---------------------------------------------------------------------------

class _LevelCard extends ConsumerWidget {
  const _LevelCard({
    required this.level,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final AssessmentLevel level;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSublevelId = ref.watch(selectedSublevelIdProvider);
    final sublevelsAsync = ref.watch(sublevelsForLevelProvider(level.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('assessment-level-${level.id}'),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF16355C),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${level.displayOrder}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(level.title),
          subtitle: sublevelsAsync.when(
            data: (sublevels) {
              if (sublevels.isEmpty) return const Text('No sublevels');
              if (sublevels.length == 1) {
                return Text('${sublevels.first.title} • 1 sublevel');
              }
              return Text('${sublevels.length} sublevels');
            },
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Error loading sublevels'),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit level',
                color: Colors.blueGrey.shade600,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete level',
                color: Colors.red.shade400,
                onPressed: onDelete,
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ],
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            sublevelsAsync.when(
              data: (sublevels) {
                final maxDisplayOrder = sublevels.isEmpty
                    ? 0
                    : sublevels
                          .map((sublevel) => sublevel.displayOrder)
                          .reduce((a, b) => a > b ? a : b);
                final nextDisplayOrder = maxDisplayOrder + 1;

                Future<void> openCreateSublevelDialog() async {
                  final created = await showDialog<bool>(
                    context: context,
                    builder: (_) => Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: Dialog(
                          insetPadding: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: CreateSublevelForm(
                              levelId: level.id,
                              initialDisplayOrder: nextDisplayOrder,
                              onCreated: (createdSublevel) {
                                ref.invalidate(
                                  sublevelsForLevelProvider(level.id),
                                );
                                ref
                                        .read(selectedLevelIdProvider.notifier)
                                        .state =
                                    level.id;
                                ref
                                    .read(selectedSublevelIdProvider.notifier)
                                    .state = createdSublevel
                                    .id;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                  if (created == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sublevel created')),
                    );
                  }
                }

                return Column(
                  children: [
                    if (sublevels.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No sublevels in this level'),
                      )
                    else
                      ...sublevels.map(
                        (sublevel) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InlineSublevelCard(
                            sublevel: sublevel,
                            isSelected: selectedSublevelId == sublevel.id,
                            onTap: () {
                              ref.read(selectedLevelIdProvider.notifier).state =
                                  level.id;
                              ref
                                      .read(selectedSublevelIdProvider.notifier)
                                      .state =
                                  sublevel.id;
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: openCreateSublevelDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Sublevel'),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineSublevelCard extends StatelessWidget {
  const _InlineSublevelCard({
    required this.sublevel,
    required this.isSelected,
    required this.onTap,
  });

  final AssessmentSublevel sublevel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Text(sublevel.title),
        subtitle: Text(
          'Pass ${sublevel.passingScore}% • ${sublevel.questions.length} question${sublevel.questions.length == 1 ? '' : 's'}',
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right-side detail pane – shows sublevels for the selected level
// ---------------------------------------------------------------------------

class _AssessmentDetailPane extends ConsumerWidget {
  const _AssessmentDetailPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelId = ref.watch(selectedLevelIdProvider);

    if (levelId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a level to view sublevels',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final sublevelsAsync = ref.watch(sublevelsForLevelProvider(levelId));

    return sublevelsAsync.when(
      data: (sublevels) {
        final maxDisplayOrder = sublevels.isEmpty
            ? 0
            : sublevels
                  .map((sublevel) => sublevel.displayOrder)
                  .reduce((a, b) => a > b ? a : b);
        final nextDisplayOrder = maxDisplayOrder + 1;
        final selectedSublevelId = ref.watch(selectedSublevelIdProvider);
        AssessmentSublevel? selectedSublevel;
        if (selectedSublevelId != null) {
          for (final sublevel in sublevels) {
            if (sublevel.id == selectedSublevelId) {
              selectedSublevel = sublevel;
              break;
            }
          }
        }

        void openCreateSublevelDialog() {
          showDialog(
            context: context,
            builder: (_) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Dialog(
                  insetPadding: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: CreateSublevelForm(
                      levelId: levelId,
                      initialDisplayOrder: nextDisplayOrder,
                      onCreated: (createdSublevel) {
                        ref.invalidate(sublevelsForLevelProvider(levelId));
                        ref.read(selectedSublevelIdProvider.notifier).state =
                            createdSublevel.id;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sublevel created')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        Future<void> deleteSublevel(AssessmentSublevel sublevel) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete sublevel'),
              content: Text('Delete "${sublevel.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;

          try {
            await ref
                .read(deleteSublevelProvider.notifier)
                .delete(
                  sublevel.id,
                  details: {
                    'level_id': levelId,
                    'title': sublevel.title,
                    'display_order': sublevel.displayOrder,
                  },
                );
            ref.invalidate(sublevelsForLevelProvider(levelId));
            if (ref.read(selectedSublevelIdProvider) == sublevel.id) {
              ref.read(selectedSublevelIdProvider.notifier).state = null;
            }

            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Sublevel deleted')));
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete sublevel: $e')),
            );
          }
        }

        void openEditSublevelDialog(AssessmentSublevel sublevel) {
          showDialog(
            context: context,
            builder: (_) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Dialog(
                  insetPadding: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: EditSublevelForm(
                      sublevel: sublevel,
                      onUpdated: () {
                        ref.invalidate(sublevelsForLevelProvider(levelId));
                        ref.read(selectedLevelIdProvider.notifier).state =
                            levelId;
                        ref.read(selectedSublevelIdProvider.notifier).state =
                            sublevel.id;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sublevel updated')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Sublevel Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: openCreateSublevelDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Sublevel'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (sublevels.isEmpty) {
                      return Center(
                        child: Text(
                          'No sublevels yet. Add one to get started.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }
                    if (selectedSublevel == null) {
                      return Center(
                        child: Text(
                          'Select a sublevel from the level panel to view details.',
                          style: TextStyle(color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final activeSublevel = selectedSublevel;
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  activeSublevel.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    openEditSublevelDialog(activeSublevel),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () => deleteSublevel(activeSublevel),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                ),
                                label: const Text('Delete'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red.shade600,
                                  side: BorderSide(color: Colors.red.shade200),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SublevelDetailsSection(sublevel: activeSublevel),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _SublevelDetailsSection extends StatelessWidget {
  const _SublevelDetailsSection({required this.sublevel});

  final AssessmentSublevel sublevel;

  @override
  Widget build(BuildContext context) {
    final questionCount = sublevel.questions.length;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((sublevel.description ?? '').trim().isNotEmpty) ...[
            Text(
              sublevel.description!,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Order: ${sublevel.displayOrder}')),
              Chip(label: Text('Passing: ${sublevel.passingScore}%')),
              Chip(
                label: Text(
                  '$questionCount question${questionCount == 1 ? '' : 's'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Questions',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (sublevel.questions.isEmpty)
            Text(
              'No questions in this sublevel.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sublevel.questions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _QuestionDetailsCard(
                  index: index,
                  question: sublevel.questions[index],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _QuestionDetailsCard extends StatefulWidget {
  const _QuestionDetailsCard({required this.index, required this.question});

  final int index;
  final dynamic question;

  static List<dynamic> _toList(dynamic value) {
    return value is List ? value : const [];
  }

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const {};
  }

  static String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  @override
  State<_QuestionDetailsCard> createState() => _QuestionDetailsCardState();
}

class _QuestionDetailsCardState extends State<_QuestionDetailsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final questionMap = _QuestionDetailsCard._toMap(widget.question);
    final options = _QuestionDetailsCard._toList(questionMap['options']);
    final examples = _QuestionDetailsCard._toList(questionMap['example']);
    final mainContent = _QuestionDetailsCard._toList(
      questionMap['main_content'],
    );
    final extraFields = _QuestionDetailsCard._toMap(
      questionMap['extra_fields'],
    );
    final knownKeys = {
      'type',
      'audio_file',
      'options',
      'correct_answer',
      'example',
      'main_content',
      'extra_fields',
    };
    final otherFields = <String, dynamic>{};
    for (final entry in questionMap.entries) {
      if (!knownKeys.contains(entry.key)) {
        otherFields[entry.key] = entry.value;
      }
    }

    final correctAnswer = _QuestionDetailsCard._formatValue(
      questionMap['correct_answer'],
    );
    final audioFile = _QuestionDetailsCard._formatValue(
      questionMap['audio_file'],
    );

    const typeLabels = <String, String>{
      'multiple_choice_image': 'Multiple Choice (Image)',
      'letter_recognition': 'Letter Recognition',
      'word_matching': 'Word Matching',
      'fill_in_blank': 'Fill in the Blank',
      'true_false': 'True / False',
    };
    final rawType = questionMap['type']?.toString() ?? '';
    final typeLabel = typeLabels[rawType] ?? rawType;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Question ${widget.index + 1}',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (typeLabel.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Correct: $correctAnswer • ${options.length} option${options.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (typeLabel.isNotEmpty)
                        _FieldLine(label: 'Type', value: typeLabel),
                      if (typeLabel.isNotEmpty) const SizedBox(height: 8),
                      _FieldLine(label: 'Audio file', value: audioFile),
                      const SizedBox(height: 8),
                      _FieldLine(label: 'Correct answer', value: correctAnswer),
                      const SizedBox(height: 10),
                      _FieldList(title: 'Options', values: options),
                      if (examples.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _FieldList(title: 'Example', values: examples),
                      ],
                      if (mainContent.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _FieldList(title: 'Main content', values: mainContent),
                      ],
                      if (extraFields.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _FieldMap(title: 'Extra fields', values: extraFields),
                      ],
                      if (otherFields.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _FieldMap(title: 'Other fields', values: otherFields),
                      ],
                    ],
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLine extends StatelessWidget {
  const _FieldLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _FieldList extends StatelessWidget {
  const _FieldList({required this.title, required this.values});

  final String title;
  final List<dynamic> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        if (values.isEmpty)
          Text('None', style: TextStyle(color: Colors.grey.shade600))
        else
          ...values.map(
            (value) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${_QuestionDetailsCard._formatValue(value)}'),
            ),
          ),
      ],
    );
  }
}

class _FieldMap extends StatelessWidget {
  const _FieldMap({required this.title, required this.values});

  final String title;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        ...values.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${entry.key}: ${_QuestionDetailsCard._formatValue(entry.value)}',
            ),
          ),
        ),
      ],
    );
  }
}
