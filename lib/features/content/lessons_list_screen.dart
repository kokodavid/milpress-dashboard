import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/lessons_list_controller.dart';
import 'widgets/course_selection_header.dart';
import 'widgets/modules_list_for_selected_course.dart';
import 'widgets/selected_lesson_detail_pane.dart';

class LessonsListScreen extends ConsumerWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCourse = ref.watch(selectedCourseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lessons')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selection header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CourseSelectionHeader(
              selectedCourse: selectedCourse.asData?.value,
              onClear: () {
                ref.read(selectedCourseIdProvider.notifier).state = null;
                ref.read(selectedLessonIdProvider.notifier).state = null;
              },
            ),
          ),
          const Divider(height: 1),
          // Split view: left list, right detail
          Expanded(
            child: Row(
              children: const [
                SizedBox(
                  width: 380,
                  child: ModulesListForSelectedCourse(),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  child: SelectedLessonDetailPane(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selectedCourse.asData?.value == null ? null : () {},
        icon: const Icon(Icons.add),
        label: const Text('Create Lesson'),
      ),
    );
  }
}
