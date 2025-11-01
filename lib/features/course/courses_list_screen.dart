import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'course_models.dart';
import 'course_repository.dart';
import 'create_course_form.dart';
import 'course_detail_view.dart';
import '../../widgets/search_input.dart';
import '../../utils/app_colors.dart';

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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: refreshCourses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
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
                flex: 30,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.faintGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: refreshCourses,
                    child: Builder(
                    builder: (context) {
                      final query = searchQuery.trim().toLowerCase();
                      final List<Course> filteredCourses = query.isEmpty
                          ? courses
                          : courses
                                .where(
                                  (course) => course.title
                                      .toLowerCase()
                                      .contains(query),
                                )
                                .toList();

                      final items = <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                          child: SearchInput(
                            hintText: 'Search',
                            initialValue: searchQuery,
                            onChanged: (value) =>
                                ref
                                        .read(
                                          _courseSearchQueryProvider.notifier,
                                        )
                                        .state =
                                    value,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Text(
                            'Showing ${filteredCourses.length} of ${courses.length} courses',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ];

                      if (filteredCourses.isEmpty) {
                        items.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 48,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.search_off,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No courses match your search.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      ref
                                              .read(
                                                _courseSearchQueryProvider
                                                    .notifier,
                                              )
                                              .state =
                                          '',
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    ref
                                        .read(
                                          _selectedCourseIdProvider.notifier,
                                        )
                                        .state = course
                                        .id;
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Course title
                                        Text(
                                          course.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.darkGrey,
                                                fontSize: 16,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),

                                        // Status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: course.locked 
                                                ? Colors.orange.shade100
                                                : Colors.green.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            course.locked ? 'Draft' : 'Published',
                                            style: TextStyle(
                                              color: course.locked 
                                                  ? Colors.orange.shade700
                                                  : Colors.green.shade700,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Meta information row
                                        Row(
                                          children: [
                                            if (course.type != null &&
                                                course.type!.isNotEmpty) ...[
                                              Icon(
                                                Icons.circle,
                                                size: 12,
                                                color: AppColors.grey,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                course.type!,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                            ],
                                            if (course.durationInMinutes !=
                                                null) ...[
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${course.durationInMinutes} min',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                            ],
                                            if (course.locked) ...[
                                              Icon(
                                                Icons.lock_outline,
                                                size: 16,
                                                color: AppColors.primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Locked',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.orange.shade600,
                                                ),
                                              ),
                                            ],
                                          ],
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
              ),
              Expanded(
                flex: 70,
                child: selectedCourseId == null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.faintGrey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Select Course to view\ndetails',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
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
                          ref.read(_selectedCourseIdProvider.notifier).state =
                              null;
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
            builder: (context) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Dialog(
                  insetPadding: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: CreateCourseForm(onCreated: refreshCourses),
                  ),
                ),
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white
        ),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}

final _selectedCourseIdProvider = StateProvider<String?>((ref) => null);
final _courseSearchQueryProvider = StateProvider<String>((ref) => '');
