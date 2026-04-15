import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../modules/modules_repository.dart';
import '../../modules/create_module_form.dart';
import '../../lesson_v2/lesson_v2_repository.dart';
import '../../lesson_v2/lesson_v2_models.dart';
import '../../assessment_v2/assessment_v2_repository.dart';
import '../state/lessons_list_controller.dart';
import '../../../widgets/app_button.dart';
import 'lesson_steps/step_drafts.dart';
import 'lesson_steps/step_type_form_sections.dart';

class ModulesListForSelectedCourse extends ConsumerStatefulWidget {
  const ModulesListForSelectedCourse({super.key});

  @override
  ConsumerState<ModulesListForSelectedCourse> createState() =>
      _ModulesListForSelectedCourseState();
}

class _ModulesListForSelectedCourseState
    extends ConsumerState<ModulesListForSelectedCourse> {
  final Set<String> _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final courseId = ref.watch(selectedCourseIdProvider);

    if (courseId == null) {
      return const _CenteredHint(
        text: 'Select a course to view modules and lessons',
      );
    }

    final modulesAsync = ref.watch(modulesForCourseProvider(courseId));

    return modulesAsync.when(
      data: (modules) {
        final nextPosition = modules.isEmpty ? 1 : (modules.last.position + 1);
        return Column(
          children: [
            if (modules.isEmpty)
              const Expanded(
                child: _CenteredHint(text: 'No modules yet for this course'),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: modules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = modules[index];
                    final isExpanded = _expanded.contains(m.id);
                    return _ModuleCard(
                      module: m,
                      isExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expanded.add(m.id);
                          } else {
                            _expanded.remove(m.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            // Add Module button at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: 'Add Module',
                backgroundColor: AppColors.primaryColor,
                onPressed: () async {
                  final created = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => CreateModuleForm(
                      courseId: courseId,
                      initialPosition: nextPosition,
                      onCreated: () {
                        // refresh after creation
                        ref.invalidate(modulesForCourseProvider(courseId));
                      },
                    ),
                  );
                  if (created == true) {
                    // Additional handling if needed
                  }
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => _ErrorRetry(
        message: 'Failed to load modules',
        onRetry: () => ref.refresh(modulesForCourseProvider(courseId)),
      ),
    );
  }
}

class _ModuleCard extends ConsumerWidget {
  const _ModuleCard({
    required this.module,
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  final dynamic module;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAssessment = module.moduleType == 'assessment';
    final lessonsAsync = isAssessment
        ? null
        : ref.watch(lessonsForModuleProvider(module.id));
    final assessmentAsync = isAssessment
        ? ref.watch(assessmentByCourseIdProvider(module.courseId))
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isAssessment ? Colors.purple.shade400 : AppColors.copBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: isAssessment
                  ? const Icon(Icons.quiz, size: 18, color: Colors.white)
                  : Text(
                      '${module.position}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          title: Text('Module ${module.position}'),
          subtitle: isAssessment
              ? assessmentAsync!.when(
                  data: (assessment) {
                    final lockedText = module.locked ? ' • 🔒 Locked' : '';
                    if (assessment == null) {
                      return Text('Assessment (not linked)$lockedText');
                    }
                    return Text('${assessment.title}$lockedText');
                  },
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Error loading assessment'),
                )
              : lessonsAsync!.when(
                  data: (lessons) {
                    final lessonCount = lessons.length;
                    final lockedText = module.locked ? ' • 🔒 Locked' : '';
                    if (lessons.isEmpty) {
                      return Text('No lessons$lockedText');
                    }
                    final firstLesson = lessons.first.title;
                    final lastLesson = lessons.last.title;
                    final lessonRange = lessonCount == 1
                        ? firstLesson
                        : '$firstLesson - $lastLesson';
                    return Text('$lessonRange$lockedText');
                  },
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('Error loading lessons'),
                ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: onExpansionChanged,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            if (isAssessment)
              assessmentAsync!.when(
                data: (assessment) {
                  if (assessment == null) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No assessment linked to this module'),
                    );
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assessment.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade800,
                          ),
                        ),
                        if (assessment.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            assessment.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple.shade600,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: assessment.isActive
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            assessment.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: assessment.isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e'),
                ),
              )
            else
              lessonsAsync!.when(
                data: (lessons) {
                  final nextPosition = lessons.isEmpty
                      ? 1
                      : (lessons.last.displayOrder + 1);
                  return Column(
                    children: [
                      if (lessons.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No lessons in this module'),
                        )
                      else
                        ...lessons.map(
                          (lesson) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _LessonCard(lesson: lesson),
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Add Lesson button
                      SizedBox(
                        width: double.infinity,
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: AppColors.copBlue,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () async {
                                final created = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => _AddLessonDialog(
                                    moduleId: module.id,
                                    initialPosition: nextPosition,
                                  ),
                                );
                                if (created == true) {
                                  ref.invalidate(
                                    lessonsForModuleProvider(module.id),
                                  );
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: 16,
                                      color: AppColors.copBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Lesson',
                                      style: TextStyle(
                                        color: AppColors.copBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error: $e'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddLessonDialog extends ConsumerStatefulWidget {
  const _AddLessonDialog({
    required this.moduleId,
    required this.initialPosition,
  });
  final String moduleId;
  final int initialPosition;

  @override
  ConsumerState<_AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends ConsumerState<_AddLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  late final TextEditingController _positionCtrl;
  final List<StepDraft> _steps = [];
  int _currentStep = 0;
  bool _submitting = false;
  NewLesson? _createdLesson;
  LessonType _lessonType = LessonType.letter;
  @override
  void initState() {
    super.initState();
    _positionCtrl = TextEditingController(
      text: widget.initialPosition.toString(),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _positionCtrl.dispose();
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
        width: 700,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Lesson',
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
            const SizedBox(height: 16),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                type: StepperType.horizontal,
                controlsBuilder: (context, details) {
                  final isLessonStep = _currentStep == 0;
                  final isStepsStep = _currentStep == 1;
                  final canBack = _currentStep > 0;
                  final primaryLabel = isLessonStep
                      ? (_createdLesson == null ? 'Create Lesson' : 'Continue')
                      : 'Save Steps';
                  return Row(
                    children: [
                      if (canBack)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() => _currentStep -= 1),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: Color(0xFFE85D04)),
                              foregroundColor: const Color(0xFFE85D04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      if (canBack) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitting
                              ? null
                              : () async {
                                  if (isLessonStep) {
                                    await _createLesson();
                                  } else if (isStepsStep) {
                                    await _saveSteps();
                                  }
                                },
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
                              : Text(
                                  primaryLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
                steps: [
                  Step(
                    title: const Text('Lesson'),
                    isActive: _currentStep >= 0,
                    content: _buildLessonForm(enabled: _createdLesson == null),
                  ),
                  Step(
                    title: const Text('Steps'),
                    isActive: _currentStep >= 1,
                    content: _buildStepsForm(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonForm({required bool enabled}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lesson Title*',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleCtrl,
            enabled: enabled,
            decoration: InputDecoration(
              hintText: 'Enter lesson title',
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
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Lesson title is required'
                : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Position',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _positionCtrl,
                      enabled: enabled,
                      decoration: InputDecoration(
                        hintText: 'Enter position',
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
                          borderSide: const BorderSide(
                            color: Color(0xFFE85D04),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n < 1) return 'Enter a valid number';
                        return null;
                      },
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
                      'Lesson Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<LessonType>(
                      initialValue: _lessonType,
                      decoration: InputDecoration(
                        hintText: 'Select type',
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
                          borderSide: const BorderSide(
                            color: Color(0xFFE85D04),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: LessonType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.name),
                            ),
                          )
                          .toList(),
                      onChanged: enabled
                          ? (value) {
                              if (value != null) {
                                setState(() {
                                  _lessonType = value;
                                });
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!enabled) ...[
            const SizedBox(height: 12),
            Text(
              'Lesson created. Add steps below.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Lesson Steps',
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
        if (_steps.isEmpty)
          const Text('No steps added yet')
        else
          Column(
            children: [
              for (var i = 0; i < _steps.length; i++)
                _buildStepCard(_steps[i], i),
            ],
          ),
      ],
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
                  child: DropdownButtonFormField<LessonStepType>(
                    initialValue: step.stepType,
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
                    onChanged: (value) {
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

  Future<void> _createLesson() async {
    if (!_formKey.currentState!.validate()) return;
    if (_createdLesson != null) {
      setState(() => _currentStep = 1);
      return;
    }
    final title = _titleCtrl.text.trim();
    final pos = int.parse(_positionCtrl.text.trim());
    setState(() => _submitting = true);
    try {
      final input = NewLessonCreate(
        moduleId: widget.moduleId,
        title: title,
        lessonType: _lessonType,
        displayOrder: pos,
      );
      final created = await ref
          .read(saveLessonProvider.notifier)
          .create(input, const []);
      _createdLesson = created;
      if (mounted) {
        if (_steps.isEmpty) {
          _addDefaultSteps(1);
        }
        setState(() => _currentStep = 1);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create lesson: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveSteps() async {
    if (_createdLesson == null) return;
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
      await ref
          .read(saveLessonProvider.notifier)
          .updateSteps(_createdLesson!.id, inputs);
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

  void _addStep() {
    setState(() {
      _steps.add(StepDraft(position: _steps.length + 1, stepKey: ''));
    });
  }

  void _addDefaultSteps(int count) {
    for (var i = 0; i < count; i++) {
      _steps.add(StepDraft(position: _steps.length + 1, stepKey: ''));
    }
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
}

class _LessonCard extends ConsumerWidget {
  const _LessonCard({required this.lesson});
  final NewLesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLessonId = ref.watch(selectedLessonIdProvider);
    final isSelected = selectedLessonId == lesson.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Text(lesson.title),
        trailing: Text(
          lesson.lessonType.name,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        onTap: () {
          ref.read(selectedLessonIdProvider.notifier).state = lesson.id;
        },
      ),
    );
  }
}

class _CenteredHint extends StatelessWidget {
  const _CenteredHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(4),
        ),
      );

    final dashPath = Path();
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final extractPath = pathMetric.extractPath(
          distance,
          distance + dashWidth,
        );
        dashPath.addPath(extractPath, Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
