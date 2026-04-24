import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../modules/modules_repository.dart';
import '../../modules/create_module_form.dart';
import '../../lesson_v2/lesson_v2_repository.dart';
import '../../lesson_v2/lesson_v2_models.dart';
import '../../assessment_v2/assessment_v2_repository.dart';
import '../state/lessons_list_controller.dart';
import '../../../widgets/app_button.dart';

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
                                final createdLessonId =
                                    await showDialog<String>(
                                      context: context,
                                      builder: (ctx) => _AddLessonDialog(
                                        moduleId: module.id,
                                        initialPosition: nextPosition,
                                      ),
                                    );
                                if (createdLessonId != null) {
                                  ref.invalidate(
                                    lessonsForModuleProvider(module.id),
                                  );
                                  ref
                                          .read(
                                            selectedLessonIdProvider.notifier,
                                          )
                                          .state =
                                      createdLessonId;
                                  if (!context.mounted) return;
                                  context.go('/lessons/$createdLessonId/steps');
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
  bool _submitting = false;
  LessonType _lessonType = LessonType.letter;

  static const _orange = Color(0xFFE85D04);

  @override
  void initState() {
    super.initState();
    _positionCtrl = TextEditingController(
      text: widget.initialPosition.toString(),
    );
    _titleCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _positionCtrl.dispose();
    super.dispose();
  }

  bool get _step1Ready =>
      _titleCtrl.text.trim().isNotEmpty &&
      (int.tryParse(_positionCtrl.text.trim()) ?? 0) >= 1;

  @override
  Widget build(BuildContext context) {
    final displayTitle = _titleCtrl.text.trim().isEmpty
        ? 'New Lesson'
        : _titleCtrl.text.trim();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW LESSON',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    color: Colors.grey.shade500,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Step indicator ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _buildStepIndicator(),
            ),

            const SizedBox(height: 4),
            Divider(color: Colors.grey.shade200, height: 1),

            // ── Body ────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                child: _buildLessonForm(),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Divider(color: Colors.grey.shade200, height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _StepChip(
          stepNumber: 1,
          label: 'Lesson details',
          isActive: true,
          isDone: false,
          badge: _step1Ready ? 'Ready' : null,
          badgeColor: const Color(0xFF22C55E),
        ),
        Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.grey.shade300,
          ),
        ),
        _StepChip(
          stepNumber: 2,
          label: 'Builder',
          isActive: false,
          isDone: false,
          badge: null,
          badgeColor: Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 20, 18),
      child: Row(
        children: [
          // Status text
          Icon(Icons.check_circle, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Text(
            'Ready to publish',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            'Draft autosaved',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          const Spacer(),
          // Cancel
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          // Primary action
          ElevatedButton(
            onPressed: _submitting ? null : _createLesson,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Continue to builder',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 15),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lesson title field
          Text(
            'Lesson title *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Vowel /a/ — introduction',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: _orange),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Lesson title is required'
                : null,
          ),
          const SizedBox(height: 18),

          // Position + Lesson type row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Position
              SizedBox(
                width: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Position',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _positionCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: _orange),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
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
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Order within this module',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Lesson type — pill buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _LessonTypePicker(
                      selected: _lessonType,
                      enabled: true,
                      onChanged: (t) => setState(() => _lessonType = t),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _createLesson() async {
    if (!_formKey.currentState!.validate()) return;
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
      if (created == null) return;
      if (mounted) {
        Navigator.of(context).pop(created.id);
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
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isDone,
    this.badge,
    this.badgeColor,
  });

  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isDone;
  final String? badge;
  final Color? badgeColor;

  static const _orange = Color(0xFFE85D04);

  @override
  Widget build(BuildContext context) {
    final circleColor = isActive || isDone ? _orange : Colors.grey.shade300;
    final textColor = isActive || isDone ? Colors.black : Colors.grey.shade500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (badge != null)
              Text(
                badge!,
                style: TextStyle(
                  fontSize: 11,
                  color: badgeColor ?? Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LessonTypePicker extends StatelessWidget {
  const _LessonTypePicker({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final LessonType selected;
  final bool enabled;
  final ValueChanged<LessonType> onChanged;

  static const _orange = Color(0xFFE85D04);

  static String _label(LessonType t) {
    switch (t) {
      case LessonType.letter:
        return 'Letter';
      case LessonType.word:
        return 'Word';
      case LessonType.sentence:
        return 'Sentence';
    }
  }

  static String _sublabel(LessonType t) {
    switch (t) {
      case LessonType.letter:
        return 'Single-letter foc…';
      case LessonType.word:
        return 'Whole-word rea…';
      case LessonType.sentence:
        return 'Sentence-level';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: LessonType.values.map((type) {
        final isSelected = type == selected;
        return Expanded(
          child: GestureDetector(
            onTap: enabled ? () => onChanged(type) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                right: type != LessonType.sentence ? 6 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF4EE) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? _orange : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(type),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _orange : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _sublabel(type),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? _orange.withOpacity(0.75)
                          : Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
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
