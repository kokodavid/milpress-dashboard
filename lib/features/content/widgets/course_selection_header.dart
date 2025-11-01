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

    return coursesAsync.when(
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }
}

class _LoadingDropdown extends StatelessWidget {
  const _LoadingDropdown();
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _ErrorDropdown extends StatelessWidget {
  const _ErrorDropdown({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
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
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }
}
