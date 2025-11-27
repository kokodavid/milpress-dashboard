import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../user_progress_models.dart';
import 'summary_tile.dart';

class ProgressSummary extends StatelessWidget {
  final AsyncValue<List<CourseProgress>> courseProgressAsync;
  final AsyncValue<List<ModuleProgress>> moduleProgressAsync;
  final AsyncValue<List<LessonProgress>> lessonProgressAsync;
  const ProgressSummary({
    super.key,
    required this.courseProgressAsync,
    required this.moduleProgressAsync,
    required this.lessonProgressAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SummaryTile(
          label: 'Courses',
          value: courseProgressAsync.when(
            data: (d) => d.length.toString(),
            loading: () => '...',
            error: (_, __) => '-',
          ),
          extra: courseProgressAsync.when(
            data: (d) => '${d.where((c) => c.isCompleted == true).length} completed',
            loading: () => '',
            error: (_, __) => '',
          ),
          icon: Icons.school,
          color: Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: SummaryTile(
          label: 'Modules',
          value: moduleProgressAsync.when(
            data: (d) => d.length.toString(),
            loading: () => '...',
            error: (_, __) => '-',
          ),
          extra: moduleProgressAsync.when(
            data: (d) => '${d.where((m) => m.status == 'completed').length} completed',
            loading: () => '',
            error: (_, __) => '',
          ),
          icon: Icons.view_module,
          color: Colors.orange,
        )),
        const SizedBox(width: 12),
        Expanded(child: SummaryTile(
          label: 'Lessons',
          value: lessonProgressAsync.when(
            data: (d) => d.length.toString(),
            loading: () => '...',
            error: (_, __) => '-',
          ),
          extra: lessonProgressAsync.when(
            data: (d) => '${d.where((l) => l.isCompleted).length} completed',
            loading: () => '',
            error: (_, __) => '',
          ),
          icon: Icons.menu_book,
          color: Colors.green,
        )),
      ],
    );
  }
}
