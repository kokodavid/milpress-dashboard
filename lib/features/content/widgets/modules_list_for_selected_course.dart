import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/modules_repository.dart';
import '../../lesson/lessons_repository.dart';
import '../../lesson/lesson_models.dart';
import '../state/lessons_list_controller.dart';

class ModulesListForSelectedCourse extends ConsumerStatefulWidget {
  const ModulesListForSelectedCourse({super.key});

  @override
  ConsumerState<ModulesListForSelectedCourse> createState() => _ModulesListForSelectedCourseState();
}

class _ModulesListForSelectedCourseState extends ConsumerState<ModulesListForSelectedCourse> {
  final Set<String> _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final courseId = ref.watch(selectedCourseIdProvider);

    if (courseId == null) {
      return const _CenteredHint(text: 'Select a course to view modules and lessons');
    }

    final modulesAsync = ref.watch(modulesForCourseProvider(courseId));

    return modulesAsync.when(
      data: (modules) {
        if (modules.isEmpty) {
          return const _CenteredHint(text: 'No modules yet for this course');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: modules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final m = modules[index];
            final isExpanded = _expanded.contains(m.id);
            return Card.filled(
              child: ExpansionTile(
                leading: CircleAvatar(child: Text('${m.position}')),
                title: Text('Module ${m.position}'),
                subtitle: (m.description != null && m.description!.isNotEmpty)
                    ? Text(m.description!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m.locked) const Tooltip(message: 'Locked', child: Icon(Icons.lock_outline)),
                  ],
                ),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() {
                    if (expanded) {
                      _expanded.add(m.id);
                    } else {
                      _expanded.remove(m.id);
                    }
                  });
                },
                childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                children: [
                  if (!isExpanded)
                    const SizedBox.shrink()
                  else
                    _LessonsForModule(moduleId: m.id),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _ErrorRetry(
        message: 'Failed to load modules',
        onRetry: () => ref.refresh(modulesForCourseProvider(courseId)),
      ),
    );
  }
}

class _LessonsForModule extends ConsumerWidget {
  const _LessonsForModule({required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForModuleProvider(moduleId));
    return lessonsAsync.when(
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('No lessons in this module'),
            ),
          );
        }
        return Column(
          children: [
            for (final l in lessons) _LessonRow(lesson: l),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(child: Text('Failed to load lessons')),
            TextButton.icon(
              onPressed: () => ref.refresh(lessonsForModuleProvider(moduleId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonRow extends ConsumerWidget {
  const _LessonRow({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
      leading: const SizedBox(width: 4),
      title: Text(lesson.title),
      subtitle: Row(
        children: [
          Text('Position ${lesson.position}'),
          if (lesson.durationMinutes != null) ...[
            const SizedBox(width: 12),
            Text('${lesson.durationMinutes} min'),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ref.read(selectedLessonIdProvider.notifier).state = lesson.id;
      },
    );
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
