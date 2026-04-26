import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lesson_v2/lesson_v2_repository.dart' show lessonTitleMapProvider, lessonIdsForCourseProvider;
import '../user_progress_models.dart';
import '../user_progress_repository.dart';
import 'status_chip.dart';

class LessonProgressList extends ConsumerWidget {
  final String userId;
  final List<LessonProgress> lessons;
  final String statusFilter; // 'all' | 'in_progress' | 'completed'
  final String? courseFilter; // courseId to filter by, null = all courses

  const LessonProgressList({
    super.key,
    required this.userId,
    required this.lessons,
    this.statusFilter = 'all',
    this.courseFilter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When a course is selected, resolve its lesson IDs and filter.
    Set<String>? allowedIds;
    if (courseFilter != null) {
      final idsAsync = ref.watch(lessonIdsForCourseProvider(courseFilter!));
      if (idsAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      allowedIds = idsAsync.valueOrNull?.toSet() ?? {};
    }

    final filtered = lessons.where((l) {
      if (allowedIds != null && !allowedIds.contains(l.lessonId)) return false;
      if (statusFilter == 'completed') return l.isCompleted;
      if (statusFilter == 'in_progress') return !l.isCompleted;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No lesson progress found.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Build a single sorted key from all lesson IDs so the provider can be
    // compared correctly by Riverpod and we fire exactly one DB query.
    final sortedKey = (filtered.map((l) => l.lessonId).toList()..sort()).join(',');
    final titlesAsync = ref.watch(lessonTitleMapProvider(sortedKey));

    // Show a single spinner while titles are loading — no per-item loaders.
    if (titlesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final titleMap = titlesAsync.valueOrNull ?? {};

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final lp = filtered[index];
        final title = titleMap[lp.lessonId]?.isNotEmpty == true
            ? titleMap[lp.lessonId]!
            : 'Lesson ${lp.lessonId.substring(0, 8)}…';
        return _LessonRow(userId: userId, lp: lp, title: title);
      },
    );
  }
}

class _LessonRow extends ConsumerWidget {
  final String userId;
  final LessonProgress lp;
  final String title;
  const _LessonRow({required this.userId, required this.lp, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = lp.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE85D04),
            ),
          ),
          const SizedBox(width: 12),

          // Lesson title — already resolved, no async needed
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),

          // Attempt count badge (if available)
          if (lp.attemptCount != null && lp.attemptCount! > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${lp.attemptCount} ${lp.attemptCount == 1 ? 'attempt' : 'attempts'}',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(width: 8),
          ],

          StatusChip(
            label: isCompleted ? 'Completed' : 'In progress',
            completed: isCompleted,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: Colors.grey[400],
            tooltip: 'Remove lesson progress',
            style: IconButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(28, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove lesson progress'),
        content: const Text(
          'This will permanently delete the progress record for this lesson.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Capture messenger before any async gap.
              final messenger = ScaffoldMessenger.of(context);
              try {
                // Call the repo directly — avoids autoDispose disposing the
                // StateNotifier mid-flight when the dialog closes.
                await ref
                    .read(userProgressRepositoryProvider)
                    .deleteLessonProgressById(
                      lp.id,
                      userId: userId,
                      lessonId: lp.lessonId,
                    );
                messenger.showSnackBar(const SnackBar(
                  content: Text('Lesson progress removed.'),
                  backgroundColor: Color(0xFF10B981),
                ));
                ref.invalidate(lessonProgressForUserProvider(userId));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                  content: Text('Failed to remove lesson progress: $e'),
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
