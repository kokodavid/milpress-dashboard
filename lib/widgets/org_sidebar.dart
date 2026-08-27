import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_colors.dart';
import '../features/org_portal/auth/org_session_provider.dart';
import '../features/subscriptions/subscription_enums.dart';

// =============================================================================
// OrgSidebar — navigation sidebar shown for org portal users.
// =============================================================================
class OrgSidebar extends ConsumerWidget {
  final String selectedRoute;
  final bool isCollapsed;
  final VoidCallback onToggle;

  const OrgSidebar({
    super.key,
    required this.selectedRoute,
    required this.isCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(orgSessionProvider);
    final session = sessionAsync.valueOrNull;
    final org = session?.org;

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
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 12.0 : 20.0,
              24.0,
              isCollapsed ? 12.0 : 20.0,
              isCollapsed ? 12.0 : 20.0,
            ),
            child: isCollapsed
                ? Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'MilPress',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (org != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          org.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _PlanBadge(plan: org.plan),
                        const SizedBox(height: 4),
                        Text(
                          '${org.seatsUsed} / ${org.seatLimit ?? '∞'} seats',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),

          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 8),

          // ── Nav items ───────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrgNavTile(
                    icon: Icons.dashboard_outlined,
                    label: 'Overview',
                    route: '/org/overview',
                    selectedRoute: selectedRoute,
                    isCollapsed: isCollapsed,
                  ),
                  _OrgNavTile(
                    icon: Icons.people_outline,
                    label: 'Members',
                    route: '/org/members',
                    selectedRoute: selectedRoute,
                    isCollapsed: isCollapsed,
                  ),
                  _OrgNavTile(
                    icon: Icons.bar_chart_outlined,
                    label: 'Learner Progress',
                    route: '/org/progress',
                    selectedRoute: selectedRoute,
                    isCollapsed: isCollapsed,
                  ),
                  // Show grants only for NGOs / schools or if they have grants
                  if (org == null ||
                      org.type == OrgType.ngo ||
                      org.type == OrgType.school ||
                      org.type == OrgType.community)
                    _OrgNavTile(
                      icon: Icons.card_giftcard_outlined,
                      label: 'Grants',
                      route: '/org/grants',
                      selectedRoute: selectedRoute,
                      isCollapsed: isCollapsed,
                    ),
                  _OrgNavTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: '/org/settings',
                    selectedRoute: selectedRoute,
                    isCollapsed: isCollapsed,
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCollapsed ? 0 : 12.0,
              8.0,
              isCollapsed ? 0 : 12.0,
              20.0,
            ),
            child: Column(
              children: [
                _OrgNavTile(
                  icon: isCollapsed
                      ? Icons.keyboard_double_arrow_right
                      : Icons.keyboard_double_arrow_left,
                  label: isCollapsed ? 'Expand' : 'Collapse',
                  route: '',
                  selectedRoute: '',
                  isCollapsed: isCollapsed,
                  onTap: onToggle,
                ),
                const SizedBox(height: 4),
                _OrgNavTile(
                  icon: Icons.logout_outlined,
                  label: 'Logout',
                  route: '',
                  selectedRoute: '',
                  isCollapsed: isCollapsed,
                  color: Colors.redAccent,
                  onTap: () async {
                    ref.read(orgSessionProvider.notifier).clear();
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/org-login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Plan badge chip ────────────────────────────────────────────────────────────
class _PlanBadge extends StatelessWidget {
  final OrgPlan plan;
  const _PlanBadge({required this.plan});

  Color get _color => switch (plan) {
    OrgPlan.starter    => const Color(0xFF3B82F6),
    OrgPlan.growth     => const Color(0xFF10B981),
    OrgPlan.enterprise => const Color(0xFFE85D04),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        plan.label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Nav tile ───────────────────────────────────────────────────────────────────
class _OrgNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String selectedRoute;
  final bool isCollapsed;
  final Color? color;
  final VoidCallback? onTap;

  const _OrgNavTile({
    required this.icon,
    required this.label,
    required this.route,
    required this.selectedRoute,
    required this.isCollapsed,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = route.isNotEmpty && selectedRoute.startsWith(route);
    final tileColor = color ?? Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? (route.isNotEmpty ? () => context.go(route) : null),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 0 : 12,
              vertical: 11,
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, color: tileColor, size: 20),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: tileColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.chevron_right, color: tileColor, size: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
