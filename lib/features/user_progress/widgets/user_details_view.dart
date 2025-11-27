import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/profiles_repository.dart';
import '../user_progress_repository.dart';
import 'error_box.dart';
import 'progress_summary.dart';
import 'course_progress_list.dart';
import '../../../utils/initials.dart';

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
      error: (e, _) => ErrorBox(message: 'Failed to load user: $e'),
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
                      computeInitials(profile.fullName.isNotEmpty ? profile.fullName : (profile.email ?? 'U')),
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
              ProgressSummary(
                courseProgressAsync: courseProgressAsync,
                moduleProgressAsync: moduleProgressAsync,
                lessonProgressAsync: lessonProgressAsync,
              ),
              const SizedBox(height: 24),
              Text(
                'Course progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: CourseProgressList(
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

// initials logic moved to utils/initials.dart
