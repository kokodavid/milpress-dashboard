import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../lesson_v2/lesson_v2_models.dart';
import '../../../lesson_v2/lesson_v2_repository.dart';
import 'step_drafts.dart';
import 'step_type_form_sections.dart';
import 'step_type_picker.dart';

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
      _steps.add(StepDraft(position: 1, stepKey: ''));
    }
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Steps', style: Theme.of(context).textTheme.titleMedium),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  onPressed: index == 0
                      ? null
                      : () => _moveStep(index, index - 1),
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
                  child: TextFormField(
                    controller: step.stepKeyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Step Key',
                      hintText: 'e.g. sound, blend, trace…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StepTypeButton(
                    currentType: step.stepType,
                    onChanged: (newType) =>
                        setState(() => step.setStepType(newType)),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Text('Required'),
                    Switch(
                      value: step.required,
                      onChanged: (value) =>
                          setState(() => step.required = value),
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
    return buildLessonStepTypeFields(
      context: context,
      step: step,
      setState: setState,
    );
  }

  Future<void> _addStep() async {
    final type = await showStepTypePicker(context: context);
    if (type == null) return;
    if (!mounted) return;
    setState(() {
      final draft = StepDraft(position: _steps.length + 1, stepKey: '');
      draft.setStepType(type);
      _steps.add(draft);
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps[index].dispose();
      _steps.removeAt(index);
      _reindexSteps();
    });
  }

  void _moveStep(int from, int to) {
    setState(() {
      final step = _steps.removeAt(from);
      _steps.insert(to, step);
      _reindexSteps();
    });
  }

  void _reindexSteps() {
    for (var i = 0; i < _steps.length; i++) {
      _steps[i].position = i + 1;
    }
  }

  String? _validateSteps() {
    if (_steps.isEmpty) {
      return 'Add at least one step';
    }
    for (final step in _steps) {
      final error = validateLessonStepDraft(step);
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  Future<void> _saveSteps() async {
    final error = _validateSteps();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save steps: $e')));
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
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
                          child: TextFormField(
                            controller: _draft.stepKeyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Step Key',
                              hintText: 'e.g. sound, blend, trace…',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StepTypeButton(
                            currentType: _draft.stepType,
                            onChanged: (newType) =>
                                setState(() => _draft.setStepType(newType)),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
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
    return buildLessonStepTypeFields(
      context: context,
      step: step,
      setState: setState,
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
}

// ── Shared step-type selector button ─────────────────────────────────────────

/// Replaces the raw [DropdownButtonFormField] for step type selection.
/// Shows the current type with its icon and a "Change" badge. Tapping opens
/// the [StepTypePickerDialog] so the user can preview types before choosing.
class _StepTypeButton extends StatelessWidget {
  const _StepTypeButton({
    required this.currentType,
    required this.onChanged,
  });

  final LessonStepType currentType;
  final ValueChanged<LessonStepType> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showStepTypePicker(
          context: context,
          initialType: currentType,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              currentType.icon,
              size: 18,
              color: const Color(0xFFE85D04),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Step Type',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  Text(
                    currentType.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Change',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFE85D04),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
