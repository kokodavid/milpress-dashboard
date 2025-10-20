import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'course_models.dart';
import 'course_modules_list.dart';
import 'course_repository.dart';
import 'edit_course_form.dart';
import '../modules/create_module_form.dart';
import '../modules/modules_repository.dart';

String _fmtDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

class CourseDetailView extends ConsumerWidget {
  final Course course;
  final VoidCallback onRefresh;
  final VoidCallback onDeleted;
  const CourseDetailView({super.key, required this.course, required this.onRefresh, required this.onDeleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesForCourseProvider(course.id));
    final nextModulePosition = modulesAsync.maybeWhen(
      data: (modules) {
        var highest = 0;
        for (final module in modules) {
          if (module.position > highest) {
            highest = module.position;
          }
        }
        return highest + 1;
      },
      orElse: () => 1,
    );
    final modulesLoading = modulesAsync.maybeWhen(loading: () => true, orElse: () => false);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: EditCourseForm(
                              course: course,
                              onUpdated: () {
                                onRefresh();
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    label: const Text('Delete'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete course?'),
                          content: Text('Are you sure you want to delete "${course.title}"? This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          final repo = ref.read(courseRepositoryProvider);
                          await repo.deleteCourse(course.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Course deleted')),
                            );
                          }
                          onDeleted();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Delete failed: $e')),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              if (course.type != null && course.type!.isNotEmpty)
                Chip(label: Text(course.type!)),
              if (course.level != null)
                Chip(label: Text('Level ${course.level}')),
              if (course.durationInMinutes != null)
                Chip(label: Text('${course.durationInMinutes} min')),
              if (course.updatedAt != null)
                Chip(label: Text(_fmtDateTime(course.updatedAt!))),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Course Details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(course.description ?? 'No description available.'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modules',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              FilledButton.icon(
                onPressed: modulesLoading
                    ? null
                    : () {
                        final parentContext = context;
                        showDialog(
                          context: parentContext,
                          builder: (_) => Dialog(
                            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                            child: CreateModuleForm(
                              courseId: course.id,
                              initialPosition: nextModulePosition,
                              onCreated: () {
                                ref.invalidate(modulesForCourseProvider(course.id));
                                onRefresh();
                                if (parentContext.mounted) {
                                  ScaffoldMessenger.of(parentContext).showSnackBar(
                                    const SnackBar(content: Text('Module created')),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.add),
                label: const Text('Add Module'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CourseModulesList(courseId: course.id),
          ),
        ],
      ),
    );
  }
}
