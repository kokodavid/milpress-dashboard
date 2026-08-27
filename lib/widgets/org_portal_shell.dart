import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/org_portal/auth/org_session_provider.dart';
import 'org_sidebar.dart';

// =============================================================================
// OrgPortalShell — wraps all /org/* routes with the org sidebar + top bar.
// =============================================================================
class OrgPortalShell extends ConsumerStatefulWidget {
  final Widget child;
  const OrgPortalShell({super.key, required this.child});

  @override
  ConsumerState<OrgPortalShell> createState() => _OrgPortalShellState();
}

class _OrgPortalShellState extends ConsumerState<OrgPortalShell> {
  bool _isSidebarCollapsed = false;

  String _pageTitle(String route) {
    if (route.startsWith('/org/overview')) return 'Overview';
    if (route.startsWith('/org/members'))  return 'Members';
    if (route.startsWith('/org/progress')) return 'Learner Progress';
    if (route.startsWith('/org/grants'))   return 'Sponsored Grants';
    if (route.startsWith('/org/settings')) return 'Organization Settings';
    return 'Organization Portal';
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final session = ref.watch(currentOrgSessionProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // ── Sidebar ─────────────────────────────────────────────────────
          OrgSidebar(
            selectedRoute: location,
            isCollapsed: _isSidebarCollapsed,
            onToggle: () =>
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          ),

          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        _pageTitle(location),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (session != null) ...[
                        // Org name chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F4F4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 14,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                session.org.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            session.role.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Screen content
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
