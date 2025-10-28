import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../lesson_quiz_model.dart';
import '../lesson_quiz_repository.dart';

class LessonQuizForm extends ConsumerStatefulWidget {
  const LessonQuizForm({
    super.key,
    required this.lessonId,
    this.initial,
  });

  final String lessonId;
  final LessonQuiz? initial;

  @override
  ConsumerState<LessonQuizForm> createState() => _LessonQuizFormState();
}

class _LessonQuizFormState extends ConsumerState<LessonQuizForm> {
  final _formKey = GlobalKey<FormState>();
  final _typeCtrl = TextEditingController();
  final _stageCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _audioCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();
  final _difficultyCtrl = TextEditingController();

  String? _optionsError;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _typeCtrl.text = i.questionType ?? '';
      _stageCtrl.text = i.stage ?? '';
      _contentCtrl.text = i.questionContent ?? '';
      _audioCtrl.text = i.soundFileUrl ?? '';
      _answerCtrl.text = i.correctAnswer ?? '';
      _difficultyCtrl.text = i.difficultyLevel?.toString() ?? '';
      if (i.options != null && i.options!.isNotEmpty) {
        _optionsCtrl.text = const JsonEncoder.withIndent('  ').convert(i.options);
      }
    }
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    _stageCtrl.dispose();
    _contentCtrl.dispose();
    _audioCtrl.dispose();
    _answerCtrl.dispose();
    _optionsCtrl.dispose();
    _difficultyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final createState = ref.watch(createLessonQuizProvider);
    final updateState = ref.watch(updateLessonQuizProvider);

    final isBusy = createState.isLoading || updateState.isLoading;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditing ? 'Edit Quiz' : 'Create Quiz',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _typeCtrl,
                  decoration: const InputDecoration(labelText: 'Question Type'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stageCtrl,
                  decoration: const InputDecoration(labelText: 'Stage'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentCtrl,
                  decoration: const InputDecoration(labelText: 'Question Content'),
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _audioCtrl,
                  decoration: const InputDecoration(labelText: 'Sound File URL'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _answerCtrl,
                  decoration: const InputDecoration(labelText: 'Correct Answer'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _difficultyCtrl,
                  decoration: const InputDecoration(labelText: 'Difficulty (int)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optionsCtrl,
                  decoration: InputDecoration(
                    labelText: 'Options (JSON: object or array)',
                    helperText: 'Example object: {"a":"A","b":"B"}\nExample array: ["A","B","C"]',
                    errorText: _optionsError,
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: isBusy ? null : _onSubmit,
                      child: Text(isEditing ? 'Save' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit() async {
    setState(() => _optionsError = null);

    Map<String, dynamic>? optionsMap;
    if (_optionsCtrl.text.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(_optionsCtrl.text.trim());
        if (parsed is List) {
          optionsMap = {'choices': parsed};
        } else if (parsed is Map) {
          optionsMap = parsed.map((k, v) => MapEntry(k.toString(), v));
        } else {
          setState(() => _optionsError = 'Options must be a JSON object or array');
          return;
        }
      } catch (e) {
        setState(() => _optionsError = 'Invalid JSON: $e');
        return;
      }
    }

    final difficulty = int.tryParse(_difficultyCtrl.text.trim());

    final isEditing = widget.initial != null;
    if (isEditing) {
      final update = LessonQuizUpdate(
        questionType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
        stage: _stageCtrl.text.trim().isEmpty ? null : _stageCtrl.text.trim(),
        questionContent: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        soundFileUrl: _audioCtrl.text.trim().isEmpty ? null : _audioCtrl.text.trim(),
        correctAnswer: _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
        options: optionsMap,
        difficultyLevel: difficulty,
      );
      try {
        await ref.read(updateLessonQuizProvider.notifier).update(widget.initial!.id, update);
        if (mounted) Navigator.of(context).pop(true);
      } catch (_) {}
    } else {
      final create = LessonQuizCreate(
        lessonId: widget.lessonId,
        questionType: _typeCtrl.text.trim().isEmpty ? null : _typeCtrl.text.trim(),
        stage: _stageCtrl.text.trim().isEmpty ? null : _stageCtrl.text.trim(),
        questionContent: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        soundFileUrl: _audioCtrl.text.trim().isEmpty ? null : _audioCtrl.text.trim(),
        correctAnswer: _answerCtrl.text.trim().isEmpty ? null : _answerCtrl.text.trim(),
        options: optionsMap,
        difficultyLevel: difficulty,
      );
      try {
        await ref.read(createLessonQuizProvider.notifier).create(create);
        if (mounted) Navigator.of(context).pop(true);
      } catch (_) {}
    }
  }
}
