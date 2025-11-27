import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';


class AppSidebar extends ConsumerWidget {
  final String selectedRoute;
  final bool isCollapsed;
  final VoidCallback onToggle;
  const AppSidebar({
    super.key,
    required this.selectedRoute,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 72 : 240,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.copBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Logo and toggle button
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 12.0 : 24.0,
              32.0,
              isCollapsed ? 12.0 : 24.0,
              isCollapsed ? 16.0 : 40.0,
            ),
            child: isCollapsed
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Image.asset(
                          'assets/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Milpress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                                fontSize: 18,
                              ),
                        ),
                      ),
                    ],
                  ),
          ),
          // Navigation options
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarNavTile(
                    iconAsset: 'assets/house.png',
                    label: 'Dashboard',
                    selected: selectedRoute == '/dashboard',
                    onTap: () => context.go('/dashboard'),
                    isCollapsed: isCollapsed,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(height: 4),
                    _SidebarSectionLabel('Content Management'),
                    const SizedBox(height: 8),
                  ],
                  _SidebarNavTile(
                    iconAsset: 'assets/book.png',
                    label: 'Courses',
                    selected: selectedRoute == '/courses',
                    onTap: () => context.go('/courses'),
                    isCollapsed: isCollapsed,
                  ),
                  if (!isCollapsed) const SizedBox(height: 4),
                  _SidebarNavTile(
                    iconAsset: 'assets/book_open.png',
                    label: 'Lessons',
                    selected: selectedRoute == '/lessons',
                    onTap: () => context.go('/lessons'),
                    isCollapsed: isCollapsed,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(height: 20),
                    _SidebarSectionLabel('Users Management'),
                    const SizedBox(height: 8),
                  ],
                  _SidebarNavTile(
                    icon: Icons.people_outline,
                    label: 'Users',
                    selected: selectedRoute == '/users',
                    onTap: () => context.go('/users'),
                    isCollapsed: isCollapsed,
                  ),
                ],
              ),
            ),
          ),
          // Bottom section
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 0 : 16.0,
              8.0,
              isCollapsed ? 0 : 16.0,
              24.0,
            ),
            child: Column(
              children: [
                // Collapse/Expand action as a tile (like the reference UI)
                _SidebarNavTile(
                  icon: isCollapsed
                      ? Icons.keyboard_double_arrow_right
                      : Icons.keyboard_double_arrow_left,
                  label: isCollapsed ? 'Expand' : 'Collapse',
                  selected: false,
                  onTap: onToggle,
                  isCollapsed: isCollapsed,
                ),
                if (!isCollapsed) const SizedBox(height: 8),
                _SidebarNavTile(
                  icon: Icons.people_alt_outlined,
                  label: 'Admin',
                  selected: selectedRoute == '/settings',
                  onTap: () => context.go('/settings'),
                  isCollapsed: isCollapsed,
                ),
                if (!isCollapsed) const SizedBox(height: 4),
                _SidebarNavTile(
                  icon: Icons.logout_outlined,
                  label: 'Logout',
                  selected: false,
                  onTap: () {},
                  color: Colors.red,
                  isCollapsed: isCollapsed,
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
      padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white.withOpacity(0.7),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  final IconData? icon;
  final String? iconAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final bool isCollapsed;
  const _SidebarNavTile({
    this.icon,
    this.iconAsset,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.isCollapsed = false,
  }) : assert(
         icon != null || iconAsset != null,
         'Either icon or iconAsset must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final isSelected = selected;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: iconAsset != null
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            iconAsset!,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(icon!, color: Colors.white, size: 20),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.chevron_right, color: Colors.white, size: 16),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
