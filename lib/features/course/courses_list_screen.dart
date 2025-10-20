import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'course_models.dart';
import 'course_repository.dart';

String _fmtDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

class CoursesListScreen extends ConsumerWidget {
  const CoursesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesListProvider(null));
    final selectedCourseId = ref.watch(_selectedCourseIdProvider);

    Future<void> refreshCourses() async {
      ref.invalidate(coursesListProvider(null));
      await ref.read(coursesListProvider(null).future);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => refreshCourses(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 8),
                Text('Failed to load courses'),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: refreshCourses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return RefreshIndicator(
              onRefresh: refreshCourses,
              child: ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('No courses found')),
                ],
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: RefreshIndicator(
                  onRefresh: refreshCourses,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final Course c = courses[index];
                      return Card(
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            child: Text(_initials(c.title)),
                          ),
                          title: Text(c.title),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Wrap(
                              spacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (c.type != null && c.type!.isNotEmpty)
                                  _metaChip(
                                    context,
                                    Icons.category_outlined,
                                    c.type!,
                                  ),
                                if (c.level != null)
                                  _metaChip(
                                    context,
                                    Icons.stacked_bar_chart_outlined,
                                    'Level ${c.level}',
                                  ),
                                if (c.durationInMinutes != null)
                                  _metaChip(
                                    context,
                                    Icons.schedule,
                                    '${c.durationInMinutes} min',
                                  ),
                                if (c.updatedAt != null)
                                  _metaChip(
                                    context,
                                    Icons.update,
                                    _fmtDateTime(c.updatedAt!),
                                  ),
                              ],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (c.locked)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Icon(Icons.lock_outline, size: 18),
                                ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  // TODO: handle actions
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'modules',
                                    child: Text('View Modules'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          selected: selectedCourseId == c.id,
                          onTap: () {
                            ref.read(_selectedCourseIdProvider.notifier).state =
                                c.id;
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 3,
                child: selectedCourseId == null
                    ? const Center(
                        child: Text('Select a course to view details'),
                      )
                    : _CourseDetailView(
                        course: courses.firstWhere(
                          (c) => c.id == selectedCourseId,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: CreateCourseForm(onCreated: refreshCourses),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].isNotEmpty ? parts[0][0] : '') + (parts[1].isNotEmpty ? parts[1][0] : '');
  }

  Widget _metaChip(BuildContext context, IconData icon, String label) {
    return Chip(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      avatar: Icon(icon, size: 14),
      label: Text(label),
    );
  }
}

final _selectedCourseIdProvider = StateProvider<String?>((ref) => null);

class _CourseDetailView extends StatelessWidget {
  final Course course;
  const _CourseDetailView({required this.course});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              if (course.type != null && course.type!.isNotEmpty)
                Chip(label: Text(course.type!)),
              if (course.level != null)
                Chip(label: Text('Level ${course.level}')),
              if (course.durationInMinutes != null)
                Chip(label: Text('${course.durationInMinutes} min')),
              if (course.updatedAt != null)
                Chip(label: Text(_fmtDateTime(course.updatedAt!))),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Course Details:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(course.description ?? 'No description available.'),
        ],
      ),
    );
  }
}

class CreateCourseForm extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const CreateCourseForm({required this.onCreated, super.key});

  @override
  ConsumerState<CreateCourseForm> createState() => _CreateCourseFormState();
}

class _CreateCourseFormState extends ConsumerState<CreateCourseForm> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String type = '';
  int? level;
  int? duration;
  bool locked = false;
  bool isLoading = false;
  String? errorMsg;

  Future<void> _submit() async {
    setState(() {
      errorMsg = null;
    });
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() {
        isLoading = true;
      });
      try {
        final repo = ref.read(courseRepositoryProvider);
        await repo.createCourse(
          CourseCreate(
            title: title,
            description: description,
            type: type,
            level: level,
            durationInMinutes: duration,
            locked: locked,
          ),
        );
        Navigator.of(context).pop();
        widget.onCreated();
      } catch (e) {
        setState(() {
          errorMsg = e.toString();
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Course',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Title is required' : null,
              onSaved: (v) => title = v?.trim() ?? '',
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
              onSaved: (v) => description = v?.trim() ?? '',
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Type'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Type is required' : null,
              onSaved: (v) => type = v?.trim() ?? '',
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Level'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Level is required';
                final val = int.tryParse(v);
                if (val == null || val < 1) return 'Enter a valid level (>=1)';
                return null;
              },
              onSaved: (v) => level = int.tryParse(v ?? ''),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Duration (min)'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Duration is required';
                final val = int.tryParse(v);
                if (val == null || val < 1)
                  return 'Enter a valid duration (>=1)';
                return null;
              },
              onSaved: (v) => duration = int.tryParse(v ?? ''),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: locked,
                  onChanged: (v) => setState(() => locked = v ?? false),
                ),
                const Text('Locked'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
