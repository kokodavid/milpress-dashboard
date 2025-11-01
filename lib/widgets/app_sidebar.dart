import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

class AppSidebar extends ConsumerWidget {
  final String selectedRoute;
  const AppSidebar({super.key, required this.selectedRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
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
          // Logo section
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 40.0),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Text(
                  'Milpress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          // Navigation options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SidebarSectionLabel('Overview'),
                  const SizedBox(height: 8),
                  _SidebarNavTile(
                    iconAsset: 'assets/house.png',
                    label: 'Dashboard',
                    selected: selectedRoute == '/dashboard',
                    onTap: () => context.go('/dashboard'),
                  ),
                  const SizedBox(height: 4),
                  _SidebarNavTile(
                    iconAsset: 'assets/book.png',
                    label: 'Courses',
                    selected: selectedRoute == '/courses',
                    onTap: () => context.go('/courses'),
                  ),
                  const SizedBox(height: 4),
                  _SidebarNavTile(
                    iconAsset: 'assets/book_open.png',
                    label: 'Lessons',
                    selected: selectedRoute == '/lessons',
                    onTap: () => context.go('/lessons'),
                  ),
                ],
              ),
            ),
          ),
          // Bottom section
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 24.0),
            child: Column(
              children: [
                _SidebarNavTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: selectedRoute == '/settings',
                  onTap: () => context.go('/settings'),
                ),
                const SizedBox(height: 4),
                _SidebarNavTile(
                  icon: Icons.logout_outlined,
                  label: 'Logout',
                  selected: false,
                  onTap: () {},
                  color: Colors.red.shade400,
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
  const _SidebarNavTile({
    this.icon,
    this.iconAsset,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  }) : assert(icon != null || iconAsset != null, 'Either icon or iconAsset must be provided');
  
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
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
                      : Icon(
                          icon!,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight:FontWeight.w500,
                  ),
                ),
                if (isSelected) const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
