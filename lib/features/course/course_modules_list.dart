import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modules/modules_repository.dart';

import '../../features/lesson/lessons_repository.dart';

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
            return ModuleWithLessonsDropdown(module: m);
          },
        );
      },
    );
  }
}

class ModuleWithLessonsDropdown extends ConsumerStatefulWidget {
  final dynamic module;
  const ModuleWithLessonsDropdown({super.key, required this.module});

  @override
  ConsumerState<ModuleWithLessonsDropdown> createState() => _ModuleWithLessonsDropdownState();
}

class _ModuleWithLessonsDropdownState extends ConsumerState<ModuleWithLessonsDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final lessonsAsync = ref.watch(lessonsForModuleProvider(module.id));
    int? lessonCount;
    lessonsAsync.whenData((lessons) => lessonCount = lessons.length);
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(child: Text('${module.position}')),
          title: Text(module.description?.isNotEmpty == true ? module.description! : 'Module ${module.position}'),
          subtitle: Wrap(
            spacing: 12,
            children: [
              if (module.durationMinutes != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14),
                    const SizedBox(width: 4),
                    Text('${module.durationMinutes} min'),
                  ],
                ),
              if (module.locked)
                const Chip(label: Text('Locked')),
              if (lessonCount != null)
                Chip(label: Text('$lessonCount lesson${lessonCount == 1 ? '' : 's'}')),
            ],
          ),
          trailing: IconButton(
            icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LessonsDropdown(moduleId: module.id),
          ),
      ],
    );
  }
}

class LessonsDropdown extends ConsumerWidget {
  final String moduleId;
  const LessonsDropdown({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForModuleProvider(moduleId));
    return lessonsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Failed to load lessons: $e'),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Text('No lessons in this module');
        }
        return SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: lessons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => LessonCard(lesson: lessons[index]),
          ),
        );
      },
    );
  }
}

class LessonCard extends StatelessWidget {
  final dynamic lesson;
  const LessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Thumbnail
            if (lesson.thumbnails != null && lesson.thumbnails.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  lesson.thumbnails,
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              )
            else
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: Colors.grey, size: 32),
              ),
            const SizedBox(width: 16),
            // Title & Duration
            Container(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (lesson.durationMinutes != null)
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 4),
                        Text('${lesson.durationMinutes} min'),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
