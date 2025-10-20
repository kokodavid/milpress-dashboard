import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modules/modules_repository.dart';

class CourseModulesList extends ConsumerWidget {
  final String courseId;
  const CourseModulesList({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesForCourseProvider(courseId));
    return modulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Failed to load modules: $e'),
        ),
      ),
      data: (modules) {
        if (modules.isEmpty) {
          return const Center(child: Text('No modules for this course'));
        }
        return ListView.separated(
          itemCount: modules.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = modules[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${m.position}')),
              title: Text(m.description?.isNotEmpty == true ? m.description! : 'Module ${m.position}'),
              subtitle: Wrap(
                spacing: 12,
                children: [
                  if (m.durationMinutes != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 14),
                        const SizedBox(width: 4),
                        Text('${m.durationMinutes} min'),
                      ],
                    ),
                  if (m.locked)
                    const Chip(label: Text('Locked')),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
