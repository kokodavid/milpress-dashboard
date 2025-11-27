import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/app_colors.dart';
import '../../course/course_repository.dart';
import '../../modules/modules_repository.dart';
import '../../lesson/lessons_repository.dart';
import '../user_progress_models.dart';
import 'status_chip.dart';
import 'percentage_label.dart';
import 'progress_bar.dart';
import 'error_box.dart';

final expandedCoursesProvider = StateProvider<Set<String>>((ref) => <String>{});

class CourseProgressList extends ConsumerWidget {
  final AsyncValue<List<CourseProgress>> courseProgressAsync;
  final AsyncValue<List<ModuleProgress>> moduleProgressAsync;
  final AsyncValue<List<LessonProgress>> lessonProgressAsync;
  const CourseProgressList({
    super.key,
    required this.courseProgressAsync,
    required this.moduleProgressAsync,
    required this.lessonProgressAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(expandedCoursesProvider);
    return courseProgressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorBox(message: 'Failed to load course progress: $e'),
      data: (courses) {
        final modulesByCourse = moduleProgressAsync.maybeWhen(
          data: (mods) => _groupBy<String, ModuleProgress>(mods, (m) => m.courseProgressId ?? ''),
          orElse: () => <String, List<ModuleProgress>>{},
        );
        final inProgress = courses.where((c) => c.isCompleted != true).toList();
        if (inProgress.isEmpty) {
          return const Center(child: Text('No course in progress'));
        }
        const threshold = 0.05;
        CourseProgress? selected;
        double selectedPercent = -1;
        double percentFor(CourseProgress cp) {
          final modules = modulesByCourse[cp.id] ?? const [];
          final totalLessons = modules.fold<int>(0, (sum, m) => sum + (m.totalLessons ?? 0));
          final completedLessons = modules.fold<int>(0, (sum, m) => sum + (m.completedLessons ?? 0));
          if (totalLessons <= 0) return 0;
          return (completedLessons / totalLessons).clamp(0.0, 1.0);
        }
        for (final cp in inProgress) {
          final p = percentFor(cp);
          if (p >= threshold && p > selectedPercent) {
            selected = cp;
            selectedPercent = p;
          }
        }
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
            final List<ModuleProgress> modules = List<ModuleProgress>.from(
              modulesByCourse[cp.id] ?? const [],
            )
              ..sort((a, b) {
                final aTotal = a.totalLessons ?? 0;
                final bTotal = b.totalLessons ?? 0;
                final aCompleted = a.completedLessons ?? 0;
                final bCompleted = b.completedLessons ?? 0;
                final aRatio = aTotal > 0 ? aCompleted / aTotal : 0.0;
                final bRatio = bTotal > 0 ? bCompleted / bTotal : 0.0;
                final cmp = aRatio.compareTo(bRatio);
                if (cmp != 0) return cmp; // lower progress first
                final aDone = (a.status == 'completed');
                final bDone = (b.status == 'completed');
                if (aDone != bDone) return aDone ? 1 : -1;
                return (a.moduleId).compareTo(b.moduleId);
              });
            final completedLessons = modules.fold<int>(0, (sum, m) => sum + (m.completedLessons ?? 0));
            final completedModules = modules.where((m) => m.status == 'completed').length;
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
                      final current = ref.read(expandedCoursesProvider.notifier).state;
                      final copy = Set<String>.from(current);
                      if (copy.contains(cp.id)) {
                        copy.remove(cp.id);
                      } else {
                        copy.add(cp.id);
                      }
                      ref.read(expandedCoursesProvider.notifier).state = copy;
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
                              StatusChip(label: courseCompleted ? 'Completed' : 'In Progress', completed: courseCompleted),
                              const SizedBox(width: 12),
                              AnimatedRotation(
                                duration: const Duration(milliseconds: 180),
                                turns: isExpanded ? 0.5 : 0,
                                child: const Icon(Icons.keyboard_arrow_down, size: 24),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PercentageLabel(percent: modulePercent),
                          const SizedBox(height: 6),
                          ProgressBar(value: percent),
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
                                                error: (e, _) => const Text('Module', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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
                                            return StatusChip(label: moduleDone ? 'Completed' : 'In Progress', completed: moduleDone);
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
