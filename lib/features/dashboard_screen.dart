
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final selectedIndexProvider = StateProvider<int>((ref) => 0);

class DashboardScreen extends ConsumerStatefulWidget {
	const DashboardScreen({super.key});

	@override
	ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
	final List<Widget> _pages = const [
		DashboardOverview(),
		AnalyticsPage(),
		SettingsPage(),
	];

	@override
	Widget build(BuildContext context) {
		final selectedIndex = ref.watch(selectedIndexProvider);
		return Scaffold(
			body: Row(
				children: [
					NavigationRail(
						selectedIndex: selectedIndex,
						onDestinationSelected: (index) {
							ref.read(selectedIndexProvider.notifier).state = index;
						},
						labelType: NavigationRailLabelType.all,
						destinations: const [
							NavigationRailDestination(
								icon: Icon(Icons.dashboard_outlined),
								selectedIcon: Icon(Icons.dashboard),
								label: Text('Dashboard'),
							),
							NavigationRailDestination(
								icon: Icon(Icons.analytics_outlined),
								selectedIcon: Icon(Icons.analytics),
								label: Text('Analytics'),
							),
							NavigationRailDestination(
								icon: Icon(Icons.settings_outlined),
								selectedIcon: Icon(Icons.settings),
								label: Text('Settings'),
							),
						],
					),
					const VerticalDivider(thickness: 1, width: 1),
					Expanded(
						child: _pages[selectedIndex],
					),
				],
			),
		);
	}
}

class DashboardOverview extends StatelessWidget {
	const DashboardOverview({super.key});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.all(24.0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Dashboard Overview',
						style: Theme.of(context).textTheme.headlineMedium,
					),
								const SizedBox(height: 24),
								Expanded(
									child: LayoutBuilder(
										builder: (context, constraints) {
															int crossAxisCount = 4;
															if (constraints.maxWidth < 600) {
																crossAxisCount = 1;
															} else if (constraints.maxWidth < 900) {
																crossAxisCount = 2;
															} else if (constraints.maxWidth < 1200) {
																crossAxisCount = 3;
															}

											return GridView.count(
												crossAxisCount: crossAxisCount,
												crossAxisSpacing: 16,
												mainAxisSpacing: 16,
												children: [
													_buildQuickActionCard(
														context,
														title: 'Courses',
														subtitle: 'Create and manage courses',
														icon: Icons.menu_book_outlined,
														color: Colors.blue,
														onTap: () => context.go('/courses'),
														ctaText: 'Open',
													),
													_buildQuickActionCard(
														context,
														title: 'Modules',
														subtitle: 'Manage course modules',
														icon: Icons.view_module_outlined,
														color: Colors.green,
														onTap: () => context.go('/modules'),
														ctaText: 'Open',
													),
													_buildQuickActionCard(
														context,
														title: 'Lessons',
														subtitle: 'Create and organize lessons',
														icon: Icons.menu_book,
														color: Colors.orange,
														onTap: () => context.go('/lessons'),
														ctaText: 'Open',
													),
													_buildQuickActionCard(
														context,
														title: 'Quizzes',
														subtitle: 'Manage lesson quizzes',
														icon: Icons.quiz_outlined,
														color: Colors.purple,
														onTap: () => context.go('/quizzes'),
														ctaText: 'Open',
													),
												],
											);
										},
									),
								),
				],
			),
		);
	}

				Widget _buildQuickActionCard(
					BuildContext context, {
					required String title,
					required String subtitle,
					required IconData icon,
					required Color color,
					required VoidCallback onTap,
					String ctaText = 'Open',
				}) {
					return Card(
						clipBehavior: Clip.antiAlias,
						elevation: 2,
						child: InkWell(
							onTap: onTap,
							child: Padding(
								padding: const EdgeInsets.all(16.0),
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Row(
											children: [
																	CircleAvatar(
																		// Using withAlpha to avoid deprecated withOpacity; 0.15 * 255 ≈ 38
																		backgroundColor: color.withAlpha(38),
													child: Icon(icon, color: color),
												),
												const Spacer(),
												TextButton.icon(
													onPressed: onTap,
													icon: const Icon(Icons.arrow_forward),
													label: Text(ctaText),
												),
											],
										),
										const SizedBox(height: 12),
										Text(
											title,
											style: Theme.of(context).textTheme.titleLarge,
										),
										const SizedBox(height: 6),
										Text(
											subtitle,
											style: Theme.of(context).textTheme.bodyMedium?.copyWith(
														color: Colors.grey[700],
													),
										),
									],
								),
							),
						),
					);
				}
}

class AnalyticsPage extends StatelessWidget {
	const AnalyticsPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.all(24.0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Analytics',
						style: Theme.of(context).textTheme.headlineMedium,
					),
					const SizedBox(height: 24),
					const Expanded(
						child: Center(
							child: Text('Analytics content will go here'),
						),
					),
				],
			),
		);
	}
}

class SettingsPage extends StatelessWidget {
	const SettingsPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.all(24.0),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						'Settings',
						style: Theme.of(context).textTheme.headlineMedium,
					),
					const SizedBox(height: 24),
					const Expanded(
						child: Center(
							child: Text('Settings content will go here'),
						),
					),
				],
			),
		);
	}
}
