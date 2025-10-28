import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lesson/lessons_repository.dart';
import '../../lesson/lesson_quiz_repository.dart';
import '../../lesson/widgets/lesson_quiz_form.dart';
import 'media/video_player_widget.dart';
import 'media/audio_player_widget.dart';
import '../state/lessons_list_controller.dart';

class SelectedLessonDetailPane extends ConsumerWidget {
  const SelectedLessonDetailPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLessonId = ref.watch(selectedLessonIdProvider);

    if (selectedLessonId == null) {
      return const _EmptyDetailPlaceholder();
    }

    final lessonAsync = ref.watch(lessonByIdProvider(selectedLessonId));

    return lessonAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Failed to load lesson: $e'),
        ),
      ),
      data: (lesson) {
        if (lesson == null) return const _EmptyDetailPlaceholder();
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Title row with thumbnail
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LessonThumbnail(url: lesson.thumbnails),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.list_alt, size: 16),
                    label: Text('Position ${lesson.position}'),
                  ),
                  if (lesson.durationMinutes != null)
                    Chip(
                      avatar: const Icon(Icons.schedule, size: 16),
                      label: Text('${lesson.durationMinutes} min'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Video player
              if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) ...[
                Text('Video', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                LessonVideoPlayer(url: lesson.videoUrl!),
                const SizedBox(height: 16),
              ],
              // Audio player
              if (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty) ...[
                Text('Audio', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                LessonAudioPlayer(url: lesson.audioUrl!),
                const SizedBox(height: 16),
              ],
              if (lesson.videoUrl != null)
                ListTile(
                  leading: const Icon(Icons.ondemand_video),
                  title: const Text('Video'),
                  subtitle: Text(lesson.videoUrl!),
                ),
              if (lesson.audioUrl != null)
                ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: const Text('Audio'),
                  subtitle: Text(lesson.audioUrl!),
                ),
              const SizedBox(height: 12),
              Text(
                'Content',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (lesson.content != null && lesson.content!.isNotEmpty)
                Text(
                  lesson.content!,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                const Text('No content provided'),

              const SizedBox(height: 24),
              Row(
                children: [
                  Text('Quizzes', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () async {
                      final created = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => Padding(
                          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                          child: SizedBox(
                            height: MediaQuery.of(ctx).size.height * 0.85,
                            child: LessonQuizForm(lessonId: lesson.id),
                          ),
                        ),
                      );
                      if (created == true) {
                        // refresh quizzes list
                        // ignore: use_build_context_synchronously
                        final ref = ProviderScope.containerOf(context, listen: false);
                        ref.read(quizzesForLessonProvider(lesson.id).future).then((_) {
                          ref.invalidate(quizzesForLessonProvider(lesson.id));
                        });
                        ref.invalidate(quizzesForLessonProvider(lesson.id));
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Quiz'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _LessonQuizzesList(lessonId: lesson.id),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyDetailPlaceholder extends StatelessWidget {
  const _EmptyDetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'Select a lesson to view details',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _LessonThumbnail extends StatelessWidget {
  const _LessonThumbnail({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 96,
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image, color: Colors.grey),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url!,
        width: 96,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}

class _LessonQuizzesList extends ConsumerWidget {
  const _LessonQuizzesList({required this.lessonId});
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesAsync = ref.watch(quizzesForLessonProvider(lessonId));
    return quizzesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(12.0),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text('Failed to load quizzes: $e')),
            TextButton.icon(
              onPressed: () => ref.refresh(quizzesForLessonProvider(lessonId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            )
          ],
        ),
      ),
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('No quizzes for this lesson'),
          );
        }
        return Column(
          children: [
            for (final q in quizzes) _QuizCard(q: q),
          ],
        );
      },
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.q});
  final dynamic q; // LessonQuiz

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionsWidget = _buildOptions(q.options, theme);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (q.questionType != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(label: Text(q.questionType!)),
                  ),
                if (q.stage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(label: Text(q.stage!)),
                  ),
                if (q.difficultyLevel != null)
                  Chip(
                    avatar: const Icon(Icons.flag, size: 16),
                    label: Text('Lvl ${q.difficultyLevel}'),
                  ),
                const Spacer(),
                _QuizCardActions(q: q),
              ],
            ),
            if (q.questionContent != null) ...[
              Text(q.questionContent!, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
            ],
            if (q.soundFileUrl != null && q.soundFileUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Audio', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              LessonAudioPlayer(url: q.soundFileUrl!),
            ],
            if (optionsWidget != null) ...[
              const SizedBox(height: 8),
              optionsWidget,
            ],
            if (q.correctAnswer != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('Answer: ${q.correctAnswer!}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildOptions(Map<String, dynamic>? options, ThemeData theme) {
    if (options == null || options.isEmpty) return null;

    // Try common shapes: {choices: ["A","B"]} or {a:"...",b:"..."}
    if (options['choices'] is List) {
      final list = (options['choices'] as List).cast<dynamic>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Options', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(String.fromCharCode('A'.codeUnitAt(0) + i)),
                  const Text('. '),
                  Expanded(child: Text(list[i].toString())),
                ],
              ),
            ),
        ],
      );
    }

    // Fallback: list key-value pairs
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        ...options.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.key}: '),
                Expanded(child: Text(e.value.toString())),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizCardActions extends ConsumerWidget {
  const _QuizCardActions({required this.q});
  final dynamic q; // LessonQuiz

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final updated = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (ctx) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.85,
                  child: LessonQuizForm(lessonId: q.lessonId, initial: q),
                ),
              ),
            );
            if (updated == true) {
              ref.invalidate(quizzesForLessonProvider(q.lessonId));
            }
          },
        ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete quiz?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                ],
              ),
            );
            if (confirm == true) {
              try {
                await ref.read(deleteLessonQuizProvider.notifier).delete(q.id);
                ref.invalidate(quizzesForLessonProvider(q.lessonId));
              } catch (_) {}
            }
          },
        ),
      ],
    );
  }
}
