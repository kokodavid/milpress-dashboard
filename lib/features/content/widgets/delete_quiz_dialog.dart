import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lesson/lesson_quiz_repository.dart';
import '../../../widgets/app_button.dart';

Future<bool?> showDeleteQuizDialog({
  required BuildContext context,
  required WidgetRef ref,
  required dynamic quiz,
  required VoidCallback onDeleted,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _DeleteQuizDialog(
      quiz: quiz,
      ref: ref,
      onDeleted: onDeleted,
    ),
  );
}

class _DeleteQuizDialog extends StatefulWidget {
  final dynamic quiz;
  final WidgetRef ref;
  final VoidCallback onDeleted;

  const _DeleteQuizDialog({
    required this.quiz,
    required this.ref,
    required this.onDeleted,
  });

  @override
  State<_DeleteQuizDialog> createState() => _DeleteQuizDialogState();
}

class _DeleteQuizDialogState extends State<_DeleteQuizDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delete Quiz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Content
            Text(
              'Are you sure you want to delete this quiz?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            
            // Quiz preview card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.quiz,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quiz.questionContent ?? 'Quiz Question',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (widget.quiz.difficultyLevel != null)
                                  Text(
                                    'Level ${widget.quiz.difficultyLevel}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (widget.quiz.questionType != null) ...[
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    widget.quiz.questionType!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (widget.quiz.stage != null) ...[
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    widget.quiz.stage!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Warning card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The quiz question, answer options, and all associated data will be permanently deleted.',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    outlined: true,
                    backgroundColor: const Color(0xFFE85D04),
                    onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: _isDeleting ? 'Deleting...' : 'Delete Quiz',
                    backgroundColor: Colors.red.shade600,
                    onPressed: _isDeleting ? null : _handleDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      await widget.ref.read(deleteLessonQuizProvider.notifier).delete(
        widget.quiz.id,
        details: {
          'lesson_id': widget.quiz.lessonId,
          if (widget.quiz.questionType != null) 'question_type': widget.quiz.questionType,
          if (widget.quiz.stage != null) 'stage': widget.quiz.stage,
          if (widget.quiz.difficultyLevel != null) 'difficulty_level': widget.quiz.difficultyLevel,
          if (widget.quiz.questionContent != null)
            'question_excerpt': widget.quiz.questionContent!.length > 80
                ? widget.quiz.questionContent!.substring(0, 80)
                : widget.quiz.questionContent,
        },
      );
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz deleted successfully')),
        );
        widget.onDeleted();
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}