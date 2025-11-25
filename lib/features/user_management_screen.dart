import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_colors.dart';
import '../widgets/search_input.dart' as shell_search; // avoid name clash if needed
import 'auth/profile_models.dart';
import 'auth/profiles_repository.dart';
import 'user_progress/user_progress_repository.dart';
import 'user_progress/user_progress_models.dart';
import 'course/course_repository.dart';
import 'modules/modules_repository.dart';
import 'lesson/lessons_repository.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(profilesListProvider(null));
    final selectedUserId = ref.watch(_selectedUserIdProvider);
    final searchQuery = ref.watch(_userSearchQueryProvider);

    Future<void> refreshUsers() async {
      ref.invalidate(profilesListProvider(null));
      await ref.read(profilesListProvider(null).future);
    }

    return Scaffold(
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 8),
                const Text('Failed to load users'),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: refreshUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (users) {
          return Row(
            children: [
              // Left panel: list & filters
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
                    onRefresh: refreshUsers,
                    child: Builder(
                      builder: (context) {
                        final query = searchQuery.trim().toLowerCase();
                        final List<Profile> filtered = query.isEmpty
                            ? users
                            : users
                                .where((p) =>
                                    (p.fullName.toLowerCase()).contains(query) ||
                                    (p.email ?? '').toLowerCase().contains(query))
                                .toList();

                        final items = <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                            child: shell_search.SearchInput(
                              hintText: 'Search users by name or email',
                              initialValue: searchQuery,
                              onChanged: (value) =>
                                  ref.read(_userSearchQueryProvider.notifier).state = value,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Text(
                              'Showing ${filtered.length} of ${users.length} users',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ];

                        if (filtered.isEmpty) {
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
                                    'No users match your search.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        ref.read(_userSearchQueryProvider.notifier).state = '',
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Clear search'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          for (var i = 0; i < filtered.length; i++) {
                            final user = filtered[i];
                            final isSelected = selectedUserId == user.id;
                            items.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                    onTap: () => ref
                                        .read(_selectedUserIdProvider.notifier)
                                        .state = user.id,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                child: Text(
                                                  _initials(user.fullName.isNotEmpty
                                                      ? user.fullName
                                                      : (user.email ?? 'U')),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  user.fullName.isNotEmpty
                                                      ? user.fullName
                                                      : (user.email ?? 'Unnamed User'),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.darkGrey,
                                                        fontSize: 16,
                                                      ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((user.email ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.mail_outline,
                                                  size: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    user.email!,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                            if (i != filtered.length - 1) {
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

              // Right panel: placeholder for details
              Expanded(
                flex: 70,
                child: selectedUserId == null
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
                            'Select a user to view\ndetails',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : UserDetailsView(userId: selectedUserId),
              ),
            ],
          );
        },
      ),
    );
  }

  String _initials(String str) {
    final parts = str.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class UserDetailsView extends ConsumerWidget {
  final String userId;
  const UserDetailsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final courseProgressAsync = ref.watch(courseProgressForUserProvider(userId));
    final moduleProgressAsync = ref.watch(moduleProgressForUserProvider(userId));
    final lessonProgressAsync = ref.watch(lessonProgressForUserProvider(userId));

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBox(message: 'Failed to load user: $e'),
      data: (profile) {
        if (profile == null) return const Center(child: Text('User not found'));

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text(
                      _initials(profile.fullName.isNotEmpty ? profile.fullName : (profile.email ?? 'U')),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty ? profile.fullName : (profile.email ?? profile.id),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((profile.email ?? '').isNotEmpty)
                          Text(
                            profile.email!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Progress Summary Section
              _ProgressSummary(courseProgressAsync: courseProgressAsync, moduleProgressAsync: moduleProgressAsync, lessonProgressAsync: lessonProgressAsync),
              const SizedBox(height: 24),
              Text(
                'Course progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _CourseProgressList(
                  courseProgressAsync: courseProgressAsync,
                  moduleProgressAsync: moduleProgressAsync,
                  lessonProgressAsync: lessonProgressAsync,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _initials(String str) {
  final parts = str.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(message, style: TextStyle(color: Colors.red.shade800)),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  final AsyncValue<List<CourseProgress>> courseProgressAsync;
  final AsyncValue<List<ModuleProgress>> moduleProgressAsync;
  final AsyncValue<List<LessonProgress>> lessonProgressAsync;
  const _ProgressSummary({
    required this.courseProgressAsync,
    required this.moduleProgressAsync,
    required this.lessonProgressAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SummaryTile(
          label: 'Courses',
          value: courseProgressAsync.when(
            data: (d) => d.length.toString(),
            loading: () => '...',
            error: (_, __) => '-',
          ),
          extra: courseProgressAsync.when(
            data: (d) => '${d.where((c) => c.isCompleted == true).length} completed',
            loading: () => '',
            error: (_, __) => '',
          ),
          icon: Icons.school,
          color: Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryTile(
          label: 'Modules',
          value: moduleProgressAsync.when(
            data: (d) => d.length.toString(),
            loading: () => '...',
            error: (_, __) => '-',
          ),
          extra: moduleProgressAsync.when(
            data: (d) => '${d.where((m) => m.status == 'completed').length} completed',
            loading: () => '',
            error: (_, __) => '',
          ),
          icon: Icons.view_module,
          color: Colors.orange,
        )),
        const SizedBox(width: 12),
        Expanded(child: _SummaryTile(
          label: 'Lessons',
          value: lessonProgressAsync.when(
            data: (d) => d.length.toString(),
            loading: () => '...',
            error: (_, __) => '-',
          ),
          extra: lessonProgressAsync.when(
            data: (d) => '${d.where((l) => l.isCompleted).length} completed',
            loading: () => '',
            error: (_, __) => '',
          ),
          icon: Icons.menu_book,
          color: Colors.green,
        )),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String extra;
  final IconData icon;
  final Color color;
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.extra,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0,2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (extra.isNotEmpty) Text(extra, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CourseProgressList extends ConsumerWidget {
  final AsyncValue<List<CourseProgress>> courseProgressAsync;
  final AsyncValue<List<ModuleProgress>> moduleProgressAsync;
  const _CourseProgressList({
    required this.courseProgressAsync,
    required this.moduleProgressAsync,
    required AsyncValue<List<LessonProgress>> lessonProgressAsync, // kept for future use but no longer displayed
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final expanded = ref.watch(_expandedCoursesProvider);
    return courseProgressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorBox(message: 'Failed to load course progress: $e'),
      data: (courses) {
        // Gather modules per course to compute completion percentages
        final modulesByCourse = moduleProgressAsync.maybeWhen(
          data: (mods) => _groupBy<String, ModuleProgress>(mods, (m) => m.courseProgressId ?? ''),
          orElse: () => <String, List<ModuleProgress>>{},
        );

        // Consider only ongoing courses
        final inProgress = courses.where((c) => c.isCompleted != true).toList();
        if (inProgress.isEmpty) {
          return const Center(child: Text('No course in progress'));
        }

        // Pick only the single course with the most notable progress
        const threshold = 0.05; // 5%+ counts as notable
        CourseProgress? selected;
        double selectedPercent = -1;

        double percentFor(CourseProgress cp) {
          final modules = modulesByCourse[cp.id] ?? const [];
          final totalLessons = modules.fold<int>(0, (sum, m) => sum + (m.totalLessons ?? 0));
          final completedLessons = modules.fold<int>(0, (sum, m) => sum + (m.completedLessons ?? 0));
          if (totalLessons <= 0) return 0;
          return (completedLessons / totalLessons).clamp(0.0, 1.0);
        }

        // First, look for courses above threshold and pick the highest percent
        for (final cp in inProgress) {
          final p = percentFor(cp);
          if (p >= threshold && p > selectedPercent) {
            selected = cp;
            selectedPercent = p;
          }
        }

        // If none meet threshold, pick the highest non-zero; else nothing
        if (selected == null) {
          for (final cp in inProgress) {
            final p = percentFor(cp);
            if (p > 0 && p > selectedPercent) {
              selected = cp;
              selectedPercent = p;
            }
          }
        }

        if (selected == null) {
          return const Center(child: Text('No notable course progress yet'));
        }

        return ListView.separated(
          itemCount: 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final cp = selected!;
              final modules = modulesByCourse[cp.id] ?? const [];
              // Completed counts from user progress tables
              final completedLessons = modules.fold<int>(0, (sum, m) => sum + (m.completedLessons ?? 0));
              final completedModules = modules.where((m) => m.status == 'completed').length;
              // Fetch authoritative totals from repositories
              final modulesCountAsync = ref.watch(modulesCountForCourseProvider(cp.courseId));
              final lessonsCountAsync = ref.watch(lessonsCountForCourseProvider(cp.courseId));
              final int computedLessonTotal = modules.fold<int>(0, (sum, m) => sum + (m.totalLessons ?? 0));
              final int? repoLessonTotal = lessonsCountAsync.maybeWhen(data: (v) => v, orElse: () => null);
              final int totalLessons = repoLessonTotal ?? computedLessonTotal;
              final int computedModuleTotal = modules.length;
              final int? repoModuleTotal = modulesCountAsync.maybeWhen(data: (v) => v, orElse: () => null);
              final int totalModules = repoModuleTotal ?? computedModuleTotal;
              double percent = 0;
              if (totalLessons > 0) {
                percent = (completedLessons / totalLessons).clamp(0.0, 1.0);
              } else if (cp.isCompleted == true) {
                percent = 1.0;
              }
              final double modulePercent = totalModules > 0 ? (completedModules / totalModules).clamp(0.0, 1.0) : 0.0;
              final bool courseCompleted = totalLessons > 0 && completedLessons >= totalLessons;
              final isExpanded = expanded.contains(cp.id);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0,1)),
                  ],
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        final current = ref.read(_expandedCoursesProvider.notifier).state;
                        final copy = Set<String>.from(current);
                        if (copy.contains(cp.id)) {
                          copy.remove(cp.id);
                        } else {
                          copy.add(cp.id);
                        }
                        ref.read(_expandedCoursesProvider.notifier).state = copy;
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16,16,16, isExpanded ? 0 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      final courseAsync = ref.watch(courseByIdProvider(cp.courseId));
                                      return courseAsync.when(
                                        loading: () => Text(
                                          'Loading course...',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                                        ),
                                        error: (e, _) => Text(
                                          'Course',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        data: (course) => Text(
                                          course != null && course.title.isNotEmpty
                                              ? course.title
                                              : 'Course ${cp.courseId.substring(0, 8)}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                _StatusChip(label: courseCompleted ? 'Completed' : 'In Progress', completed: courseCompleted),
                                const SizedBox(width: 12),
                                AnimatedRotation(
                                  duration: const Duration(milliseconds: 180),
                                  turns: isExpanded ? 0.5 : 0,
                                  child: const Icon(Icons.keyboard_arrow_down, size: 24),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(value: percent, backgroundColor: Colors.grey.shade200),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Modules $completedModules/$totalModules (${(modulePercent * 100).round()}%)',
                                    style: Theme.of(context).textTheme.bodySmall),
                                Text('Lessons $completedLessons/$totalLessons (${(percent * 100).round()}%)',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded && modules.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16,12,16,16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modules Progress', style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: modules.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, mIndex) {
                                final m = modules[mIndex];
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppColors.copBlue,
                                            child: Text('${mIndex+1}', style: const TextStyle(color: Colors.white,fontWeight: FontWeight.w600,fontSize: 12)),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Builder(
                                              builder: (context) {
                                                final moduleAsync = ref.watch(moduleByIdProvider(m.moduleId));
                                                return moduleAsync.when(
                                                  loading: () => Text('Loading module...', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                                                  error: (e, _) => Text('Module', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                                  data: (mod) => Text(
                                                    mod != null && (mod.description?.isNotEmpty ?? false)
                                                        ? mod.description!
                                                        : 'Module ${m.moduleId.substring(0,8)}',
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          Builder(
                                            builder: (context) {
                                              final lessonsAsync = ref.watch(lessonsForModuleProvider(m.moduleId));
                                              final totalLessonsInModule = lessonsAsync.maybeWhen(
                                                data: (ls) => ls.length,
                                                orElse: () => m.totalLessons ?? 0,
                                              );
                                              final completedLessonsInModule = ((m.completedLessons ?? 0) > totalLessonsInModule)
                                                  ? totalLessonsInModule
                                                  : (m.completedLessons ?? 0);
                                              final moduleDone = totalLessonsInModule > 0 && completedLessonsInModule >= totalLessonsInModule;
                                              return _StatusChip(label: moduleDone ? 'Completed' : 'In Progress', completed: moduleDone);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Builder(
                                        builder: (context) {
                                          final lessonsAsync = ref.watch(lessonsForModuleProvider(m.moduleId));
                                          final totalLessonsInModule = lessonsAsync.maybeWhen(
                                            data: (ls) => ls.length,
                                            orElse: () => m.totalLessons ?? 0,
                                          );
                                          final completedLessonsInModule = ((m.completedLessons ?? 0) > totalLessonsInModule)
                                              ? totalLessonsInModule
                                              : (m.completedLessons ?? 0);
                                          return Row(
                                            children: [
                                              Icon(Icons.circle, size: 10, color: Colors.grey.shade500),
                                              const SizedBox(width: 6),
                                              Text(
                                                '$completedLessonsInModule of $totalLessonsInModule Lessons',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    Map<K, List<V>> _groupBy<K, V>(List<V> items, K Function(V) keySelector) {
      final map = <K, List<V>>{};
      for (final item in items) {
        final key = keySelector(item);
        map.putIfAbsent(key, () => []).add(item);
      }
      return map;
    }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool completed;
  const _StatusChip({required this.label, required this.completed});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: completed ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: completed ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}

final _selectedUserIdProvider = StateProvider<String?>((ref) => null);
final _userSearchQueryProvider = StateProvider<String>((ref) => '');
final _expandedCoursesProvider = StateProvider<Set<String>>((ref) => <String>{});
