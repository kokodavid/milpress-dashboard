import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lesson_v2/lesson_v2_models.dart';
import '../../../lesson_v2/lesson_v2_repository.dart';
import 'step_drafts.dart';

const List<String> stepKeyOptions = [
  'sound',
  'example',
  'exercise',
  'formation',
];

const List<LessonStepType> forcedStepTypes = [
  LessonStepType.introduction,
  LessonStepType.demonstration,
  LessonStepType.practice,
  LessonStepType.assessment,
];
const List<String> forcedStepTitles = [
  'Pronounciation',
  'Letter Formation',
  'Example Words',
  'Exercise',
];

Future<bool?> showCreateLessonStepsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String lessonId,
  required List<LessonStep> initialSteps,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => CreateLessonStepsDialog(
      lessonId: lessonId,
      initialSteps: initialSteps,
      ref: ref,
    ),
  );
}

Future<EditedStep?> showEditLessonStepDialog({
  required BuildContext context,
  required LessonStep step,
}) {
  return showDialog<EditedStep>(
    context: context,
    builder: (context) => EditLessonStepDialog(step: step),
  );
}

class CreateLessonStepsDialog extends ConsumerStatefulWidget {
  const CreateLessonStepsDialog({
    super.key,
    required this.lessonId,
    required this.initialSteps,
    required this.ref,
  });

  final String lessonId;
  final List<LessonStep> initialSteps;
  final WidgetRef ref;

  @override
  ConsumerState<CreateLessonStepsDialog> createState() =>
      _CreateLessonStepsDialogState();
}

