import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/initials.dart';
import '../../../utils/app_colors.dart';
import '../../assessment_v2/assessment_v2_repository.dart';
import '../../assessment_v2/models/assessment_v2_progress_model.dart';
import '../../auth/profiles_repository.dart';
import '../user_progress_models.dart';
import '../user_progress_repository.dart';
import '../../assessment_v2/assessment_v2_repository.dart' show progressForUserProvider;
import 'error_box.dart';
import 'progress_summary.dart';
import 'course_progress_list.dart';
import 'lesson_progress_list.dart';
import 'assignment_progress_list.dart';

// ─── tab index state (per-user so it resets when you switch users) ────────────
final _tabIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final _statusFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');

class UserDetailsView extends ConsumerWidget {
  final String userId;
  const UserDetailsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(userId));
    final courseProgressAsync = ref.watch(courseProgressForUserProvider(userId));
    final lessonProgressAsync = ref.watch(lessonProgressForUserProvider(userId));
    final assignmentProgressAsync = ref.watch(progressForUserProvider(userId));

    final tabIndex = ref.watch(_tabIndexProvider);
    final statusFilter = ref.watch(_statusFilterProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorBox(message: 'Failed to load user: $e'),
      data: (profile) {
        if (profile == null) return const Center(child: Text('User not found'));

        // Count pills for each segment
        final courseCount = courseProgressAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);
        final lessonCount = lessonProgressAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);
        final assignCount = assignmentProgressAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryColor.withValues(alpha: .15),
                    child: Text(
                      computeInitials(
                        profile.fullName.isNotEmpty ? profile.fullName : (profile.email ?? 'U'),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : (profile.email ?? profile.id),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((profile.email ?? '').isNotEmpty)
                          Text(
                            profile.email!,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Email user button
                  OutlinedButton.icon(
                    onPressed: () {
                      final email = profile.email ?? '';
                      if (email.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Email: $email')),
                        );
                      }
                    },
                    icon: const Icon(Icons.email_outlined, size: 16),
                    label: const Text('Email user'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reset progress button
                  OutlinedButton.icon(
                    onPressed: () => _confirmReset(context, ref, userId),
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Reset progress'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      backgroundColor: const Color(0xFFFFF5F5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── KPI strip ──────────────────────────────────────────────────
              ProgressSummary(
                courseProgressAsync: courseProgressAsync,
                lessonProgressAsync: lessonProgressAsync,
                assignmentProgressAsync: assignmentProgressAsync,
              ),

              const SizedBox(height: 20),

              // ── Segmented control + status filter ──────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _SegmentedControl(
                      selectedIndex: tabIndex,
                      segments: [
                        _Segment(label: 'Course progress', count: courseCount),
                        _Segment(label: 'Lesson progress', count: lessonCount),
                        _Segment(label: 'Assignment progress', count: assignCount),
                      ],
                      onChanged: (i) {
                        ref.read(_tabIndexProvider.notifier).state = i;
                        ref.read(_statusFilterProvider.notifier).state = 'all';
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusDropdown(
                    value: statusFilter,
                    onChanged: (v) => ref.read(_statusFilterProvider.notifier).state = v,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Content area ───────────────────────────────────────────────
              Expanded(
                child: _buildContent(
                  context,
                  tabIndex: tabIndex,
                  statusFilter: statusFilter,
                  courseProgressAsync: courseProgressAsync,
                  lessonProgressAsync: lessonProgressAsync,
                  assignmentProgressAsync: assignmentProgressAsync,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required int tabIndex,
    required String statusFilter,
    required AsyncValue<List<CourseProgress>> courseProgressAsync,
    required AsyncValue<List<LessonProgress>> lessonProgressAsync,
    required AsyncValue<List<AssessmentV2Progress>> assignmentProgressAsync,
  }) {
    switch (tabIndex) {
      case 1:
        return LessonProgressList(
          userId: userId,
          lessonProgressAsync: lessonProgressAsync,
          statusFilter: statusFilter,
        );
      case 2:
        return AssignmentProgressList(
          assignmentProgressAsync: assignmentProgressAsync,
          statusFilter: statusFilter,
        );
      default:
        return CourseProgressList(
          userId: userId,
          courseProgressAsync: courseProgressAsync,
          lessonProgressAsync: lessonProgressAsync,
          assignmentProgressAsync: assignmentProgressAsync,
          statusFilter: statusFilter,
        );
    }
  }

  void _confirmReset(BuildContext context, WidgetRef ref, String userId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset user progress'),
        content: const Text(
          'This will permanently delete all course, lesson, module, and assignment '
          'progress for this user. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();

              // Capture messenger before the async gap so it stays valid
              final messenger = ScaffoldMessenger.of(context);

              final success = await ref
                  .read(resetUserProgressProvider.notifier)
                  .reset(userId);

              // Invalidate providers regardless of context mount state
              ref.invalidate(courseProgressForUserProvider(userId));
              ref.invalidate(lessonProgressForUserProvider(userId));
              ref.invalidate(moduleProgressForUserProvider(userId));
              ref.invalidate(progressForUserProvider(userId));
              ref.read(_tabIndexProvider.notifier).state = 0;
              ref.read(_statusFilterProvider.notifier).state = 'all';

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'User progress has been reset successfully.'
                        : 'Failed to reset progress. Please try again.',
                  ),
                  backgroundColor:
                      success ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Reset progress'),
          ),
        ],
      ),
    );
  }
}

// ─── Segmented control ────────────────────────────────────────────────────────

class _Segment {
  final String label;
  final int count;
  const _Segment({required this.label, required this.count});
}

class _SegmentedControl extends StatelessWidget {
  final int selectedIndex;
  final List<_Segment> segments;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.selectedIndex,
    required this.segments,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: List.generate(segments.length, (i) {
          final seg = segments[i];
          final isSelected = i == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(14),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        seg.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.black87 : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor.withValues(alpha: .12)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${seg.count}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primaryColor : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Status dropdown ─────────────────────────────────────────────────────────

class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  static const _items = [
    ('all', 'All statuses'),
    ('in_progress', 'In progress'),
    ('completed', 'Completed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          items: _items.map((item) {
            return DropdownMenuItem<String>(
              value: item.$1,
              child: Text(item.$2),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
