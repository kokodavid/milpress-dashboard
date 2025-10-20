import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'course_models.dart';
import 'course_repository.dart';
import 'create_course_form.dart';
import 'course_detail_view.dart';
import '../../widgets/search_input.dart';

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
    final searchQuery = ref.watch(_courseSearchQueryProvider);

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
                  child: Builder(
                    builder: (context) {
                      final query = searchQuery.trim().toLowerCase();
            final List<Course> filteredCourses = query.isEmpty
                          ? courses
                          : courses
                              .where((course) => course.title.toLowerCase().contains(query))
                              .toList();

                      final items = <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                          child: SearchInput(
                            hintText: 'Search courses',
                            initialValue: searchQuery,
                            onChanged: (value) => ref.read(_courseSearchQueryProvider.notifier).state = value,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Text(
                            'Showing ${filteredCourses.length} of ${courses.length} courses',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ];

                      if (filteredCourses.isEmpty) {
                        items.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 48),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off, size: 36, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(
                                  'No courses match your search.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      ref.read(_courseSearchQueryProvider.notifier).state = '',
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Clear search'),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        for (var i = 0; i < filteredCourses.length; i++) {
                          final course = filteredCourses[i];
                          final isSelected = selectedCourseId == course.id;
                          items.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withAlpha(12)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    ref.read(_selectedCourseIdProvider.notifier).state = course.id;
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              Theme.of(context).colorScheme.primary.withAlpha(30),
                                          child: Text(
                                            _initials(course.title),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 18),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course.title,
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected
                                                          ? Theme.of(context).colorScheme.primary
                                                          : Colors.black87,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 10,
                                                runSpacing: 4,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  if (course.type != null && course.type!.isNotEmpty)
                                                    _metaChip(
                                                      context,
                                                      Icons.category_outlined,
                                                      course.type!,
                                                    ),
                                                  if (course.level != null)
                                                    _metaChip(
                                                      context,
                                                      Icons.stacked_bar_chart_outlined,
                                                      'Level ${course.level}',
                                                    ),
                                                  if (course.durationInMinutes != null)
                                                    _metaChip(
                                                      context,
                                                      Icons.schedule,
                                                      '${course.durationInMinutes} min',
                                                    ),
                                                  if (course.updatedAt != null)
                                                    _metaChip(
                                                      context,
                                                      Icons.update,
                                                      _fmtDateTime(course.updatedAt!),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (course.locked)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12.0),
                                            child: Icon(
                                              Icons.lock_outline,
                                              size: 22,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                          if (i != filteredCourses.length - 1) {
                            items.add(const SizedBox(height: 8));
                          }
                        }
                      }

                      items.add(const SizedBox(height: 24));

                      return ListView(
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: items,
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
                    : CourseDetailView(
                        course: courses.firstWhere(
                          (c) => c.id == selectedCourseId,
                        ),
                        onRefresh: () async {
                          await refreshCourses();
                        },
                        onDeleted: () async {
                          // Clear selection and refresh list
                          ref.read(_selectedCourseIdProvider.notifier).state = null;
                          await refreshCourses();
                        },
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
final _courseSearchQueryProvider = StateProvider<String>((ref) => '');

