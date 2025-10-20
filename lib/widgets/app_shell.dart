import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_sidebar.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(selectedRoute: location),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
