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

class CourseProgressList extends StatelessWidget {
  final String userId;
  final List<CourseProgress> courses;
  final List<LessonProgress> allLessonProgress;
  final List<AssessmentV2Progress> assignments;
  final String statusFilter; // 'all' | 'in_progress' | 'completed'

  const CourseProgressList({
    super.key,
    required this.userId,
    required this.courses,
    required this.allLessonProgress,
    required this.assignments,
    this.statusFilter = 'all',
  });

  @override
  Widget build(BuildContext context) {
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
        return _CourseCard(
          userId: userId,
          cp: cp,
          allLessonProgress: allLessonProgress,
          assignments: assignments,
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
  final List<LessonProgress> allLessonProgress;
  final List<AssessmentV2Progress> assignments;

  const _CourseCard({
    required this.userId,
    required this.cp,
    required this.allLessonProgress,
    required this.assignments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseByIdProvider(cp.courseId));
    final lessonsTotalAsync = ref.watch(lessonsCountForCourseProvider(cp.courseId));
    final lessonIdsAsync = ref.watch(lessonIdsForCourseProvider(cp.courseId));
    final assessmentAsync = ref.watch(assessmentByCourseIdProvider(cp.courseId));

    // Cross-reference all user completions with the lesson IDs that belong
    // to this course — lesson_completion has no course_progress_id column.
    final courseLessonIds = lessonIdsAsync.maybeWhen(
      data: (ids) => ids.toSet(),
      orElse: () => <String>{},
    );
    final completedLessons = allLessonProgress
        .where((l) => courseLessonIds.contains(l.lessonId) && l.isCompleted)
        .length;
    final totalLessons = lessonsTotalAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    final lessonPercent = totalLessons > 0 ? (completedLessons / totalLessons).clamp(0.0, 1.0) : 0.0;

    // Assignment counts for this course (plain list — no async needed).
    int totalAssignments = 0;
    int passedAssignments = 0;
    assessmentAsync.whenData((assessment) {
      if (assessment != null) {
        final forThisCourse = assignments.where((a) => a.assessmentId == assessment.id).toList();
        totalAssignments = forThisCourse.length;
        passedAssignments = forThisCourse.where((a) => a.isPassed).length;
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
                courseId: cp.courseId,
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
  final String courseId;
  final String courseProgressId;

  const _DeleteCourseButton({
    required this.userId,
    required this.courseId,
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
              try {
                await ref
                    .read(userProgressRepositoryProvider)
                    .deleteCourseProgressById(
                      courseProgressId,
                      userId: userId,
                      courseId: courseId,
                    );
                messenger.showSnackBar(const SnackBar(
                  content: Text('Course progress removed.'),
                  backgroundColor: Color(0xFF10B981),
                ));
                ref.invalidate(courseProgressForUserProvider(userId));
                ref.invalidate(lessonProgressForUserProvider(userId));
                ref.invalidate(moduleProgressForUserProvider(userId));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Failed to remove course progress: $e'),
                  backgroundColor: const Color(0xFFDC2626),
                ));
              }
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
