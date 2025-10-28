import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      modules.isEmpty ? 'No modules yet for this course' : 'Modules',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: modules.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = modules[index];
                  final isExpanded = _expanded.contains(m.id);
                  return Card.filled(
                    child: ExpansionTile(
                      leading: CircleAvatar(child: Text('${m.position}')),
                      title: Text('Module ${m.position}'),
                      subtitle: (m.description != null && m.description!.isNotEmpty)
                          ? Text(m.description!)
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (m.locked) const Tooltip(message: 'Locked', child: Icon(Icons.lock_outline)),
                        ],
                      ),
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expanded.add(m.id);
                          } else {
                            _expanded.remove(m.id);
                          }
                        });
                      },
                      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                      children: [
                        if (!isExpanded)
                          const SizedBox.shrink()
                        else
                          _LessonsForModule(moduleId: m.id),
                      ],
                    ),
                  );
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

class _LessonsForModule extends ConsumerWidget {
  const _LessonsForModule({required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForModuleProvider(moduleId));
    return lessonsAsync.when(
      data: (lessons) {
        final nextPosition = lessons.isEmpty ? 1 : (lessons.last.position + 1);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    final created = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (ctx) => Padding(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                        child: SizedBox(
                          height: MediaQuery.of(ctx).size.height * 0.85,
                          child: _AddLessonSheet(
                            moduleId: moduleId,
                            initialPosition: nextPosition,
                          ),
                        ),
                      ),
                    );
                    if (created == true) {
                      ref.invalidate(lessonsForModuleProvider(moduleId));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Lesson'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (lessons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No lessons in this module'),
                ),
              )
            else
              ...[
                for (final l in lessons) _LessonRow(lesson: l),
              ],
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(12.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            const Expanded(child: Text('Failed to load lessons')),
            TextButton.icon(
              onPressed: () => ref.refresh(lessonsForModuleProvider(moduleId)),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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

class _LessonRow extends ConsumerWidget {
  const _LessonRow({required this.lesson});
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
      leading: const SizedBox(width: 4),
      title: Text(lesson.title),
      subtitle: Row(
        children: [
          Text('Position ${lesson.position}'),
          if (lesson.durationMinutes != null) ...[
            const SizedBox(width: 12),
            Text('${lesson.durationMinutes} min'),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ref.read(selectedLessonIdProvider.notifier).state = lesson.id;
      },
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
