import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../lesson/lessons_repository.dart';
import '../../lesson/lesson_quiz_repository.dart';
import 'media/video_player_widget.dart';
import 'media/audio_player_widget.dart';
import 'edit_lesson_dialog.dart';
import 'delete_lesson_dialog.dart';
import 'quiz_dialog.dart';
import 'delete_quiz_dialog.dart';
import '../state/lessons_list_controller.dart';
import '../../../widgets/app_button.dart';

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
              // Header section with thumbnail, title, and actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LessonThumbnail(url: lesson.thumbnails),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          lesson.title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        // Lesson details row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.list_alt,
                                    size: 14,
                                    color: Colors.purple.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Position ${lesson.position}',
                                    style: TextStyle(
                                      color: Colors.purple.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            if (lesson.durationMinutes != null) ...[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${lesson.durationMinutes}min',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                            ],
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lesson.createdAt?.toString().split(' ')[0] ??
                                      'No date',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Show lesson info
                        },
                        icon: Icon(
                          Icons.info_outline,
                          color: Colors.grey.shade600,
                        ),
                        tooltip: 'Lesson Info',
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              showEditLessonDialog(
                                context: context,
                                ref: ref,
                                lesson: lesson,
                                onUpdated: () {
                                  // Refresh the lesson data
                                  ref.invalidate(lessonByIdProvider(lesson.id));
                                  // Also refresh the lessons list for the module
                                  ref.invalidate(lessonsForModuleProvider(lesson.moduleId));
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/edit_pencil.png',
                                    width: 16,
                                    height: 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              showDeleteLessonDialog(
                                context: context,
                                ref: ref,
                                lesson: lesson,
                                onDeleted: () {
                                  // Refresh the lessons list and clear selection
                                  ref.invalidate(lessonsForModuleProvider(lesson.moduleId));
                                  ref.read(selectedLessonIdProvider.notifier).state = null;
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Video player
              if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) ...[
                Text('Video', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 750,
                    constraints: const BoxConstraints(
                      minHeight: 225,
                      maxHeight: 450,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LessonVideoPlayer(url: lesson.videoUrl!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Extras section
              Text('Extras', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              // Video file entry
              if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.videocam,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Video',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lesson.videoUrl!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              // Play video
                            },
                            icon: Icon(
                              Icons.play_arrow,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: 'Play',
                          ),
                          // IconButton(
                          //   onPressed: () {
                          //     // Edit video URL
                          //   },
                          //   icon: Image.asset(
                          //     'assets/edit_pencil.png',
                          //     width: 20,
                          //     height: 20,
                          //     color: Colors.grey.shade600,
                          //   ),
                          //   tooltip: 'Edit',
                          // ),
                          // IconButton(
                          //   onPressed: () {
                          //     // Delete video
                          //   },
                          //   icon: Image.asset(
                          //     'assets/delete.png',
                          //     width: 20,
                          //     height: 20,
                          //     color: Colors.red.shade600,
                          //   ),
                          //   tooltip: 'Delete',
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Audio file entry
              if (lesson.audioUrl != null && lesson.audioUrl!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.audiotrack,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Audio',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lesson.audioUrl!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Action buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              // Play audio
                            },
                            icon: Icon(
                              Icons.play_arrow,
                              color: Colors.grey.shade600,
                            ),
                            tooltip: 'Play',
                          ),
                          // IconButton(
                          //   onPressed: () {
                          //     // Edit audio URL
                          //   },
                          //   icon: Image.asset(
                          //     'assets/edit_pencil.png',
                          //     width: 20,
                          //     height: 20,
                          //     color: Colors.grey.shade600,
                          //   ),
                          //   tooltip: 'Edit',
                          // ),
                          // IconButton(
                          //   onPressed: () {
                          //     // Delete audio
                          //   },
                          //   icon: Image.asset(
                          //     'assets/delete.png',
                          //     width: 20,
                          //     height: 20,
                          //     color: Colors.red.shade600,
                          //   ),
                          //   tooltip: 'Delete',
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              // Text(
              //   'Content',
              //   style: Theme.of(context).textTheme.titleMedium,
              // ),
              // const SizedBox(height: 8),
              // if (lesson.content != null && lesson.content!.isNotEmpty)
              //   Text(
              //     lesson.content!,
              //     style: Theme.of(context).textTheme.bodyMedium,
              //   )
              // else
              //   const Text('No content provided'),

              // const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Lesson Quizzes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 120,
                    height: 35,
                    child: AppButton(
                      label: 'Add Quiz',
                      backgroundColor: AppColors.primaryColor,
                      onPressed: () async {
                        final created = await showQuizDialog(
                          context: context,
                          ref: ref,
                          lessonId: lesson.id,
                        );
                        if (created == true) {
                          // Refresh quizzes list
                          ref.invalidate(quizzesForLessonProvider(lesson.id));
                        }
                      },
                    ),
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
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image, color: Colors.grey, size: 40),
    );

    if (url == null || url!.isEmpty) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url!,
        width: 120,
        height: 120,
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
            ),
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
        return Column(children: [for (final q in quizzes) _QuizCard(q: q)]);
      },
    );
  }
}

class _QuizCard extends StatefulWidget {
  const _QuizCard({required this.q});
  final dynamic q; // LessonQuiz

  @override
  State<_QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<_QuizCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionsWidget = _buildOptions(widget.q.options, theme);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with actions and dropdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Dropdown button
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.q.questionContent ?? 'Quiz Question',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _QuizCardActions(q: widget.q),
              ],
            ),
            const SizedBox(height: 12),
            
            // Tags row (always visible)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (widget.q.difficultyLevel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Level ${widget.q.difficultyLevel}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (widget.q.questionType != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.q.questionType!,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (widget.q.stage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.q.stage!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Collapsible content with animation
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Audio player section
                  if (widget.q.soundFileUrl != null && widget.q.soundFileUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200, width: 1),
                      ),
                      child: LessonAudioPlayer(url: widget.q.soundFileUrl!),
                    ),
                  ],
                  
                  // Answer options section
                  if (optionsWidget != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Answer Options',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    optionsWidget,
                  ],
                  
                  // Correct answer section
                  if (widget.q.correctAnswer != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Correct Answer: ${widget.q.correctAnswer!}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              crossFadeState: _isExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
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
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${String.fromCharCode('A'.codeUnitAt(0) + i)}:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      list[i].toString(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
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
        ...options.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${e.key.toString().toUpperCase()}:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.value.toString(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
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
          icon: Image.asset(
            'assets/edit_pencil.png',
            width: 20,
            height: 20,
            color: Colors.grey.shade600,
          ),
          onPressed: () async {
            final updated = await showQuizDialog(
              context: context,
              ref: ref,
              lessonId: q.lessonId,
              initialQuiz: q,
            );
            if (updated == true) {
              ref.invalidate(quizzesForLessonProvider(q.lessonId));
            }
          },
        ),
        IconButton(
          tooltip: 'Delete',
          icon: Image.asset(
            'assets/delete.png',
            width: 20,
            height: 20,
            color: Colors.red.shade600,
          ),
          onPressed: () async {
            await showDeleteQuizDialog(
              context: context,
              ref: ref,
              quiz: q,
              onDeleted: () {
                ref.invalidate(quizzesForLessonProvider(q.lessonId));
              },
            );
          },
        ),
      ],
    );
  }
}
