import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/auth_screen.dart';
import 'features/dashboard_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/user_management_screen.dart';
import 'features/course/courses_list_screen.dart';
import 'features/content/modules_list_screen.dart';
import 'features/content/lessons_list_screen.dart';
import 'features/content/quizzes_list_screen.dart';
import 'features/assessment_v2/assessment_v2_screen.dart';
import 'features/content_management/content_management_screen.dart';
import 'features/lesson_builder/lesson_builder_screen.dart';
import 'features/subscriptions/subscriptions_screen.dart';
import 'features/organizations/organizations_screen.dart';
import 'features/plans/plans_screen.dart';
import 'features/org_portal/auth/org_login_screen.dart';
import 'features/org_portal/auth/org_session_provider.dart';
import 'features/org_portal/overview/org_overview_screen.dart';
import 'features/org_portal/members/org_members_screen.dart';
import 'features/org_portal/progress/org_progress_screen.dart';
import 'features/org_portal/grants/org_grants_screen.dart';
import 'features/org_portal/settings/org_settings_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/org_portal_shell.dart';

// =============================================================================
// Top-level redirect — two responsibilities:
//
//  1. /org/* routes  → require a Supabase session, else → /org-login
//  2. Admin routes   → require a Supabase session, else → /login
//                    → if an org-portal session is active, block access to
//                      the admin shell and redirect back to /org/overview
//
// ShellRoute doesn't support redirect in go_router v13, so all guards live
// here at the GoRouter level.
// =============================================================================
String? _globalRedirect(BuildContext context, GoRouterState state) {
  final location = state.matchedLocation;
  final user = Supabase.instance.client.auth.currentUser;

  // ── Org portal routes ──────────────────────────────────────────────────────
  if (location.startsWith('/org/')) {
    if (user == null) return '/org-login';
    return null; // org session check happens inside OrgPortalShell
  }

  // ── Always-public routes ───────────────────────────────────────────────────
  if (location == '/login' || location == '/org-login') return null;
  if (location.startsWith('/lessons/')) return null;

  // ── Admin routes (everything else in the AppShell) ────────────────────────
  // Require a Supabase session.
  if (user == null) return '/login';

  // If an org-portal session is active the user logged in via /org-login.
  // Keep them inside the org portal — they must not see the admin shell.
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    final orgSession = container.read(orgSessionProvider).valueOrNull;
    if (orgSession != null) return '/org/overview';
  } catch (_) {
    // ProviderScope not yet in tree on very first startup frame — allow.
  }

  return null;
}

final GoRouter appRouter = GoRouter(
	initialLocation: '/login',
	redirect: _globalRedirect,
	routes: [
		// ── Admin login ──────────────────────────────────────────────────
		GoRoute(
			path: '/login',
			builder: (context, state) => const AdminLoginScreen(),
		),

		// ── Org portal login ─────────────────────────────────────────────
		GoRoute(
			path: '/org-login',
			builder: (context, state) => const OrgLoginScreen(),
		),

		// ── Full-screen lesson steps builder (outside AppShell) ──────────
		GoRoute(
			path: '/lessons/:lessonId/steps',
			builder: (context, state) {
				final lessonId = state.pathParameters['lessonId']!;
				final stepParam = state.uri.queryParameters['step'];
				final initialStepIndex = stepParam != null ? int.tryParse(stepParam) : null;
				return LessonStepsBuilderScreen(lessonId: lessonId, initialStepIndex: initialStepIndex);
			},
		),

		// ── Admin shell ──────────────────────────────────────────────────
		ShellRoute(
			builder: (context, state, child) => AppShell(child: child),
			routes: [
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
					path: '/users',
					builder: (context, state) => const UserManagementScreen(),
				),
				GoRoute(
					path: '/settings',
					builder: (context, state) => const SettingsScreen(),
				),
				GoRoute(
					path: '/quizzes',
					builder: (context, state) => const QuizzesListScreen(),
				),
				GoRoute(
					path: '/assessments',
					builder: (context, state) => const AssessmentV2Screen(),
				),
				GoRoute(
					path: '/content',
					builder: (context, state) => const ContentManagementScreen(),
				),
				GoRoute(
					path: '/subscriptions',
					builder: (context, state) => const SubscriptionsScreen(),
				),
				GoRoute(
					path: '/organizations',
					builder: (context, state) => const OrganizationsScreen(),
				),
				GoRoute(
					path: '/plans',
					builder: (context, state) => const PlansScreen(),
				),
			],
		),

		// ── Organization Portal shell ─────────────────────────────────────
		ShellRoute(
			builder: (context, state, child) => OrgPortalShell(child: child),
			routes: [
				GoRoute(
					path: '/org/overview',
					builder: (context, state) => const OrgOverviewScreen(),
				),
				GoRoute(
					path: '/org/members',
					builder: (context, state) => const OrgMembersScreen(),
				),
				GoRoute(
					path: '/org/progress',
					builder: (context, state) => const OrgProgressScreen(),
				),
				GoRoute(
					path: '/org/grants',
					builder: (context, state) => const OrgGrantsScreen(),
				),
				GoRoute(
					path: '/org/settings',
					builder: (context, state) => const OrgSettingsScreen(),
				),
			],
		),
	],
);
