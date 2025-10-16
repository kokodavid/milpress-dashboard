import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'course_models.dart';
import 'course_repository.dart';

class CoursesListScreen extends ConsumerWidget {
  const CoursesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesListProvider(null));

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
          return RefreshIndicator(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            _metaChip(context, Icons.category_outlined, c.type!),
                          if (c.level != null)
                            _metaChip(context, Icons.stacked_bar_chart_outlined, 'Level ${c.level}'),
                          if (c.durationInMinutes != null)
                            _metaChip(context, Icons.schedule, '${c.durationInMinutes} min'),
                          if (c.updatedAt != null)
                            _metaChip(context, Icons.update, _fmtDateTime(c.updatedAt!)),
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
                            // e.g., navigate to modules for this course, edit, delete
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'modules', child: Text('View Modules')),
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to Create Course screen
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

  String _fmtDateTime(DateTime dt) {
    // Keep it simple without introducing additional dependencies
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
