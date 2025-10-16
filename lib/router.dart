import 'package:go_router/go_router.dart';
import 'features/auth/auth_screen.dart';
import 'features/dashboard_screen.dart';
import 'features/course/courses_list_screen.dart';
import 'features/content/modules_list_screen.dart';
import 'features/content/lessons_list_screen.dart';
import 'features/content/quizzes_list_screen.dart';

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
		GoRoute(
			path: '/courses',
			builder: (context, state) => const CoursesListScreen(),
		),
		GoRoute(
			path: '/modules',
			builder: (context, state) => const ModulesListScreen(),
		),
		GoRoute(
			path: '/lessons',
			builder: (context, state) => const LessonsListScreen(),
		),
		GoRoute(
			path: '/quizzes',
			builder: (context, state) => const QuizzesListScreen(),
		),
	],
);
