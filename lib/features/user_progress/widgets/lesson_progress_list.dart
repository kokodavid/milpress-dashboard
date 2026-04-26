import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lesson_v2/lesson_v2_repository.dart';
import '../user_progress_models.dart';
import '../user_progress_repository.dart';
import 'error_box.dart';
import 'status_chip.dart';

class LessonProgressList extends StatelessWidget {
  final String userId;
  final AsyncValue<List<LessonProgress>> lessonProgressAsync;
  final String statusFilter; // 'all' | 'in_progress' | 'completed'

  const LessonProgressList({
    super.key,
    required this.userId,
    required this.lessonProgressAsync,
    this.statusFilter = 'all',
  });

  @override
  Widget build(BuildContext context) {
    return lessonProgressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorBox(message: 'Failed to load lesson progress: $e'),
      data: (lessons) {
        final filtered = lessons.where((l) {
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

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final lp = filtered[index];
            return _LessonRow(userId: userId, lp: lp);
          },
        );
      },
    );
  }
}

class _LessonRow extends ConsumerWidget {
  final String userId;
  final LessonProgress lp;
  const _LessonRow({required this.userId, required this.lp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonByIdProvider(lp.lessonId));
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

          // Lesson title
          Expanded(
            child: lessonAsync.when(
              loading: () => const SizedBox(
                height: 14,
                width: 100,
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => Text(
                'Lesson ${lp.lessonId.substring(0, 8)}…',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              data: (lesson) => Text(
                lesson != null && lesson.lesson.title.isNotEmpty
                    ? lesson.lesson.title
                    : 'Lesson ${lp.lessonId.substring(0, 8)}…',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Quiz score badge (if available)
          if (lp.quizScore != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Score ${lp.quizScore!.round()}',
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
              final messenger = ScaffoldMessenger.of(context);
              final success = await ref
                  .read(deleteLessonProgressProvider.notifier)
                  .delete(lp.id);

              ref.invalidate(lessonProgressForUserProvider(userId));

              messenger.showSnackBar(SnackBar(
                content: Text(success
                    ? 'Lesson progress removed.'
                    : 'Failed to remove lesson progress.'),
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
