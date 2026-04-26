import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/app_colors.dart';
import '../../assessment_v2/assessment_v2_repository.dart';
import '../../assessment_v2/models/assessment_v2_progress_model.dart';
import '../../course/course_repository.dart';
import '../../lesson_v2/lesson_v2_repository.dart';
import '../user_progress_models.dart';
import '../user_progress_repository.dart';
import 'donut_chart.dart';
import 'error_box.dart';
import 'status_chip.dart';

class CourseProgressList extends ConsumerWidget {
  final String userId;
  final AsyncValue<List<CourseProgress>> courseProgressAsync;
  final AsyncValue<List<LessonProgress>> lessonProgressAsync;
  final AsyncValue<List<AssessmentV2Progress>> assignmentProgressAsync;
  final String statusFilter; // 'all' | 'in_progress' | 'completed'

  const CourseProgressList({
    super.key,
    required this.userId,
    required this.courseProgressAsync,
    required this.lessonProgressAsync,
    required this.assignmentProgressAsync,
    this.statusFilter = 'all',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return courseProgressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorBox(message: 'Failed to load course progress: $e'),
      data: (courses) {
        // Group lesson progress by courseProgressId
        final lessonsByCourse = <String, List<LessonProgress>>{};
        lessonProgressAsync.whenData((lessons) {
          for (final l in lessons) {
            final key = l.courseProgressId ?? '';
            lessonsByCourse.putIfAbsent(key, () => []).add(l);
          }
        });

        // Apply status filter
        final filtered = courses.where((cp) {
          final done = cp.isCompleted == true;
          if (statusFilter == 'completed') return done;
          if (statusFilter == 'in_progress') return !done;
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              statusFilter == 'all'
                  ? 'No course progress yet.'
                  : 'No ${statusFilter == 'completed' ? 'completed' : 'in-progress'} courses.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final cp = filtered[index];
            final courseLessons = lessonsByCourse[cp.id] ?? [];
            return _CourseCard(
              userId: userId,
              cp: cp,
              courseLessons: courseLessons,
              assignmentProgressAsync: assignmentProgressAsync,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual course card
// ---------------------------------------------------------------------------

class _CourseCard extends ConsumerWidget {
  final String userId;
  final CourseProgress cp;
  final List<LessonProgress> courseLessons;
  final AsyncValue<List<AssessmentV2Progress>> assignmentProgressAsync;

  const _CourseCard({
    required this.userId,
    required this.cp,
    required this.courseLessons,
    required this.assignmentProgressAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseByIdProvider(cp.courseId));
    final lessonsTotalAsync = ref.watch(lessonsCountForCourseProvider(cp.courseId));
    final assessmentAsync = ref.watch(assessmentByCourseIdProvider(cp.courseId));

    final completedLessons = courseLessons.where((l) => l.isCompleted).length;
    final totalLessonsFromRepo = lessonsTotalAsync.maybeWhen(data: (v) => v, orElse: () => null);
    final totalLessons = totalLessonsFromRepo ?? courseLessons.length;

    final lessonPercent = totalLessons > 0 ? (completedLessons / totalLessons).clamp(0.0, 1.0) : 0.0;

    // Assignment counts for this course
    int totalAssignments = 0;
    int passedAssignments = 0;
    assessmentAsync.whenData((assessment) {
      if (assessment != null) {
        assignmentProgressAsync.whenData((all) {
          final forThisCourse = all.where((a) => a.assessmentId == assessment.id).toList();
          totalAssignments = forThisCourse.length;
          passedAssignments = forThisCourse.where((a) => a.isPassed).length;
        });
      }
    });

    final bool isCompleted = cp.isCompleted == true;

    // Determine donut color by status
    final donutColor = isCompleted ? const Color(0xFF10B981) : AppColors.primaryColor;

    // Started date label
    String startedLabel = '';
    if (cp.startedAt != null) {
      final d = cp.startedAt!;
      startedLabel =
          'Started ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: donut + title/date + status chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DonutChart(
                value: isCompleted ? 1.0 : lessonPercent,
                color: donutColor,
                size: 60,
                strokeWidth: 7,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course title
                    courseAsync.when(
                      loading: () => const SizedBox(
                        height: 16,
                        width: 120,
                        child: LinearProgressIndicator(),
                      ),
                      error: (_, __) => Text(
                        'Course ${cp.courseId.substring(0, 8)}…',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      data: (course) => Text(
                        course != null && course.title.isNotEmpty
                            ? course.title
                            : 'Course ${cp.courseId.substring(0, 8)}…',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (startedLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        startedLabel,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(
                label: isCompleted ? 'Completed' : 'In progress',
                completed: isCompleted,
              ),
              const SizedBox(width: 8),
              _DeleteCourseButton(
                userId: userId,
                courseProgressId: cp.id,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          // Dual progress rails
          _ProgressRail(
            label: 'Lessons',
            completed: completedLessons,
            total: totalLessons,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 10),
          _ProgressRail(
            label: 'Assignments',
            completed: passedAssignments,
            total: totalAssignments,
            color: const Color(0xFF142C44),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete course progress button
// ---------------------------------------------------------------------------

class _DeleteCourseButton extends ConsumerWidget {
  final String userId;
  final String courseProgressId;

  const _DeleteCourseButton({
    required this.userId,
    required this.courseProgressId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.delete_outline, size: 18),
      color: Colors.grey[500],
      tooltip: 'Remove course progress',
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(28, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => _confirm(context, ref),
    );
  }

  void _confirm(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove course progress'),
        content: const Text(
          'This will delete all progress for this course including lessons and modules. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref
                  .read(deleteCourseProgressProvider.notifier)
                  .delete(courseProgressId);

              ref.invalidate(courseProgressForUserProvider(userId));
              ref.invalidate(lessonProgressForUserProvider(userId));
              ref.invalidate(moduleProgressForUserProvider(userId));

              messenger.showSnackBar(SnackBar(
                content: Text(success
                    ? 'Course progress removed.'
                    : 'Failed to remove course progress.'),
                backgroundColor:
                    success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
              ));
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thin labelled progress rail  (label | bar | count)
// ---------------------------------------------------------------------------

class _ProgressRail extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final Color color;

  const _ProgressRail({
    required this.label,
    required this.completed,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const Spacer(),
            Text(
              '$completed/$total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            color: color,
          ),
        ),
      ],
    );
  }
}