class _CreateLessonStepsDialogState
    extends ConsumerState<CreateLessonStepsDialog> {
  final List<StepDraft> _steps = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSteps.isNotEmpty) {
      _steps.addAll(widget.initialSteps.map(StepDraft.fromStep));
    } else {
      for (var i = 0; i < 4; i++) {
        _steps.add(StepDraft(
          position: i + 1,
          stepKey: stepKeyOptions.first,
        ));
      }
    }
    _applyForcedRules();
  }

  @override
  void dispose() {
    for (final step in _steps) {
      step.dispose();
    }
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
        width: 720,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Lesson Steps',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Steps',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _submitting ? null : _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Step'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: _steps.isEmpty
                    ? const Text('No steps added yet')
                    : Column(
                        children: [
                          for (var i = 0; i < _steps.length; i++)
                            _buildStepCard(_steps[i], i),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE85D04)),
                      foregroundColor: const Color(0xFFE85D04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _saveSteps,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D04),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Steps',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(StepDraft step, int index) {
    final isForcedType = index < forcedStepTypes.length;
    final isForcedKey = index < stepKeyOptions.length;
    final isForcedTitle = index < forcedStepTitles.length;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Step ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed:
                      index == 0 ? null : () => _moveStep(index, index - 1),
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  tooltip: 'Move up',
                ),
                IconButton(
                  onPressed: index == _steps.length - 1
                      ? null
                      : () => _moveStep(index, index + 1),
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  tooltip: 'Move down',
                ),
                IconButton(
                  onPressed: () => _removeStep(index),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Remove step',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: stepKeyOptions.contains(step.stepKeyCtrl.text)
                        ? step.stepKeyCtrl.text
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Step Key',
                      border: OutlineInputBorder(),
                    ),
                    items: stepKeyOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: isForcedKey
                        ? null
                        : (value) {
                          if (value != null) {
                            setState(() => step.stepKeyCtrl.text = value);
                          }
                        },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<LessonStepType>(
                    value: step.stepType,
                    decoration: const InputDecoration(
                      labelText: 'Step Type',
                      border: OutlineInputBorder(),
                    ),
                    items: LessonStepType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.name),
                          ),
                        )
                        .toList(),
                    onChanged: isForcedType
                        ? null
                        : (value) {
                          if (value != null) {
                            setState(() => step.setStepType(value));
                          }
                        },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text('Required'),
                    Switch(
                      value: step.required,
                      onChanged: (value) => setState(() => step.required = value),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStepTypeFields(step),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTypeFields(StepDraft step) {
    switch (step.stepType) {
      case LessonStepType.introduction:
        return _buildIntroductionFields(step, lockTitle: _isLockedTitle(step));
      case LessonStepType.demonstration:
        return _buildDemonstrationFields(step, lockTitle: _isLockedTitle(step));
      case LessonStepType.practice:
        return _buildPracticeFields(step, lockTitle: _isLockedTitle(step));
      case LessonStepType.assessment:
        return _buildAssessmentFields(step, lockTitle: _isLockedTitle(step));
    }
  }

  bool _isLockedTitle(StepDraft step) =>
      (step.position - 1) < forcedStepTitles.length;

  Widget _buildIntroductionFields(StepDraft step, {required bool lockTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          enabled: !lockTitle,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.displayTextCtrl,
          decoration: const InputDecoration(
            labelText: 'Display Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.audioBaseUrlCtrl,
          decoration: const InputDecoration(
            labelText: 'Audio Base URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: step.audio05Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Audio 0.5x URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: step.audio1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Audio 1x URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: step.audio15Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Audio 1.5x URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.howToSvgUrlCtrl,
          decoration: const InputDecoration(
            labelText: 'How-to SVG URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.practiceTipTextCtrl,
          decoration: const InputDecoration(
            labelText: 'Practice Tip Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.practiceTipAudioCtrl,
          decoration: const InputDecoration(
            labelText: 'Practice Tip Audio URL',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDemonstrationFields(StepDraft step, {required bool lockTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          enabled: !lockTitle,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Image URLs',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < step.imageUrlCtrls.length; i++)
          _buildUrlRow(
            controller: step.imageUrlCtrls[i],
            onRemove: () => setState(() => step.removeImageUrl(i)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(step.addImageUrl),
            icon: const Icon(Icons.add),
            label: const Text('Add image'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.feedbackTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Feedback Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.feedbackBodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Feedback Body',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPracticeFields(StepDraft step, {required bool lockTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          enabled: !lockTitle,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Items',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < step.practiceItems.length; i++)
          _buildPracticeItemRow(
            item: step.practiceItems[i],
            onRemove: () => setState(() => step.removePracticeItem(i)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(step.addPracticeItem),
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.tipTextCtrl,
          decoration: const InputDecoration(
            labelText: 'Tip Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.tipSoundCtrl,
          decoration: const InputDecoration(
            labelText: 'Tip Sound URL',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentFields(StepDraft step, {required bool lockTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          enabled: !lockTitle,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.promptCtrl,
          decoration: const InputDecoration(
            labelText: 'Prompt',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.soundInstructionCtrl,
          decoration: const InputDecoration(
            labelText: 'Sound Instruction URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Options',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < step.assessmentOptions.length; i++)
          _buildAssessmentOptionRow(
            option: step.assessmentOptions[i],
            onRemove: () => setState(() => step.removeAssessmentOption(i)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(step.addAssessmentOption),
            icon: const Icon(Icons.add),
            label: const Text('Add option'),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlRow({
    required TextEditingController controller,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeItemRow({
    required PracticeItemDraft item,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.imageUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.soundUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sound URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentOptionRow({
    required AssessmentOptionDraft option,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: option.labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: option.imageUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: option.isCorrect,
                    onChanged: (value) =>
                        setState(() => option.isCorrect = value ?? false),
                  ),
                  const Text('Correct'),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addStep() {
    setState(() {
      _steps.add(StepDraft(
        position: _steps.length + 1,
        stepKey: stepKeyOptions.first,
      ));
      _applyForcedRules();
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps[index].dispose();
      _steps.removeAt(index);
      _reindexSteps();
      _applyForcedRules();
    });
  }

  void _moveStep(int from, int to) {
    setState(() {
      final step = _steps.removeAt(from);
      _steps.insert(to, step);
      _reindexSteps();
      _applyForcedRules();
    });
  }

  void _reindexSteps() {
    for (var i = 0; i < _steps.length; i++) {
      _steps[i].position = i + 1;
    }
  }

  void _applyForcedRules() {
    for (var i = 0; i < _steps.length && i < forcedStepTypes.length; i++) {
      _steps[i].stepType = forcedStepTypes[i];
      _steps[i].stepKeyCtrl.text = stepKeyOptions[i];
      if (i < forcedStepTitles.length) {
        _steps[i].titleCtrl.text = forcedStepTitles[i];
      }
    }
  }

  String? _validateSteps() {
    if (_steps.isEmpty) {
      return 'Add at least one step';
    }
    for (final step in _steps) {
      if (step.stepKeyCtrl.text.trim().isEmpty) {
        return 'Every step needs a step key';
      }
      if (step.titleCtrl.text.trim().isEmpty) {
        return 'Every step needs a title';
      }
      if (step.stepType == LessonStepType.practice &&
          step.practiceItems.isEmpty) {
        return 'Practice steps need at least one item';
      }
      if (step.stepType == LessonStepType.assessment &&
          step.assessmentOptions.isEmpty) {
        return 'Assessment steps need at least one option';
      }
      if (step.stepType == LessonStepType.assessment &&
          step.assessmentOptions.every((o) => !o.isCorrect)) {
        return 'Assessment steps need at least one correct option';
      }
      if (step.stepType == LessonStepType.introduction &&
          step.displayTextCtrl.text.trim().isEmpty) {
        return 'Introduction steps need display text';
      }
      if (step.stepType == LessonStepType.assessment &&
          step.promptCtrl.text.trim().isEmpty) {
        return 'Assessment steps need a prompt';
      }
    }
    return null;
  }

  Future<void> _saveSteps() async {
    final error = _validateSteps();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final inputs = _steps.map((s) => s.toInput()).toList();
      await widget.ref
          .read(saveLessonProvider.notifier)
          .updateSteps(widget.lessonId, inputs);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save steps: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class EditLessonStepDialog extends StatefulWidget {
  const EditLessonStepDialog({super.key, required this.step});

  final LessonStep step;

  @override
  State<EditLessonStepDialog> createState() => _EditLessonStepDialogState();
}

class _EditLessonStepDialogState extends State<EditLessonStepDialog> {
  late StepDraft _draft;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _draft = StepDraft.fromStep(widget.step);
    _applyForcedRules();
  }

  @override
  void dispose() {
    _draft.dispose();
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
        width: 720,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Step',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: stepKeyOptions.contains(_draft.stepKeyCtrl.text)
                                ? _draft.stepKeyCtrl.text
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Step Key',
                              border: OutlineInputBorder(),
                            ),
                            items: stepKeyOptions
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                            onChanged: _isForcedKey()
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(
                                          () => _draft.stepKeyCtrl.text = value);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<LessonStepType>(
                            value: _draft.stepType,
                            decoration: const InputDecoration(
                              labelText: 'Step Type',
                              border: OutlineInputBorder(),
                            ),
                            items: LessonStepType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _isForcedType()
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _draft.setStepType(value));
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            const Text('Required'),
                            Switch(
                              value: _draft.required,
                              onChanged: (value) =>
                                  setState(() => _draft.required = value),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStepTypeFields(_draft),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFFE85D04)),
                      foregroundColor: const Color(0xFFE85D04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D04),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Step',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTypeFields(StepDraft step) {
    switch (step.stepType) {
      case LessonStepType.introduction:
        return _buildIntroductionFields(step);
      case LessonStepType.demonstration:
        return _buildDemonstrationFields(step);
      case LessonStepType.practice:
        return _buildPracticeFields(step);
      case LessonStepType.assessment:
        return _buildAssessmentFields(step);
    }
  }

  Widget _buildIntroductionFields(StepDraft step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.displayTextCtrl,
          decoration: const InputDecoration(
            labelText: 'Display Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.audioBaseUrlCtrl,
          decoration: const InputDecoration(
            labelText: 'Audio Base URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: step.audio05Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Audio 0.5x URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: step.audio1Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Audio 1x URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: step.audio15Ctrl,
                decoration: const InputDecoration(
                  labelText: 'Audio 1.5x URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.howToSvgUrlCtrl,
          decoration: const InputDecoration(
            labelText: 'How-to SVG URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.practiceTipTextCtrl,
          decoration: const InputDecoration(
            labelText: 'Practice Tip Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.practiceTipAudioCtrl,
          decoration: const InputDecoration(
            labelText: 'Practice Tip Audio URL',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDemonstrationFields(StepDraft step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Image URLs',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < step.imageUrlCtrls.length; i++)
          _buildUrlRow(
            controller: step.imageUrlCtrls[i],
            onRemove: () => setState(() => step.removeImageUrl(i)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(step.addImageUrl),
            icon: const Icon(Icons.add),
            label: const Text('Add image'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.feedbackTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Feedback Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.feedbackBodyCtrl,
          decoration: const InputDecoration(
            labelText: 'Feedback Body',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildPracticeFields(StepDraft step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Items',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < step.practiceItems.length; i++)
          _buildPracticeItemRow(
            item: step.practiceItems[i],
            onRemove: () => setState(() => step.removePracticeItem(i)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(step.addPracticeItem),
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.tipTextCtrl,
          decoration: const InputDecoration(
            labelText: 'Tip Text',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.tipSoundCtrl,
          decoration: const InputDecoration(
            labelText: 'Tip Sound URL',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentFields(StepDraft step) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: step.titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.promptCtrl,
          decoration: const InputDecoration(
            labelText: 'Prompt',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: step.soundInstructionCtrl,
          decoration: const InputDecoration(
            labelText: 'Sound Instruction URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Options',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < step.assessmentOptions.length; i++)
          _buildAssessmentOptionRow(
            option: step.assessmentOptions[i],
            onRemove: () => setState(() => step.removeAssessmentOption(i)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(step.addAssessmentOption),
            icon: const Icon(Icons.add),
            label: const Text('Add option'),
          ),
        ),
      ],
    );
  }

  Widget _buildUrlRow({
    required TextEditingController controller,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeItemRow({
    required PracticeItemDraft item,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: item.imageUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.soundUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sound URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentOptionRow({
    required AssessmentOptionDraft option,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: option.labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: option.imageUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                children: [
                  Checkbox(
                    value: option.isCorrect,
                    onChanged: (value) =>
                        setState(() => option.isCorrect = value ?? false),
                  ),
                  const Text('Correct'),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    setState(() => _submitting = true);
    try {
      final input = _draft.toInput();
      Navigator.of(context).pop(EditedStep(input: input));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _applyForcedRules() {
    final index = _draft.position - 1;
    if (index < 0 || index >= forcedStepTypes.length) return;
    _draft.stepType = forcedStepTypes[index];
    _draft.stepKeyCtrl.text = stepKeyOptions[index];
    if (index < forcedStepTitles.length) {
      _draft.titleCtrl.text = forcedStepTitles[index];
    }
  }

  bool _isForcedType() => (_draft.position - 1) < forcedStepTypes.length;

  bool _isForcedKey() => (_draft.position - 1) < stepKeyOptions.length;

  bool _isLockedTitle(StepDraft step) => (step.position - 1) < forcedStepTitles.length;
}
