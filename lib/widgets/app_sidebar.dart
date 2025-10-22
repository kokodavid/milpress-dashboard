import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppSidebar extends StatelessWidget {
  final String selectedRoute;
  const AppSidebar({super.key, required this.selectedRoute});

  @override
  Widget build(BuildContext context) {
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
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  selected: selectedRoute == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _SidebarNavTile(
                  icon: Icons.menu_book,
                  label: 'Courses',
                  selected: selectedRoute == '/courses',
                  onTap: () => context.go('/courses'),
                ),
                _SidebarNavTile(
                  icon: Icons.view_module_outlined,
                  label: 'Modules',
                  selected: selectedRoute == '/modules',
                  onTap: () => context.go('/modules'),
                ),
                _SidebarNavTile(
                  icon: Icons.menu_book_outlined,
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
                const Divider(),
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
