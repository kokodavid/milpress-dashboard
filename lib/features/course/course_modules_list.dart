import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import '../modules/modules_repository.dart';
import '../modules/edit_module_form.dart';
import '../modules/delete_module_dialog.dart';

import '../../features/lesson_v2/lesson_v2_models.dart';
import '../../features/lesson_v2/lesson_v2_repository.dart';

class CourseModulesList extends ConsumerWidget {
  final String courseId;
  const CourseModulesList({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesAsync = ref.watch(modulesForCourseProvider(courseId));
    return modulesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Failed to load modules: $e'),
        ),
      ),
      data: (modules) {
        if (modules.isEmpty) {
          return const Center(child: Text('No modules for this course'));
        }
        return ListView.builder(
          itemCount: modules.length,
          itemBuilder: (context, index) {
            final m = modules[index];
            return ModuleWithLessonsDropdown(module: m);
          },
        );
      },
    );
  }
}

class ModuleWithLessonsDropdown extends ConsumerStatefulWidget {
  final dynamic module;
  const ModuleWithLessonsDropdown({super.key, required this.module});

  @override
  ConsumerState<ModuleWithLessonsDropdown> createState() =>
      _ModuleWithLessonsDropdownState();
}

class _ModuleWithLessonsDropdownState
    extends ConsumerState<ModuleWithLessonsDropdown> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final lessonsAsync = ref.watch(lessonsForModuleProvider(module.id));
    int? lessonCount;
    lessonsAsync.whenData((lessons) => lessonCount = lessons.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Numbered circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.copBlue,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${module.position}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Module title and metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.description?.isNotEmpty == true
                          ? module.description!
                          : 'Module ${module.position}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (lessonCount != null) ...[
                          Icon(Icons.circle, size: 12, color: AppColors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '$lessonCount Lesson${lessonCount == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                        if (module.durationMinutes != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${module.durationMinutes} min',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (module.locked) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.orange.shade600,
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

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      showEditModuleDialog(
                        context: context,
                        ref: ref,
                        module: module,
                        onUpdated: () {
                          // Refresh the modules list
                          ref.invalidate(modulesForCourseProvider);
                        },
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.faintGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.grey.shade600,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/edit_pencil.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDeleteModuleDialog(
                        context: context,
                        ref: ref,
                        module: module,
                        onDeleted: () {
                          // Refresh the modules list
                          ref.invalidate(modulesForCourseProvider);
                        },
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.faintGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.red.shade600,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              'assets/delete.png',
                              width: 18,
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            const SizedBox(height: 8),
            LessonsDropdown(moduleId: module.id),
          ],
        ],
      ),
    );
  }
}

class LessonsDropdown extends ConsumerWidget {
  final String moduleId;
  const LessonsDropdown({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsForModuleProvider(moduleId));
    return lessonsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Failed to load lessons: $e'),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Text('No lessons in this module');
        }
        return SizedBox(
          height: 160,
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: lessons.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => LessonCard(lesson: lessons[index]),
            ),
          ),
        );
      },
    );
  }
}

class LessonCard extends StatelessWidget {
  final NewLesson lesson;
  const LessonCard({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Center(
          child: Text(
            lesson.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
