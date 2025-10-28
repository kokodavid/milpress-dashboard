import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../course/course_models.dart';
import '../../course/course_repository.dart';
import '../state/lessons_list_controller.dart';

class CourseSelectionHeader extends ConsumerWidget {
  const CourseSelectionHeader({
    super.key,
    this.selectedCourse,
    this.onClear,
  });

  final Course? selectedCourse;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const query = CoursesQuery(limit: 100, orderBy: 'title', ascending: true);
    final coursesAsync = ref.watch(coursesListProvider(query));
    final selectedId = selectedCourse?.id ?? ref.watch(selectedCourseIdProvider);

    return Row(
      children: [
        Expanded(
          child: coursesAsync.when(
            data: (courses) {
              final items = courses
                  .map((c) => DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                      ))
                  .toList();

              return DropdownButtonFormField<String>(
                value: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                hint: const Text('Select course'),
                items: items,
                onChanged: (value) {
                  // Change course selection and clear any selected lesson
                  ref.read(selectedCourseIdProvider.notifier).state = value;
                  ref.read(selectedLessonIdProvider.notifier).state = null;
                },
              );
            },
            loading: () => const _LoadingDropdown(),
            error: (e, _) => _ErrorDropdown(
              onRetry: () => ref.refresh(coursesListProvider(query)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Clear',
          onPressed: (selectedId != null)
              ? () {
                  ref.read(selectedCourseIdProvider.notifier).state = null;
                  ref.read(selectedLessonIdProvider.notifier).state = null;
                  onClear?.call();
                }
              : null,
          icon: const Icon(Icons.clear),
        )
      ],
    );
  }
}

class _LoadingDropdown extends StatelessWidget {
  const _LoadingDropdown();
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Course',
        prefixIcon: Icon(Icons.school_outlined),
      ),
      child: Row(
        children: const [
          SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading courses…'),
        ],
      ),
    );
  }
}

class _ErrorDropdown extends StatelessWidget {
  const _ErrorDropdown({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Course',
        prefixIcon: Icon(Icons.school_outlined),
        errorText: 'Failed to load courses',
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ),
    );
  }
}
