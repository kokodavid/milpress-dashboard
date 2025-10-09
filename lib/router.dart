import 'package:go_router/go_router.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard_screen.dart';

final GoRouter appRouter = GoRouter(
	initialLocation: '/login',
	routes: [
		GoRoute(
			path: '/login',
			builder: (context, state) => const AdminLoginScreen(),
		),
			GoRoute(
				path: '/dashboard',
				builder: (context, state) => const DashboardScreen(),
			),
	],
);
