import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';
import 'package:milpress_dashboard/widgets/app_button.dart';
import 'package:milpress_dashboard/widgets/app_text_form_field.dart';

import 'assessment_v2_repository.dart';
import 'models/assessment_sublevel_model.dart';

class EditSublevelForm extends ConsumerStatefulWidget {
  final AssessmentSublevel sublevel;
  final VoidCallback onUpdated;

  const EditSublevelForm({
    super.key,
    required this.sublevel,
    required this.onUpdated,
  });

  @override
  ConsumerState<EditSublevelForm> createState() => _EditSublevelFormState();
}

class _EditSublevelFormState extends ConsumerState<EditSublevelForm> {
  final _formKey = GlobalKey<FormState>();
  late String title = widget.sublevel.title;
  late String description = widget.sublevel.description ?? '';
  late int displayOrder = widget.sublevel.displayOrder;
  late int passingScore = widget.sublevel.passingScore;
  final List<_QuestionDraft> _questions = [];
  bool isLoading = false;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _questions.addAll(
      widget.sublevel.questions.map(_QuestionDraft.fromQuestionData),
    );
  }

  @override
  void dispose() {
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(_QuestionDraft());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      final removed = _questions.removeAt(index);
      removed.dispose();
    });
  }

  void _addOption(_QuestionDraft question) {
    setState(() {
      question.optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(_QuestionDraft question, int optionIndex) {
    if (question.optionControllers.length <= 1) return;
    setState(() {
      final removed = question.optionControllers.removeAt(optionIndex);
      removed.dispose();
    });
  }

  void _addExample(_QuestionDraft question) {
    setState(() {
      question.exampleControllers.add(TextEditingController());
    });
  }

  void _removeExample(_QuestionDraft question, int exampleIndex) {
    if (question.exampleControllers.isEmpty) return;
    setState(() {
      final removed = question.exampleControllers.removeAt(exampleIndex);
      removed.dispose();
    });
  }

  void _addMainContent(_QuestionDraft question) {
    setState(() {
      question.mainContentControllers.add(TextEditingController());
    });
  }

  void _removeMainContent(_QuestionDraft question, int contentIndex) {
    if (question.mainContentControllers.length <= 1) return;
    setState(() {
      final removed = question.mainContentControllers.removeAt(contentIndex);
      removed.dispose();
    });
  }

  void _addCustomField(_QuestionDraft question) {
    setState(() {
      question.customFields.add(_CustomFieldDraft());
    });
  }

  void _removeCustomField(_QuestionDraft question, int fieldIndex) {
    setState(() {
      final removed = question.customFields.removeAt(fieldIndex);
      removed.dispose();
    });
  }

  List<String> _nonEmptyTexts(List<TextEditingController> controllers) {
    return controllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  String? _validateQuestions() {
    if (_questions.isEmpty) {
      return 'Add at least one question before saving the sublevel';
    }

    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final questionNo = i + 1;

      final audioFile = question.audioFileController.text.trim();
      if (audioFile.isEmpty) {
        return 'Question $questionNo: audio file is required';
      }

      final options = _nonEmptyTexts(question.optionControllers);
      if (options.isEmpty) {
        return 'Question $questionNo: add at least one option';
      }

      final correctAnswer = question.correctAnswerController.text.trim();
      if (correctAnswer.isEmpty) {
        return 'Question $questionNo: correct answer is required';
      }
      if (!options.contains(correctAnswer)) {
        return 'Question $questionNo: correct answer must match one option';
      }

      final mainContent = _nonEmptyTexts(question.mainContentControllers);
      if (mainContent.isEmpty) {
        return 'Question $questionNo: add at least one main content item';
      }

      final seenKeys = <String>{};
      for (var j = 0; j < question.customFields.length; j++) {
        final customField = question.customFields[j];
        final key = customField.keyController.text.trim();
        final value = customField.valueController.text.trim();
        if (key.isEmpty || value.isEmpty) {
          return 'Question $questionNo: custom fields need both key and value';
        }
        if (!seenKeys.add(key)) {
          return 'Question $questionNo: duplicate custom field "$key"';
        }
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _buildQuestionsPayload() {
    return _questions.map((question) {
      final extraFields = <String, dynamic>{};
      final examples = _nonEmptyTexts(question.exampleControllers);
      for (final customField in question.customFields) {
        final key = customField.keyController.text.trim();
        final value = customField.valueController.text.trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          extraFields[key] = value;
        }
      }

      return <String, dynamic>{
        ...question.otherFields,
        'audio_file': question.audioFileController.text.trim(),
        'options': _nonEmptyTexts(question.optionControllers),
        'correct_answer': question.correctAnswerController.text.trim(),
        if (examples.isNotEmpty) 'example': examples,
        'main_content': _nonEmptyTexts(question.mainContentControllers),
        if (extraFields.isNotEmpty) 'extra_fields': extraFields,
      };
    }).toList();
  }

  Future<void> _submit() async {
    setState(() => errorMsg = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final questionError = _validateQuestions();
    if (questionError != null) {
      setState(() => errorMsg = questionError);
      return;
    }

    _formKey.currentState?.save();
    final questionsPayload = _buildQuestionsPayload();

    setState(() => isLoading = true);
    try {
      await ref
          .read(saveSublevelProvider.notifier)
          .update(
            widget.sublevel.id,
            AssessmentSublevelUpdate(
              title: title,
              description: description.isEmpty ? null : description,
              displayOrder: displayOrder,
              questions: questionsPayload,
              passingScore: passingScore,
            ),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onUpdated();
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMsg = e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 760,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Sublevel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        errorMsg!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ),
                AppTextFormField(
                  label: 'Sublevel Title*',
                  hintText: 'Enter sublevel title',
                  initialValue: title,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Sublevel title is required'
                      : null,
                  onSaved: (v) => title = v?.trim() ?? '',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: AppTextFormField(
                        label: 'Display Order*',
                        hintText: 'Enter display order',
                        initialValue: displayOrder.toString(),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Display order is required';
                          }
                          final parsed = int.tryParse(v.trim());
                          if (parsed == null || parsed < 1) {
                            return 'Enter a valid number (>= 1)';
                          }
                          return null;
                        },
                        onSaved: (v) =>
                            displayOrder = int.tryParse(v?.trim() ?? '') ?? 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextFormField(
                        label: 'Passing Score (%)*',
                        hintText: '0 - 100',
                        initialValue: passingScore.toString(),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Passing score is required';
                          }
                          final parsed = int.tryParse(v.trim());
                          if (parsed == null || parsed < 0 || parsed > 100) {
                            return 'Enter a number between 0 and 100';
                          }
                          return null;
                        },
                        onSaved: (v) =>
                            passingScore = int.tryParse(v?.trim() ?? '') ?? 70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextFormField(
                  label: 'Description',
                  hintText: 'Describe this sublevel',
                  initialValue: description,
                  maxLines: 4,
                  onSaved: (v) => description = v?.trim() ?? '',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Questions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _addQuestion,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Question'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_questions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      'No questions added yet. Add a question to continue.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final question = _questions[index];
                      return _QuestionCard(
                        index: index,
                        question: question,
                        isLoading: isLoading,
                        onRemove: () => _removeQuestion(index),
                        onAddOption: () => _addOption(question),
                        onRemoveOption: (optionIndex) =>
                            _removeOption(question, optionIndex),
                        onAddExample: () => _addExample(question),
                        onRemoveExample: (exampleIndex) =>
                            _removeExample(question, exampleIndex),
                        onAddMainContent: () => _addMainContent(question),
                        onRemoveMainContent: (contentIndex) =>
                            _removeMainContent(question, contentIndex),
                        onAddCustomField: () => _addCustomField(question),
                        onRemoveCustomField: (fieldIndex) =>
                            _removeCustomField(question, fieldIndex),
                      );
                    },
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: AppButton(
                        label: 'Cancel',
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        outlined: true,
                        backgroundColor: Colors.grey,
                        textColor: Colors.grey,
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 170,
                      child: AppButton(
                        label: isLoading ? 'Saving...' : 'Save Changes',
                        onPressed: isLoading ? null : _submit,
                        backgroundColor: AppColors.primaryColor,
                        textColor: Colors.white,
                        height: 44,
                      ),
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
}

class _QuestionDraft {
  final TextEditingController audioFileController;
  final List<TextEditingController> optionControllers;
  final TextEditingController correctAnswerController;
  final List<TextEditingController> exampleControllers;
  final List<TextEditingController> mainContentControllers;
  final List<_CustomFieldDraft> customFields;
  final Map<String, dynamic> otherFields;

  static const Set<String> _knownQuestionKeys = {
    'audio_file',
    'options',
    'correct_answer',
    'example',
    'main_content',
    'extra_fields',
  };

  static Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) {
      return value.map((key, dynamic val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((text) => text.isNotEmpty)
        .toList();
  }

  static String _toFieldText(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    try {
      return jsonEncode(value);
    } catch (_) {
      return value.toString();
    }
  }

  _QuestionDraft({
    TextEditingController? audioFileController,
    List<TextEditingController>? optionControllers,
    TextEditingController? correctAnswerController,
    List<TextEditingController>? exampleControllers,
    List<TextEditingController>? mainContentControllers,
    List<_CustomFieldDraft>? customFields,
    Map<String, dynamic>? otherFields,
  }) : audioFileController = audioFileController ?? TextEditingController(),
       optionControllers =
           optionControllers ??
           [TextEditingController(), TextEditingController()],
       correctAnswerController =
           correctAnswerController ?? TextEditingController(),
       exampleControllers = exampleControllers ?? [],
       mainContentControllers =
           mainContentControllers ?? [TextEditingController()],
       customFields = customFields ?? [],
       otherFields = otherFields ?? const <String, dynamic>{};

  factory _QuestionDraft.fromQuestionData(dynamic value) {
    final map = _toMap(value);
    final options = _toStringList(map['options']);
    final examples = _toStringList(map['example']);
    final mainContent = _toStringList(map['main_content']);
    final extraFields = _toMap(map['extra_fields']);
    final customFields = extraFields.entries
        .map(
          (entry) => _CustomFieldDraft(
            keyController: TextEditingController(text: entry.key),
            valueController: TextEditingController(
              text: _toFieldText(entry.value),
            ),
          ),
        )
        .toList();
    final otherFields = <String, dynamic>{};
    for (final entry in map.entries) {
      if (!_knownQuestionKeys.contains(entry.key)) {
        otherFields[entry.key] = entry.value;
      }
    }

    return _QuestionDraft(
      audioFileController: TextEditingController(
        text: _toFieldText(map['audio_file']),
      ),
      optionControllers: options.isEmpty
          ? null
          : options
                .map((option) => TextEditingController(text: option))
                .toList(),
      correctAnswerController: TextEditingController(
        text: _toFieldText(map['correct_answer']),
      ),
      exampleControllers: examples
          .map((example) => TextEditingController(text: example))
          .toList(),
      mainContentControllers: mainContent.isEmpty
          ? null
          : mainContent
                .map((content) => TextEditingController(text: content))
                .toList(),
      customFields: customFields,
      otherFields: otherFields,
    );
  }

  void dispose() {
    audioFileController.dispose();
    for (final option in optionControllers) {
      option.dispose();
    }
    correctAnswerController.dispose();
    for (final example in exampleControllers) {
      example.dispose();
    }
    for (final content in mainContentControllers) {
      content.dispose();
    }
    for (final field in customFields) {
      field.dispose();
    }
  }
}

class _CustomFieldDraft {
  final TextEditingController keyController;
  final TextEditingController valueController;

  _CustomFieldDraft({
    TextEditingController? keyController,
    TextEditingController? valueController,
  }) : keyController = keyController ?? TextEditingController(),
       valueController = valueController ?? TextEditingController();

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final _QuestionDraft question;
  final bool isLoading;
  final VoidCallback onRemove;
  final VoidCallback onAddOption;
  final ValueChanged<int> onRemoveOption;
  final VoidCallback onAddExample;
  final ValueChanged<int> onRemoveExample;
  final VoidCallback onAddMainContent;
  final ValueChanged<int> onRemoveMainContent;
  final VoidCallback onAddCustomField;
  final ValueChanged<int> onRemoveCustomField;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.isLoading,
    required this.onRemove,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onAddExample,
    required this.onRemoveExample,
    required this.onAddMainContent,
    required this.onRemoveMainContent,
    required this.onAddCustomField,
    required this.onRemoveCustomField,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: isLoading ? null : onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remove question',
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppTextFormField(
            controller: question.audioFileController,
            label: 'Audio File*',
            hintText: 'Enter audio URL/path',
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          _DynamicStringListSection(
            title: 'Options*',
            controllers: question.optionControllers,
            addLabel: 'Add Option',
            itemLabel: 'Option',
            isLoading: isLoading,
            onAddItem: onAddOption,
            onRemoveItem: onRemoveOption,
          ),
          const SizedBox(height: 12),
          AppTextFormField(
            controller: question.correctAnswerController,
            label: 'Correct Answer*',
            hintText: 'Must match one option exactly',
            enabled: !isLoading,
          ),
          const SizedBox(height: 12),
          _DynamicStringListSection(
            title: 'Example (Optional)',
            controllers: question.exampleControllers,
            addLabel: 'Add Example Item',
            itemLabel: 'Example',
            isLoading: isLoading,
            onAddItem: onAddExample,
            onRemoveItem: onRemoveExample,
          ),
          const SizedBox(height: 12),
          _DynamicStringListSection(
            title: 'Main Content*',
            controllers: question.mainContentControllers,
            addLabel: 'Add Main Content Item',
            itemLabel: 'Content',
            isLoading: isLoading,
            onAddItem: onAddMainContent,
            onRemoveItem: onRemoveMainContent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Other Fields (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: isLoading ? null : onAddCustomField,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Field'),
              ),
            ],
          ),
          if (question.customFields.isEmpty)
            Text(
              'No extra fields added.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: question.customFields.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, fieldIndex) {
                final field = question.customFields[fieldIndex];
                return Row(
                  children: [
                    Expanded(
                      child: AppTextFormField(
                        controller: field.keyController,
                        label: 'Field Key',
                        hintText: 'e.g. hint_text',
                        enabled: !isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextFormField(
                        controller: field.valueController,
                        label: 'Field Value',
                        hintText: 'Enter value',
                        enabled: !isLoading,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: isLoading
                          ? null
                          : () => onRemoveCustomField(fieldIndex),
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: 'Remove field',
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _DynamicStringListSection extends StatelessWidget {
  final String title;
  final List<TextEditingController> controllers;
  final String addLabel;
  final String itemLabel;
  final bool isLoading;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;

  const _DynamicStringListSection({
    required this.title,
    required this.controllers,
    required this.addLabel,
    required this.itemLabel,
    required this.isLoading,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controllers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return Row(
              children: [
                Expanded(
                  child: AppTextFormField(
                    controller: controllers[index],
                    label: '$itemLabel ${index + 1}',
                    hintText: 'Enter ${itemLabel.toLowerCase()}',
                    enabled: !isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isLoading ? null : () => onRemoveItem(index),
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remove',
                ),
              ],
            );
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: isLoading ? null : onAddItem,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }
}
