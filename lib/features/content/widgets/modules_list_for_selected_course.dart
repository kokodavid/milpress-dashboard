import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../modules/modules_repository.dart';
import '../../modules/create_module_form.dart';
import '../../lesson_v2/lesson_v2_repository.dart';
import '../../lesson_v2/lesson_v2_models.dart';
import '../state/lessons_list_controller.dart';
import '../../../widgets/app_button.dart';

class ModulesListForSelectedCourse extends ConsumerStatefulWidget {
  const ModulesListForSelectedCourse({super.key});

  @override
  ConsumerState<ModulesListForSelectedCourse> createState() => _ModulesListForSelectedCourseState();
}

class _ModulesListForSelectedCourseState extends ConsumerState<ModulesListForSelectedCourse> {
  final Set<String> _expanded = <String>{};

  @override
  Widget build(BuildContext context) {
    final courseId = ref.watch(selectedCourseIdProvider);

    if (courseId == null) {
      return const _CenteredHint(text: 'Select a course to view modules and lessons');
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
    final lessonsAsync = ref.watch(lessonsForModuleProvider(module.id));
    
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
              color: AppColors.copBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${module.position}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text('Module ${module.position}'),
          subtitle: lessonsAsync.when(
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
            lessonsAsync.when(
              data: (lessons) {
                final nextPosition =
                    lessons.isEmpty ? 1 : (lessons.last.displayOrder + 1);
                return Column(
                  children: [
                    if (lessons.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No lessons in this module'),
                      )
                    else
                      ...lessons.map((lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _LessonCard(lesson: lesson),
                      )),
                    const SizedBox(height: 8),
                    // Add Lesson button
                    SizedBox(
                      width: double.infinity,
                      child: CustomPaint(
                        painter: DashedBorderPainter(color: AppColors.copBlue),
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
                                ref.invalidate(lessonsForModuleProvider(module.id));
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 16, color: AppColors.copBlue),
                                  const SizedBox(width: 8),
                                  Text('Add Lesson', style: TextStyle(color: AppColors.copBlue)),
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
  const _AddLessonDialog({required this.moduleId, required this.initialPosition});
  final String moduleId;
  final int initialPosition;

  @override
  ConsumerState<_AddLessonDialog> createState() => _AddLessonDialogState();
}

class _AddLessonDialogState extends ConsumerState<_AddLessonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  late final TextEditingController _positionCtrl;
  final List<_StepDraft> _steps = [];
  int _currentStep = 0;
  bool _submitting = false;
  NewLesson? _createdLesson;
  LessonType _lessonType = LessonType.letter;
  static const List<String> _stepKeyOptions = [
    'sound',
    'example',
    'exercise',
    'formation',
  ];
  static const List<LessonStepType> _forcedStepTypes = [
    LessonStepType.introduction,
    LessonStepType.demonstration,
    LessonStepType.practice,
    LessonStepType.assessment,
  ];
  static const List<String> _forcedStepTitles = [
    'Pronounciation',
    'Letter Formation',
    'Example Words',
    'Exercise',
  ];

  @override
  void initState() {
    super.initState();
    _positionCtrl = TextEditingController(text: widget.initialPosition.toString());
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  onPressed: _submitting ? null : () => Navigator.of(context).pop(),
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
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(primaryLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  )),
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
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Lesson title is required' : null,
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
                          borderSide: const BorderSide(color: Color(0xFFE85D04)),
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
                      value: _lessonType,
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
                          borderSide: const BorderSide(color: Color(0xFFE85D04)),
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

  Widget _buildStepCard(_StepDraft step, int index) {
    final isForcedType = index < _forcedStepTypes.length;
    final isForcedKey = index < _stepKeyOptions.length;
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
                  onPressed: index == 0 ? null : () => _moveStep(index, index - 1),
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
                    value: _stepKeyOptions.contains(step.stepKeyCtrl.text)
                        ? step.stepKeyCtrl.text
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Step Key',
                      border: OutlineInputBorder(),
                    ),
                    items: _stepKeyOptions
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

  Widget _buildStepTypeFields(_StepDraft step) {
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

  Widget _buildIntroductionFields(_StepDraft step, {required bool lockTitle}) {
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

  Widget _buildDemonstrationFields(_StepDraft step, {required bool lockTitle}) {
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

  Widget _buildPracticeFields(_StepDraft step, {required bool lockTitle}) {
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

  Widget _buildAssessmentFields(_StepDraft step, {required bool lockTitle}) {
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
    required _PracticeItemDraft item,
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
    required _AssessmentOptionDraft option,
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
      final created = await ref.read(saveLessonProvider.notifier).create(input, const []);
      _createdLesson = created;
      if (mounted) {
        if (_steps.isEmpty) {
          _addDefaultSteps(4);
          _applyForcedRules();
        }
        setState(() => _currentStep = 1);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create lesson: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveSteps() async {
    if (_createdLesson == null) return;
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
      await ref.read(saveLessonProvider.notifier).updateSteps(
            _createdLesson!.id,
            inputs,
          );
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

  void _addStep() {
    setState(() {
      _steps.add(_StepDraft(
        position: _steps.length + 1,
        stepKey: _stepKeyOptions.first,
      ));
      _applyForcedRules();
    });
  }

  void _addDefaultSteps(int count) {
    for (var i = 0; i < count; i++) {
      _steps.add(_StepDraft(
        position: _steps.length + 1,
        stepKey: _stepKeyOptions.first,
      ));
    }
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
    for (var i = 0; i < _steps.length && i < _forcedStepTypes.length; i++) {
      _steps[i].stepType = _forcedStepTypes[i];
      _steps[i].stepKeyCtrl.text = _stepKeyOptions[i];
      if (i < _forcedStepTitles.length) {
        _steps[i].titleCtrl.text = _forcedStepTitles[i];
      }
    }
  }

  bool _isLockedTitle(_StepDraft step) =>
      (step.position - 1) < _forcedStepTitles.length;
}

class _StepDraft {
  _StepDraft({
    required int position,
    required String stepKey,
  })  : position = position,
        stepType = LessonStepType.introduction,
        stepKeyCtrl = TextEditingController(text: stepKey),
        titleCtrl = TextEditingController(),
        displayTextCtrl = TextEditingController(),
        audioBaseUrlCtrl = TextEditingController(),
        audio05Ctrl = TextEditingController(),
        audio1Ctrl = TextEditingController(),
        audio15Ctrl = TextEditingController(),
        howToSvgUrlCtrl = TextEditingController(),
        practiceTipTextCtrl = TextEditingController(),
        practiceTipAudioCtrl = TextEditingController(),
        feedbackTitleCtrl = TextEditingController(),
        feedbackBodyCtrl = TextEditingController(),
        tipTextCtrl = TextEditingController(),
        tipSoundCtrl = TextEditingController(),
        promptCtrl = TextEditingController(),
        soundInstructionCtrl = TextEditingController();

  int position;
  LessonStepType stepType;
  bool required = true;

  final TextEditingController stepKeyCtrl;
  final TextEditingController titleCtrl;

  final TextEditingController displayTextCtrl;
  final TextEditingController audioBaseUrlCtrl;
  final TextEditingController audio05Ctrl;
  final TextEditingController audio1Ctrl;
  final TextEditingController audio15Ctrl;
  final TextEditingController howToSvgUrlCtrl;
  final TextEditingController practiceTipTextCtrl;
  final TextEditingController practiceTipAudioCtrl;

  final TextEditingController feedbackTitleCtrl;
  final TextEditingController feedbackBodyCtrl;
  final List<TextEditingController> imageUrlCtrls = [];

  final List<_PracticeItemDraft> practiceItems = [];
  final TextEditingController tipTextCtrl;
  final TextEditingController tipSoundCtrl;

  final TextEditingController promptCtrl;
  final TextEditingController soundInstructionCtrl;
  final List<_AssessmentOptionDraft> assessmentOptions = [];

  void setStepType(LessonStepType type) {
    stepType = type;
    if (type == LessonStepType.demonstration && imageUrlCtrls.isEmpty) {
      addImageUrl();
    }
    if (type == LessonStepType.practice && practiceItems.isEmpty) {
      addPracticeItem();
    }
    if (type == LessonStepType.assessment && assessmentOptions.isEmpty) {
      addAssessmentOption();
    }
  }

  void addImageUrl() => imageUrlCtrls.add(TextEditingController());
  void removeImageUrl(int index) {
    imageUrlCtrls[index].dispose();
    imageUrlCtrls.removeAt(index);
  }

  void addPracticeItem() => practiceItems.add(_PracticeItemDraft());
  void removePracticeItem(int index) {
    practiceItems[index].dispose();
    practiceItems.removeAt(index);
  }

  void addAssessmentOption() => assessmentOptions.add(_AssessmentOptionDraft());
  void removeAssessmentOption(int index) {
    assessmentOptions[index].dispose();
    assessmentOptions.removeAt(index);
  }

  LessonStepInput toInput() {
    return LessonStepInput(
      stepKey: stepKeyCtrl.text.trim(),
      stepType: stepType,
      position: position,
      required: required,
      config: _buildConfig(),
    );
  }

  Map<String, dynamic> _buildConfig() {
    switch (stepType) {
      case LessonStepType.introduction:
        final speedVariants = <String, String>{};
        if (audio05Ctrl.text.trim().isNotEmpty) {
          speedVariants['0.5x'] = audio05Ctrl.text.trim();
        }
        if (audio1Ctrl.text.trim().isNotEmpty) {
          speedVariants['1x'] = audio1Ctrl.text.trim();
        }
        if (audio15Ctrl.text.trim().isNotEmpty) {
          speedVariants['1.5x'] = audio15Ctrl.text.trim();
        }
        final audio = <String, dynamic>{};
        if (audioBaseUrlCtrl.text.trim().isNotEmpty) {
          audio['base_url'] = audioBaseUrlCtrl.text.trim();
        }
        if (speedVariants.isNotEmpty) {
          audio['speed_variants'] = speedVariants;
        }
        final practiceTip = <String, dynamic>{};
        if (practiceTipTextCtrl.text.trim().isNotEmpty) {
          practiceTip['text'] = practiceTipTextCtrl.text.trim();
        }
        if (practiceTipAudioCtrl.text.trim().isNotEmpty) {
          practiceTip['audio_url'] = practiceTipAudioCtrl.text.trim();
        }
        return {
          'title': titleCtrl.text.trim(),
          'display_text': displayTextCtrl.text.trim(),
          if (audio.isNotEmpty) 'audio': audio,
          if (howToSvgUrlCtrl.text.trim().isNotEmpty)
            'how_to_svg_url': howToSvgUrlCtrl.text.trim(),
          if (practiceTip.isNotEmpty) 'practice_tip': practiceTip,
        };
      case LessonStepType.demonstration:
        final images = imageUrlCtrls
            .map((c) => c.text.trim())
            .where((v) => v.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          if (images.isNotEmpty) 'image_urls': images,
          if (feedbackTitleCtrl.text.trim().isNotEmpty)
            'feedbackTitle': feedbackTitleCtrl.text.trim(),
          if (feedbackBodyCtrl.text.trim().isNotEmpty)
            'feedbackBody': feedbackBodyCtrl.text.trim(),
        };
      case LessonStepType.practice:
        final items = practiceItems
            .map((item) => item.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        final tip = <String, dynamic>{};
        if (tipTextCtrl.text.trim().isNotEmpty) {
          tip['text'] = tipTextCtrl.text.trim();
        }
        if (tipSoundCtrl.text.trim().isNotEmpty) {
          tip['sound_url'] = tipSoundCtrl.text.trim();
        }
        return {
          'title': titleCtrl.text.trim(),
          if (items.isNotEmpty) 'items': items,
          if (tip.isNotEmpty) 'tip': tip,
        };
      case LessonStepType.assessment:
        final options = assessmentOptions
            .map((option) => option.toMap())
            .where((m) => m.isNotEmpty)
            .toList();
        return {
          'title': titleCtrl.text.trim(),
          'prompt': promptCtrl.text.trim(),
          if (soundInstructionCtrl.text.trim().isNotEmpty)
            'sound_instruction_url': soundInstructionCtrl.text.trim(),
          if (options.isNotEmpty) 'options': options,
        };
    }
  }

  void dispose() {
    stepKeyCtrl.dispose();
    titleCtrl.dispose();
    displayTextCtrl.dispose();
    audioBaseUrlCtrl.dispose();
    audio05Ctrl.dispose();
    audio1Ctrl.dispose();
    audio15Ctrl.dispose();
    howToSvgUrlCtrl.dispose();
    practiceTipTextCtrl.dispose();
    practiceTipAudioCtrl.dispose();
    feedbackTitleCtrl.dispose();
    feedbackBodyCtrl.dispose();
    for (final ctrl in imageUrlCtrls) {
      ctrl.dispose();
    }
    for (final item in practiceItems) {
      item.dispose();
    }
    tipTextCtrl.dispose();
    tipSoundCtrl.dispose();
    promptCtrl.dispose();
    soundInstructionCtrl.dispose();
    for (final option in assessmentOptions) {
      option.dispose();
    }
  }
}

class _PracticeItemDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  final TextEditingController soundUrlCtrl = TextEditingController();

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (labelCtrl.text.trim().isNotEmpty) {
      map['label'] = labelCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    if (soundUrlCtrl.text.trim().isNotEmpty) {
      map['sound_url'] = soundUrlCtrl.text.trim();
    }
    return map;
  }

  void dispose() {
    labelCtrl.dispose();
    imageUrlCtrl.dispose();
    soundUrlCtrl.dispose();
  }
}

class _AssessmentOptionDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController imageUrlCtrl = TextEditingController();
  bool isCorrect = false;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (labelCtrl.text.trim().isNotEmpty) {
      map['label'] = labelCtrl.text.trim();
    }
    if (imageUrlCtrl.text.trim().isNotEmpty) {
      map['image_url'] = imageUrlCtrl.text.trim();
    }
    map['is_correct'] = isCorrect;
    return map;
  }

  void dispose() {
    labelCtrl.dispose();
    imageUrlCtrl.dispose();
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
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ));

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
