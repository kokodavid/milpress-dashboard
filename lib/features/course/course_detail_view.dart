import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

import 'course_models.dart';
import 'course_modules_list.dart';
import 'course_repository.dart';
import 'edit_course_form.dart';
import 'widgets/custom_chip.dart';
import '../modules/create_module_form.dart';
import '../modules/modules_repository.dart';

const _kPremiumColor = Color(0xFFE85D04);

String _fmtDateTime(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

class CourseDetailView extends ConsumerStatefulWidget {
  final Course course;
  final VoidCallback onRefresh;
  final VoidCallback onDeleted;
  const CourseDetailView({
    super.key,
    required this.course,
    required this.onRefresh,
    required this.onDeleted,
  });

  @override
  ConsumerState<CourseDetailView> createState() => _CourseDetailViewState();
}

class _CourseDetailViewState extends ConsumerState<CourseDetailView> {
  late bool _isPremium;
  bool _savingPremium = false;

  @override
  void initState() {
    super.initState();
    _isPremium = widget.course.isPremium;
  }

  @override
  void didUpdateWidget(CourseDetailView old) {
    super.didUpdateWidget(old);
    if (old.course.id != widget.course.id) {
      _isPremium = widget.course.isPremium;
    }
  }

  Future<void> _togglePremium(bool next) async {
    setState(() {
      _isPremium = next;
      _savingPremium = true;
    });
    try {
      await ref
          .read(toggleCoursePremiumProvider.notifier)
          .toggle(widget.course.id, newValue: next);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next
                  ? '"${widget.course.title}" marked as Premium'
                  : '"${widget.course.title}" set to Free',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isPremium = !next);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update premium status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingPremium = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final modulesAsync = ref.watch(modulesForCourseProvider(course.id));
    final nextModulePosition = modulesAsync.maybeWhen(
      data: (modules) {
        var highest = 0;
        for (final module in modules) {
          if (module.position > highest) {
            highest = module.position;
          }
        }
        return highest + 1;
      },
      orElse: () => 1,
    );
    final modulesLoading = modulesAsync.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // ── Premium toggle ──────────────────────────────────────
                  Tooltip(
                    message: _isPremium ? 'Mark as Free' : 'Mark as Premium',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: _isPremium
                            ? _kPremiumColor.withOpacity(0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isPremium
                              ? _kPremiumColor.withOpacity(0.4)
                              : Colors.grey.shade300,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            size: 15,
                            color: _isPremium
                                ? _kPremiumColor
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Premium',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isPremium
                                  ? _kPremiumColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _savingPremium
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isPremium
                                          ? _kPremiumColor
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                )
                              : Switch.adaptive(
                                  value: _isPremium,
                                  onChanged: _togglePremium,
                                  activeColor: _kPremiumColor,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                                  child: EditCourseForm(
                                    course: course,
                                    onUpdated: () {
                                      widget.onRefresh();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton.icon(
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete course?'),
                            content: Text(
                              'Are you sure you want to delete "${course.title}"? This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            // Use notifier so activity logging runs on delete
                            await ref.read(deleteCourseProvider.notifier).delete(
                              course.id,
                              details: {
                                'title': course.title,
                                if (course.level != null) 'level': course.level,
                                if (course.type != null) 'type': course.type,
                              },
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Course deleted')),
                              );
                            }
                            widget.onDeleted();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Delete failed: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              if (course.type != null && course.type!.isNotEmpty)
                CustomChip(label: course.type!, isPrimary: true),
              if (course.level != null)
                CustomChip(label: 'Level ${course.level}'),
              if (course.durationInMinutes != null)
                CustomChip(
                  label:
                      '${course.durationInMinutes! ~/ 60}h ${course.durationInMinutes! % 60}min',
                ),
              if (course.updatedAt != null)
                CustomChip(
                  label: _fmtDateTime(course.updatedAt!).split(' ')[0],
                ),
              if (_isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPremiumColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _kPremiumColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_rounded,
                          size: 13, color: _kPremiumColor),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kPremiumColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'Courses Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course.description ?? 'No description available.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modules',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton.icon(
                  onPressed: modulesLoading
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (ctx) => CreateModuleForm(
                              courseId: course.id,
                              initialPosition: nextModulePosition,
                              onCreated: () {
                                ref.invalidate(
                                  modulesForCourseProvider(course.id),
                                );
                                widget.onRefresh();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Module created'),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Module'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: CourseModulesList(courseId: course.id)),
        ],
      ),
    );
  }
}
