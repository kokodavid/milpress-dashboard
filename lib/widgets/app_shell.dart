import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_sidebar.dart';
import 'search_input.dart';
import 'current_user_chip.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    
    String getPageTitle(String route) {
      switch (route) {
        case '/dashboard':
          return 'Dashboard';
        case '/courses':
          return 'Courses';
        case '/lessons':
          return 'Lessons';
        case '/users':
          return 'Users';
        case '/settings':
          return 'Settings';
        default:
          return 'Dashboard';
      }
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Row(
        children: [
          AppSidebar(selectedRoute: location),
          Expanded(
            child: Column(
              children: [
                // Top app bar area
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                      // Page Title
                      Text(
                        getPageTitle(location),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        fit: FlexFit.loose,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: SearchInput(
                            hintText: 'Search anything',
                            onChanged: (value) {
                              // TODO: hook up filtering/search action
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: const CurrentUserChip(),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: IconButton(
                          tooltip: 'Notifications',
                          onPressed: () {
                            // TODO: open notifications
                          },
                          icon: const Icon(Icons.notifications_none_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
