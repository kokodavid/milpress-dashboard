import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lesson/lesson_quiz_model.dart';
import '../../lesson/lesson_quiz_repository.dart';
import '../../lesson/question_stages.dart';
import '../../../widgets/app_button.dart';

Future<bool?> showQuizDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String lessonId,
  LessonQuiz? initialQuiz,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => QuizDialog(
      lessonId: lessonId,
      initialQuiz: initialQuiz,
    ),
  );
}

class QuizDialog extends ConsumerStatefulWidget {
  const QuizDialog({
    super.key,
    required this.lessonId,
    this.initialQuiz,
  });

  final String lessonId;
  final LessonQuiz? initialQuiz;

  @override
  ConsumerState<QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends ConsumerState<QuizDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _typeCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _audioCtrl;
  late final TextEditingController _answerCtrl;
  late final TextEditingController _optionsCtrl;
  late final TextEditingController _difficultyCtrl;

  QuestionStage? _selectedQuestionStage;
  bool _submitting = false;
  String? _optionsError;

  bool get _isEditing => widget.initialQuiz != null;

  @override
  void initState() {
    super.initState();
    _typeCtrl = TextEditingController();
    _contentCtrl = TextEditingController();
    _audioCtrl = TextEditingController();
    _answerCtrl = TextEditingController();
    _optionsCtrl = TextEditingController();
    _difficultyCtrl = TextEditingController();

    // Initialize with existing data if editing
    final initial = widget.initialQuiz;
    if (initial != null) {
      _typeCtrl.text = initial.questionType ?? '';
      _selectedQuestionStage = QuestionStage.fromValue(initial.stage);
      _contentCtrl.text = initial.questionContent ?? '';
      _audioCtrl.text = initial.soundFileUrl ?? '';
      _answerCtrl.text = initial.correctAnswer ?? '';
      _difficultyCtrl.text = initial.difficultyLevel?.toString() ?? '';
      if (initial.options != null && initial.options!.isNotEmpty) {
        _optionsCtrl.text = const JsonEncoder.withIndent('  ').convert(initial.options);
      }
    }
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _contentCtrl.dispose();
    _audioCtrl.dispose();
    _answerCtrl.dispose();
    _optionsCtrl.dispose();
    _difficultyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Quiz' : 'Add Quiz',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Type and Stage (side by side)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Question Type',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _typeCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., Multiple Choice',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE85D04)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Stage',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<QuestionStage>(
                                  value: _selectedQuestionStage,
                                  decoration: InputDecoration(
                                    hintText: 'Select stage',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE85D04)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  items: QuestionStage.values.map((QuestionStage stage) {
                                    return DropdownMenuItem<QuestionStage>(
                                      value: stage,
                                      child: Text(stage.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (QuestionStage? newValue) {
                                    setState(() {
                                      _selectedQuestionStage = newValue;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select a stage';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Question Content
                      const Text(
                        'Question Content',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contentCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter the quiz question...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE85D04)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Question content is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Audio URL and Difficulty (side by side)
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Audio File URL',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _audioCtrl,
                                  decoration: InputDecoration(
                                    hintText: 'https://example.com/audio.mp3',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE85D04)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Difficulty Level',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _difficultyCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '1-10',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFFE85D04)),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Correct Answer
                      const Text(
                        'Correct Answer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _answerCtrl,
                        decoration: InputDecoration(
                          hintText: 'Enter the correct answer...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE85D04)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Answer Options
                      const Text(
                        'Answer Options (JSON)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _optionsCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: '{"a": "Option A", "b": "Option B"}\nor\n["Option A", "Option B", "Option C"]',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE85D04)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          errorText: _optionsError,
                        ),
                      ),
                      if (_optionsError == null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Format as JSON object or array. Object keys will be used as option labels.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    outlined: true,
                    backgroundColor: const Color(0xFFE85D04),
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: _submitting 
                        ? (_isEditing ? 'Updating...' : 'Creating...') 
                        : (_isEditing ? 'Update Quiz' : 'Create Quiz'),
                    backgroundColor: const Color(0xFFE85D04),
                    onPressed: _submitting ? null : _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _submitting = true;
      _optionsError = null;
    });

    try {
      // Validate and parse options
      Map<String, dynamic>? optionsMap;
      if (_optionsCtrl.text.trim().isNotEmpty) {
        try {
          final parsed = jsonDecode(_optionsCtrl.text.trim());
          if (parsed is List) {
            optionsMap = {'choices': parsed};
          } else if (parsed is Map) {
            optionsMap = parsed.map((k, v) => MapEntry(k.toString(), v));
          } else {
            setState(() {
              _optionsError = 'Options must be a JSON object or array';
              _submitting = false;
            });
            return;
          }
        } catch (e) {
          setState(() {
            _optionsError = 'Invalid JSON format: ${e.toString()}';
            _submitting = false;
          });
          return;
        }
      }

      final difficulty = _difficultyCtrl.text.trim().isEmpty 
          ? null 
          : int.tryParse(_difficultyCtrl.text.trim());

      if (_isEditing) {
        // Update existing quiz
        final update = LessonQuizUpdate(
          questionType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
          stage: _selectedQuestionStage?.value,
          questionContent: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
          soundFileUrl: _audioCtrl.text.trim().isEmpty ? null : _audioCtrl.text.trim(),
          correctAnswer: _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
          options: optionsMap,
          difficultyLevel: difficulty,
        );
        
        await ref.read(updateLessonQuizProvider.notifier).update(widget.initialQuiz!.id, update);
      } else {
        // Create new quiz
        final create = LessonQuizCreate(
          lessonId: widget.lessonId,
          questionType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
          stage: _selectedQuestionStage?.value,
          questionContent: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
          soundFileUrl: _audioCtrl.text.trim().isEmpty ? null : _audioCtrl.text.trim(),
          correctAnswer: _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
          options: optionsMap,
          difficultyLevel: difficulty,
        );
        
        await ref.read(createLessonQuizProvider.notifier).create(create);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Quiz updated successfully' : 'Quiz created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${_isEditing ? 'update' : 'create'} quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}