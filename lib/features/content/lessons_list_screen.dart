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
      body: Row(
        children: [
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
                          CourseSelectionHeader(
                            selectedCourse: selectedCourse.asData?.value,
                            onClear: () {
                              ref
                                      .read(selectedCourseIdProvider.notifier)
                                      .state =
                                  null;
                              ref
                                      .read(selectedLessonIdProvider.notifier)
                                      .state =
                                  null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Modules card
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
                              'Module',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const Expanded(child: ModulesListForSelectedCourse()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: SelectedLessonDetailPane()),
        ],
      ),
    );
  }
}
