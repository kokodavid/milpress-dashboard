import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/features/auth/admin_profile.dart';

class AppSidebar extends ConsumerWidget {
  final String selectedRoute;
  const AppSidebar({super.key, required this.selectedRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      color: const Color(0xFFF7F7FA),
      child: Column(
        children: [
          // Logo section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'MilPress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Navigation options
          Expanded(
            child: ListView(
              children: [
                _SidebarSectionLabel('OVERVIEW'),
                _SidebarNavTile(
                  icon: FontAwesomeIcons.house,
                  label: 'Overview',
                  selected: selectedRoute == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _SidebarNavTile(
                  icon: FontAwesomeIcons.book,
                  label: 'Courses',
                  selected: selectedRoute == '/courses',
                  onTap: () => context.go('/courses'),
                ),
                _SidebarNavTile(
                  icon: FontAwesomeIcons.bookOpen,
                  label: 'Lessons',
                  selected: selectedRoute == '/lessons',
                  onTap: () => context.go('/lessons'),
                ),
              ],
            ),
          ),
          // Bottom section
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
            child: Column(
              children: [
                _CurrentUserTile(),
                _SidebarNavTile(
                  icon: Icons.settings,
                  label: 'Settings',
                  selected: selectedRoute == '/settings',
                  onTap: () => context.go('/settings'),
                ),
                _SidebarNavTile(
                  icon: Icons.logout,
                  label: 'Logout',
                  selected: false,
                  onTap: () {
                    // TODO: Implement logout logic
                  },
                  color: Colors.deepOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  final String label;
  const _SidebarSectionLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 0, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[600], letterSpacing: 1.2),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    final highlight = selected ? Theme.of(context).colorScheme.primary : (color ?? Colors.black87);
    return ListTile(
      leading: Icon(icon, color: highlight),
      title: Text(
        label,
        style: TextStyle(
          color: highlight,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: highlight.withAlpha(20), // 0.08 * 255 ≈ 20
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

class _CurrentUserTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Row(
            children: [
              const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin User', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Admin', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          );
        }
        final profileAsync = ref.watch(adminProfileProvider(user.id));
        return profileAsync.when(
          data: (profile) {
            final name = profile?.name ?? (user.email?.split('@').first ?? 'Admin User');
            final initials = computeInitials(profile?.name ?? name);
            final role = profile?.role ?? 'Admin';
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text(initials, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.black)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium),
                        Text(role, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
          loading: () => Row(
            children: [
              const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 80, color: Colors.black12),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 50, color: Colors.black12),
                  ],
                ),
              ),
            ],
          ),
          error: (_, __) => Row(
            children: [
              const CircleAvatar(radius: 16, child: Icon(Icons.error_outline, size: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin User', style: Theme.of(context).textTheme.bodyMedium),
                    Text('Admin', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Row(
        children: [
          const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 80, color: Colors.black12),
                const SizedBox(height: 4),
                Container(height: 10, width: 50, color: Colors.black12),
              ],
            ),
          ),
        ],
      ),
      error: (_, __) => Row(
        children: [
          const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin User', style: Theme.of(context).textTheme.bodyMedium),
                Text('Admin', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
