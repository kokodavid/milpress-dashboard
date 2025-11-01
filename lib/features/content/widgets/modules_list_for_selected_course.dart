import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../../modules/modules_repository.dart';
import '../../modules/create_module_form.dart';
import '../../lesson/lessons_repository.dart';
import '../../lesson/lesson_models.dart';
import '../state/lessons_list_controller.dart';

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
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                        child: DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.8,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          builder: (_, __) => CreateModuleForm(
                            courseId: courseId,
                            initialPosition: nextPosition,
                            onCreated: () {
                              // refresh after creation
                              ref.invalidate(modulesForCourseProvider(courseId));
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Module'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
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
                final nextPosition = lessons.isEmpty ? 1 : (lessons.last.position + 1);
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
                              final created = await showModalBottomSheet<bool>(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) => Padding(
                                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                                  child: SizedBox(
                                    height: MediaQuery.of(ctx).size.height * 0.85,
                                    child: _AddLessonSheet(
                                      moduleId: module.id,
                                      initialPosition: nextPosition,
                                    ),
                                  ),
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

class _AddLessonSheet extends ConsumerStatefulWidget {
  const _AddLessonSheet({required this.moduleId, required this.initialPosition});
  final String moduleId;
  final int initialPosition;

  @override
  ConsumerState<_AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends ConsumerState<_AddLessonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  late final TextEditingController _positionCtrl;
  final _durationCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _audioCtrl = TextEditingController();
  final _thumbCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _positionCtrl = TextEditingController(text: widget.initialPosition.toString());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _positionCtrl.dispose();
    _durationCtrl.dispose();
    _videoCtrl.dispose();
    _audioCtrl.dispose();
    _thumbCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Lesson')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _positionCtrl,
                        decoration: const InputDecoration(labelText: 'Position *', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = int.tryParse(v);
                          if (n == null || n < 1) return 'Enter a valid number';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _durationCtrl,
                        decoration: const InputDecoration(labelText: 'Duration (min)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _thumbCtrl,
                  decoration: const InputDecoration(labelText: 'Thumbnail URL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _videoCtrl,
                  decoration: const InputDecoration(labelText: 'Video URL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _audioCtrl,
                  decoration: const InputDecoration(labelText: 'Audio URL', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentCtrl,
                  decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check),
                  label: const Text('Create'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleCtrl.text.trim();
    final pos = int.parse(_positionCtrl.text.trim());
    final duration = _durationCtrl.text.trim().isEmpty ? null : int.tryParse(_durationCtrl.text.trim());
    setState(() => _submitting = true);
    try {
      final input = LessonCreate(
        moduleId: widget.moduleId,
        title: title,
        position: pos,
        content: _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        videoUrl: _videoCtrl.text.trim().isEmpty ? null : _videoCtrl.text.trim(),
        audioUrl: _audioCtrl.text.trim().isEmpty ? null : _audioCtrl.text.trim(),
        durationMinutes: duration,
        thumbnails: _thumbCtrl.text.trim().isEmpty ? null : _thumbCtrl.text.trim(),
      );
      await ref.read(createLessonProvider.notifier).create(input);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create lesson: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _LessonCard extends ConsumerWidget {
  const _LessonCard({required this.lesson});
  final Lesson lesson;

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
        trailing: lesson.durationMinutes != null 
            ? Text('${lesson.durationMinutes}min', style: TextStyle(color: Colors.grey.shade600))
            : null,
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
