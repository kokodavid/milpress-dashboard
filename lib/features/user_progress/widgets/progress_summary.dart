import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../assessment_v2/models/assessment_v2_progress_model.dart';
import '../../course/course_repository.dart';
import '../../lesson_v2/lesson_v2_repository.dart';
import '../user_progress_models.dart';
import 'summary_tile.dart';

/// KPI strip: Courses · Lessons · Assignments
class ProgressSummary extends ConsumerWidget {
  final AsyncValue<List<CourseProgress>> courseProgressAsync;
  final AsyncValue<List<LessonProgress>> lessonProgressAsync;
  final AsyncValue<List<AssessmentV2Progress>> assignmentProgressAsync;

  const ProgressSummary({
    super.key,
    required this.courseProgressAsync,
    required this.lessonProgressAsync,
    required this.assignmentProgressAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Total published (unlocked) courses from the catalog
    final publishedCountAsync = ref.watch(publishedCoursesCountProvider);

    // Total lessons in the catalog
    final totalLessonsAsync = ref.watch(lessonsCountProvider);

    // Courses: attempted / total published (locked = false)
    final courseFraction = courseProgressAsync.when(
      data: (d) {
        final attempted = d.length;
        final total = publishedCountAsync.maybeWhen(
          data: (n) => n,
          orElse: () => null,
        );
        return total != null ? '$attempted/$total' : '$attempted/…';
      },
      loading: () => '…',
      error: (_, __) => '-/-',
    );

    // Lessons: X completed / Y total in catalog
    final lessonFraction = lessonProgressAsync.when(
      data: (d) {
        final done = d.where((l) => l.isCompleted).length;
        final total = totalLessonsAsync.maybeWhen(
          data: (n) => n,
          orElse: () => null,
        );
        return total != null ? '$done/$total' : '$done/…';
      },
      loading: () => '…',
      error: (_, __) => '-/-',
    );

    // Assignments: X passed / Y total attempted
    final assignmentFraction = assignmentProgressAsync.when(
      data: (d) {
        final total = d.length;
        final passed = d.where((a) => a.isPassed).length;
        return '$passed/$total';
      },
      loading: () => '…',
      error: (_, __) => '-/-',
    );

    return Row(
      children: [
        Expanded(
          child: SummaryTile(
            label: 'Courses',
            fraction: courseFraction,
            sublabel: 'attempted',
            icon: Icons.menu_book_outlined,
            iconColor: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryTile(
            label: 'Lessons',
            fraction: lessonFraction,
            sublabel: 'completed',
            icon: Icons.play_lesson_outlined,
            iconColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryTile(
            label: 'Assignments',
            fraction: assignmentFraction,
            sublabel: 'passed',
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFFE85D04),
          ),
        ),
      ],
    );
  }
}
