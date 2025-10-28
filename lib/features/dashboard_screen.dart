import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:go_router/go_router.dart';
import 'package:milpress_dashboard/features/course/course_repository.dart';
import 'package:milpress_dashboard/features/lesson/lessons_repository.dart';
import 'package:milpress_dashboard/features/auth/profiles_repository.dart';
import 'package:milpress_dashboard/features/modules/modules_repository.dart';
// Sidebar is now handled globally by AppShell

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Just show the dashboard overview content. Sidebar is handled by AppShell.
    return const DashboardOverview();
  }
}

class DashboardOverview extends ConsumerWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesCountAsync = ref.watch(coursesCountProvider);
    final lessonsCountAsync = ref.watch(lessonsCountProvider);
    final usersCountAsync = ref.watch(usersCountProvider);

    final coursesCount = coursesCountAsync.value ?? 0;
    final lessonsCount = lessonsCountAsync.value ?? 0;
    final usersCount = usersCountAsync.value ?? 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          // Stats cards row/grid
          LayoutBuilder(
            builder: (context, constraints) {
                int crossAxisCount = 3;
                double aspect = 16 / 9;
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                  aspect = 3.2; // give more height for content on narrow screens
                } else if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                  aspect = 1.6;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspect,
                  children: [
                  MetricCard(
                    count: coursesCount,
                    label: 'Courses',
                    subtitle: coursesCountAsync.isLoading
                        ? 'loading…'
                        : 'active this term',
                    color: Colors.amber,
                    icon: FontAwesomeIcons.bookOpen,
                    progress: 0.65,
                  ),
                  MetricCard(
                    count: lessonsCount,
                    label: 'Lessons',
                    subtitle: lessonsCountAsync.isLoading
                        ? 'loading…'
                        : 'prepared this month',
                    color: Colors.pink,
                    icon: Icons.menu_book,
                    progress: 0.59,
                  ),
                  MetricCard(
                    count: usersCount,
                    label: 'Users',
                    subtitle: usersCountAsync.isLoading
                        ? 'loading…'
                        : 'total registered',
                    color: Colors.lightGreen,
                    icon: FontAwesomeIcons.userGroup,
                    progress: 0.59,
                  ),
                  ],
                );
            },
          ),
          const SizedBox(height: 24),
          // Latest courses table + latest users list
          _LatestActivitySection(),
          const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.count,
    required this.label,
    this.subtitle,
    required this.color,
    required this.icon,
    this.progress = 0.6,
  });

  final int count;
  final String label;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final double progress;

  String _formatCount(int value) {
    // For small values, keep two digits (e.g., 03). For large values, use compact notation.
    if (value < 100) return value.toString().padLeft(2, '0');
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final bg = color.withAlpha(30); // subtle pastel background
    final ringBg = color.withAlpha(40);
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            // Right-top circular progress ring
            Positioned(
              top: 0,
              right: 0,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(ringBg),
                      backgroundColor: Colors.transparent,
                    ),
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      backgroundColor: Colors.transparent,
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: textTheme.labelMedium?.copyWith(
                        color: color.withAlpha(200),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withAlpha(38),
                      child: Icon(icon, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatCount(count),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(label, style: textTheme.titleMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: color.withAlpha(220),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestActivitySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 980;
        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: _LatestCoursesTable()),
              const SizedBox(width: 16),
              SizedBox(width: 340, child: const _LatestUsersCard()),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _LatestCoursesTable(),
              SizedBox(height: 16),
              _LatestUsersCard(),
            ],
          );
        }
      },
    );
  }
}

class _LatestCoursesTable extends ConsumerWidget {
  const _LatestCoursesTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCourses = ref.watch(coursesListProvider(
      const CoursesQuery(limit: 5, orderBy: 'created_at', ascending: false),
    ));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Latest Courses', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            _TableHeader(),
            asyncCourses.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load courses: $e'),
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No courses yet'),
                  );
                }
                final visibleCount = courses.length > 5 ? 5 : courses.length;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleCount,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  itemBuilder: (context, index) {
                    final c = courses[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          SizedBox(width: 28, child: Text('${index + 1}'.padLeft(2, '0'))),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.deepPurpleAccent.withAlpha(30),
                            child: const Icon(Icons.menu_book, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Status: lessons, modules, availability lock
                          _CourseStatsPills(courseId: c.id, locked: c.locked),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right, color: Colors.black26),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black54);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: style)),
          const SizedBox(width: 8),
          const SizedBox(width: 40),
          Expanded(child: Text('Course Name', style: style)),
          const SizedBox(width: 12),
          SizedBox(width: 120, child: Text('Status', style: style)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.value, required this.color});
  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text('$value', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
      ]),
    );
  }
}

class _CourseStatsPills extends ConsumerWidget {
  const _CourseStatsPills({required this.courseId, required this.locked});
  final String courseId;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsCountForCourseProvider(courseId));
    final modulesAsync = ref.watch(modulesCountForCourseProvider(courseId));

    final lessons = lessonsAsync.value;
    final modules = modulesAsync.value;

    return Row(
      children: [
        _StatusPill(
          icon: Icons.menu_book,
          value: lessons ?? 0,
          color: Colors.purple,
        ),
        const SizedBox(width: 12),
        _StatusPill(
          icon: Icons.view_module_outlined,
          value: modules ?? 0,
          color: Colors.teal,
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (locked ? Colors.red : Colors.green).withAlpha(24),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(children: [
            Icon(locked ? Icons.lock_outline : Icons.lock_open_outlined,
                color: locked ? Colors.red : Colors.green, size: 16),
            const SizedBox(width: 4),
            Text(locked ? 'Locked' : 'Open',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: locked ? Colors.red : Colors.green)),
          ]),
        ),
      ],
    );
  }
}

class _LatestUsersCard extends ConsumerWidget {
  const _LatestUsersCard();

  String _initials(String? first, String? last) {
    final a = (first ?? '').isNotEmpty ? first!.substring(0, 1) : '';
    final b = (last ?? '').isNotEmpty ? last!.substring(0, 1) : '';
    final i = (a + b).toUpperCase();
    return i.isEmpty ? 'U' : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUsers = ref.watch(profilesListProvider(
      const ProfilesQuery(limit: 5, orderBy: 'created_at', ascending: false),
    ));

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Latest Users', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            asyncUsers.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Failed to load users: $e'),
              ),
              data: (users) {
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No users yet'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = users[index];
                    final initials = _initials(u.firstName, u.lastName);
                    final subtitle = (u.email ?? '').isNotEmpty ? u.email! : '—';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withAlpha(30),
                        child: Text(initials, style: const TextStyle(color: Colors.blue)),
                      ),
                      title: Text(u.fullName.isNotEmpty ? u.fullName : 'Unnamed user'),
                      subtitle: Text(subtitle),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}



class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(child: Text('Settings content will go here')),
          ),
        ],
      ),
    );
  }
}
