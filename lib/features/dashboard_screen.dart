// lib/features/dashboard_screen.dart
//
// Operator overview — Variant A v2 (data-accurate).
// Layout (top → bottom):
//   1. Header    — greeting + range control + Export + New Lesson CTA
//   2. KPI strip — 5 cells sharing a single border
//   3. Hero row  — Catalog growth chart 1fr (Steps+Lessons cumulative) · New profiles 320px
//   4. 2×2 grid  — step types · catalog health · course progress donuts · admin activity
//   5. Latest courses table
//   6. Latest users strip

// ignore_for_file: unused_element

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:milpress_dashboard/features/course/course_repository.dart';
import 'package:milpress_dashboard/features/auth/profiles_repository.dart';
import 'package:milpress_dashboard/features/modules/modules_repository.dart';
import 'package:milpress_dashboard/features/lesson_v2/lesson_v2_repository.dart';
import 'package:milpress_dashboard/theme/milpress_colors.dart';

import 'dashboard_providers.dart';

// Keep for backward compatibility — sidebar uses this to highlight the route.
final selectedIndexProvider = StateProvider<int>((ref) => 0);

// ── Entry point ───────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _DashboardBody();
  }
}

// ── Constants ─────────────────────────────────────────────────────────────────

const _kSectionGap = 20.0;
const _kCardPad = EdgeInsets.all(20);
const _kBorderRadius = 10.0;

/// Hide source-query captions in release builds.
bool get _showSourceCaptions => !kReleaseMode;

// ── Body ──────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(),
            const SizedBox(height: _kSectionGap),
            _KpiStrip(),
            const SizedBox(height: _kSectionGap),
            _HeroRow(),
            const SizedBox(height: _kSectionGap),
            _ContentGrid(),
            const SizedBox(height: _kSectionGap),
            _LatestCoursesTable(),
            const SizedBox(height: _kSectionGap),
            _LatestUsersStrip(),
          ],
        ),
      ),
    );
  }
}

// ── 1. Header ─────────────────────────────────────────────────────────────────

class _DashboardHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final rangeDays = ref.watch(dashboardRangeDaysProvider);
    final adminNameAsync = ref.watch(currentAdminNameProvider);
    final greeting = _greeting();
    final adminName = adminNameAsync.valueOrNull ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Greeting block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OVERVIEW · ${_rangeLabel(rangeDays)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.inkMuted,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$greeting${adminName.isNotEmpty ? ', $adminName' : ''}',
                style: tt.displayMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Range segmented control
        _RangeControl(current: rangeDays),
        const SizedBox(width: 12),
        // Export
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload_outlined, size: 16),
          label: const Text('Export'),
        ),
        const SizedBox(width: 8),
        // New lesson CTA
        ElevatedButton.icon(
          onPressed: () => context.go('/lessons'),
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New lesson'),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _rangeLabel(int days) {
    switch (days) {
      case 7:
        return 'LAST 7 DAYS';
      case 90:
        return 'LAST 90 DAYS';
      case 365:
        return 'YEAR TO DATE';
      default:
        return 'LAST 30 DAYS';
    }
  }
}

class _RangeControl extends ConsumerWidget {
  const _RangeControl({required this.current});
  final int current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final segments = <int, String>{7: '7d', 30: '30d', 90: '90d', 365: 'YTD'};
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(6),
        color: colors.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.entries.map((e) {
          final selected = e.key == current;
          return GestureDetector(
            onTap: () =>
                ref.read(dashboardRangeDaysProvider.notifier).state = e.key,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                e.value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : colors.inkMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── 2. KPI Strip ─────────────────────────────────────────────────────────────

class _KpiStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final rangeDays = ref.watch(dashboardRangeDaysProvider);
    final kpiAsync = ref.watch(kpiSnapshotProvider(rangeDays));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(_kBorderRadius),
        color: colors.surface,
      ),
      child: IntrinsicHeight(
        child: kpiAsync.when(
          loading: () => _kpiShimmer(context),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load KPIs: $e',
                  style: TextStyle(color: colors.danger)),
            ),
          ),
          data: (kpi) => Row(
            children: [
              Expanded(
                child: _KpiCell(
                  label: 'COURSES',
                  value: _fmt(kpi.coursesTotal),
                  delta: kpi.coursesDelta,
                  subLine: '${kpi.coursesLocked} locked',
                  source: 'count(courses)',
                ),
              ),
              _Divider(),
              Expanded(
                child: _KpiCell(
                  label: 'LESSONS',
                  value: _fmt(kpi.lessonsTotal),
                  delta: kpi.lessonsDelta,
                  subLine: 'published · v2',
                  source: 'count(new_lessons)',
                ),
              ),
              _Divider(),
              Expanded(
                child: _KpiCell(
                  label: 'STEP TYPES',
                  value: _fmt(kpi.stepTypesTotal),
                  delta: 0,
                  subLine: '${kpi.stepsDistinctTypes} in use · ${kpi.stepsTotal} total steps',
                  source: 'count(lesson_step_types)',
                ),
              ),
              _Divider(),
              Expanded(
                child: _KpiCell(
                  label: 'LEARNERS',
                  value: _fmt(kpi.learnersTotal),
                  delta: kpi.learnersDelta,
                  subLine: '${kpi.learnersNew14d} in last 14 days',
                  source: 'count(profiles)',
                ),
              ),
              _Divider(),
              Expanded(
                child: _KpiCell(
                  label: 'SUB-LVLS PASSED',
                  value: _fmt(kpi.subLevelsPassed),
                  delta: kpi.subLevelsDelta,
                  subLine: 'of ${kpi.subLevelsAttempts} attempts',
                  source: 'course_assessment_progress(is_passed=true)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kpiShimmer(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Expanded(
          child: Padding(
            padding: _kCardPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 10, width: 64, color: Colors.black12),
                const SizedBox(height: 12),
                Container(height: 28, width: 48, color: Colors.black12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1,
      thickness: 1,
      color: context.appColors.line,
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({
    required this.label,
    required this.value,
    required this.delta,
    required this.subLine,
    required this.source,
  });

  final String label;
  final String value;
  final double delta;
  final String subLine;
  final String source;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final positive = delta >= 0;
    final deltaColor = positive ? colors.ok : colors.danger;
    final deltaBg = positive ? colors.okWash : colors.dangerWash;

    return Padding(
      padding: _kCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showSourceCaptions)
            Text(
              source,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: colors.inkFaint,
                letterSpacing: 0.3,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.inkMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: tt.displaySmall),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: _DeltaChip(delta: delta, color: deltaColor, bg: deltaBg),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subLine, style: tt.bodySmall),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip(
      {required this.delta, required this.color, required this.bg});
  final double delta;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    if (delta == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: context.appColors.surfaceDim,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text('0.0%',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.appColors.inkMuted)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
              size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '${delta.abs().toStringAsFixed(1)}%',
            style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }
}

// ── 3. Hero Row ───────────────────────────────────────────────────────────────

class _HeroRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 900;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CatalogGrowthChart()),
            const SizedBox(width: 16),
            SizedBox(width: 320, child: _NewProfilesCard()),
          ],
        );
      }
      return Column(
        children: [
          _CatalogGrowthChart(),
          const SizedBox(height: 16),
          _NewProfilesCard(),
        ],
      );
    });
  }
}

// Hero area chart — catalog growth (lessons + steps, cumulative weekly)

class _CatalogGrowthChart extends ConsumerWidget {
  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final growthAsync = ref.watch(catalogGrowthProvider);

    return _Card(
      source: 'new_lessons.created_at · lesson_steps.created_at · cumulative 12w',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Catalog growth', style: tt.titleLarge),
              const Spacer(),
              _Legend(color: colors.primary, label: 'Steps'),
              const SizedBox(width: 12),
              _Legend(color: _blue, label: 'Lessons'),
            ],
          ),
          if (_showSourceCaptions) ...[
            const SizedBox(height: 2),
            Text(
              'new_lessons · lesson_steps · cumulative weekly · last 12w',
              style: tt.labelSmall?.copyWith(color: colors.inkFaint),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: growthAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Chart error: $e')),
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                      child: Text('No data', style: tt.bodySmall));
                }
                final maxSteps = data
                    .map((d) => d.cumulativeSteps.toDouble())
                    .fold(1.0, (a, b) => a > b ? a : b);
                final maxLessons = data
                    .map((d) => d.cumulativeLessons.toDouble())
                    .fold(1.0, (a, b) => a > b ? a : b);
                final maxY =
                    (maxSteps > maxLessons ? maxSteps : maxLessons) * 1.15;

                final stepsSpots = data
                    .asMap()
                    .entries
                    .map((e) => FlSpot(
                        e.key.toDouble(),
                        e.value.cumulativeSteps.toDouble()))
                    .toList();
                final lessonsSpots = data
                    .asMap()
                    .entries
                    .map((e) => FlSpot(
                        e.key.toDouble(),
                        e.value.cumulativeLessons.toDouble()))
                    .toList();

                return LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: colors.lineSoft,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (v, m) => Text(
                            v.toInt().toString(),
                            style: GoogleFonts.inter(
                                fontSize: 10, color: colors.inkMuted),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= data.length) {
                              return const SizedBox.shrink();
                            }
                            final w = data[idx].weekStart;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'W${_weekNum(w)}',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: colors.inkMuted),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      // Steps series — orange (primary)
                      LineChartBarData(
                        spots: stepsSpots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: colors.primary,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.primary.withOpacity(0.18),
                              colors.primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // Lessons series — blue
                      LineChartBarData(
                        spots: lessonsSpots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: _blue,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _blue.withOpacity(0.14),
                              _blue.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _weekNum(DateTime dt) {
    final startOfYear = DateTime(dt.year, 1, 1);
    final diff = dt.difference(startOfYear).inDays;
    return (diff / 7).ceil() + 1;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: context.appColors.inkMuted,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// Course progress donuts

class _CourseProgressColumn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final ratesAsync = ref.watch(coursePassRatesProvider);

    return _Card(
      source: 'course_assessment_progress / assessment_sublevels',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course progress', style: tt.titleLarge),
          if (_showSourceCaptions) ...[
            const SizedBox(height: 2),
            Text(
              'course_assessment_progress / sublevels',
              style: tt.labelSmall?.copyWith(color: colors.inkFaint),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          ratesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (rates) {
              if (rates.isEmpty) {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No assessments yet', style: tt.bodySmall),
                ));
              }
              return Column(
                children: rates.map((r) => _CourseDonutRow(rate: r)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CourseDonutRow extends StatelessWidget {
  const _CourseDonutRow({required this.rate});
  final CoursePassRate rate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final hasSome = rate.total > 0;
    final passColor = rate.percent >= 75
        ? colors.ok
        : rate.percent >= 40
            ? colors.warn
            : colors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: hasSome
                        ? [
                            PieChartSectionData(
                              value: rate.passed.toDouble(),
                              color: passColor,
                              radius: 8,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              value: (rate.total - rate.passed).toDouble(),
                              color: colors.lineSoft,
                              radius: 8,
                              showTitle: false,
                            ),
                          ]
                        : [
                            PieChartSectionData(
                              value: 1,
                              color: colors.lineSoft,
                              radius: 8,
                              showTitle: false,
                            ),
                          ],
                    centerSpaceRadius: 14,
                    sectionsSpace: 0,
                  ),
                ),
                Text(
                  hasSome ? '${rate.percent}%' : '—',
                  style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: hasSome ? passColor : colors.inkFaint),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate.courseTitle,
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${rate.passed} of ${rate.total} sub-levels',
                  style: tt.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 16),
        ],
      ),
    );
  }
}

// ── 4. 2×2 Content Grid ───────────────────────────────────────────────────────

class _ContentGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 700;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _StepTypesCard(),
                  const SizedBox(height: 16),
                  _CourseProgressColumn(),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _CatalogHealthCard(),
                  const SizedBox(height: 16),
                  _AdminActivityCard(),
                ],
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          _StepTypesCard(),
          const SizedBox(height: 16),
          _CatalogHealthCard(),
          const SizedBox(height: 16),
          _CourseProgressColumn(),
          const SizedBox(height: 16),
          _AdminActivityCard(),
        ],
      );
    });
  }
}

// Step types in use

class _StepTypesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(stepTypeBreakdownProvider);

    return _Card(
      source: 'lesson_steps group by step_type · lesson_step_types is_system=true',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Step types in use', style: tt.titleLarge),
              const Spacer(),
              async.when(
                data: (d) => Text('${d.isNotEmpty ? d.fold(0, (s, e) => s + e.count) : 0} total',
                    style: tt.labelSmall?.copyWith(color: colors.inkFaint)),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_showSourceCaptions)
            Text('lesson_steps group by step_type · lesson_step_types',
                style: tt.labelSmall?.copyWith(color: colors.inkFaint)),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (types) {
              if (types.isEmpty) {
                return Text('No steps yet', style: tt.bodySmall);
              }
              final maxCount = types.first.count;
              return Column(
                children: types.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final t = entry.value;
                  final frac = maxCount == 0
                      ? 0.0
                      : (t.count / maxCount).clamp(0.0, 1.0);
                  return _StepTypeRow(
                      rank: rank, type: t, frac: frac, max: maxCount);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepTypeRow extends StatelessWidget {
  const _StepTypeRow(
      {required this.rank,
      required this.type,
      required this.frac,
      required this.max});
  final int rank;
  final StepTypeCount type;
  final double frac;
  final int max;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    // Alternate bar color: primary orange vs blue-grey
    final barColor = rank.isOdd ? colors.primary : colors.inkSoft;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colors.inkMuted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(type.displayName,
                          style: tt.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                    ),
                    Text('${type.count}',
                        style: tt.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 5,
                    backgroundColor: colors.lineSoft,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Catalog health

class _CatalogHealthCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(catalogHealthProvider);

    return _Card(
      source: 'modules ⟕ new_lessons · new_lessons ⟕ lesson_steps · courses.locked · assessment_sublevels.questions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Catalog health', style: tt.titleLarge),
              const Spacer(),
              Text('derived counts',
                  style: tt.labelSmall?.copyWith(color: colors.inkFaint)),
            ],
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (h) => _CatalogGrid(health: h),
          ),
        ],
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({required this.health});
  final CatalogHealth health;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                count: health.modulesWithoutLessons,
                label: 'Modules without lessons',
                sub: 'modules ⟕ new_lessons',
                severity: _severity(health.modulesWithoutLessons),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthTile(
                count: health.lessonsWithNoSteps,
                label: 'Lessons with no steps',
                sub: 'new_lessons ⟕ lesson_steps',
                severity: _severity(health.lessonsWithNoSteps),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HealthTile(
                count: health.lockedCourses,
                label: 'Locked courses',
                sub: 'courses.locked = true',
                severity: _Severity.neutral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HealthTile(
                count: health.sublevelsWithEmptyQuestions,
                label: 'Sublevels missing questions',
                sub: 'assessment_sublevels.questions = []',
                severity: _severity(health.sublevelsWithEmptyQuestions),
              ),
            ),
          ],
        ),
      ],
    );
  }

  _Severity _severity(int n) {
    if (n == 0) return _Severity.ok;
    if (n <= 3) return _Severity.warn;
    return _Severity.danger;
  }
}

enum _Severity { ok, warn, danger, neutral }

class _HealthTile extends StatelessWidget {
  const _HealthTile({
    required this.count,
    required this.label,
    required this.sub,
    required this.severity,
  });
  final int count;
  final String label;
  final String sub;
  final _Severity severity;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    Color tileColor;
    Color numColor;
    switch (severity) {
      case _Severity.ok:
        tileColor = colors.okWash;
        numColor = colors.ok;
        break;
      case _Severity.warn:
        tileColor = colors.warnWash;
        numColor = colors.warn;
        break;
      case _Severity.danger:
        tileColor = colors.dangerWash;
        numColor = colors.danger;
        break;
      case _Severity.neutral:
        tileColor = colors.surfaceDim;
        numColor = colors.inkSoft;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: tileColor, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: numColor,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: tt.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600, color: colors.ink)),
          if (_showSourceCaptions) ...[
            const SizedBox(height: 2),
            Text(sub,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, color: colors.inkFaint)),
          ],
        ],
      ),
    );
  }
}

// New profiles 14 days

class _NewProfilesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final kpiAsync = ref.watch(kpiSnapshotProvider(30));
    final dailyAsync = ref.watch(newProfilesDailyProvider);

    return _Card(
      source: 'profiles.created_at · last 14d',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New profiles · 14 days', style: tt.titleLarge),
                  kpiAsync.when(
                    data: (k) => _DeltaChip(
                      delta: k.learnersDelta,
                      color: k.learnersDelta >= 0 ? colors.ok : colors.danger,
                      bg: k.learnersDelta >= 0
                          ? colors.okWash
                          : colors.dangerWash,
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const Spacer(),
              Text('profiles.created_at',
                  style: tt.labelSmall?.copyWith(color: colors.inkFaint)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: dailyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Error: $e', style: TextStyle(color: colors.danger)),
              data: (days) {
                if (days.isEmpty) return const SizedBox.shrink();
                final maxCount =
                    days.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: days.asMap().entries.map((e) {
                    final today = e.key == days.length - 1;
                    final h = maxCount == 0
                        ? 0.0
                        : (e.value.count / maxCount).clamp(0.05, 1.0);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 70 * h,
                              decoration: BoxDecoration(
                                color: today
                                    ? colors.primary
                                    : colors.primary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          dailyAsync.when(
            data: (days) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('2 weeks ago', style: tt.labelSmall),
                Text(
                    '${days.isNotEmpty ? days.last.count : 0} today',
                    style: tt.labelSmall
                        ?.copyWith(color: colors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Admin activity

class _AdminActivityCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final async = ref.watch(recentActivityWithActorProvider);

    return _Card(
      source: 'admin_activity_logs · last 20',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Admin activity', style: tt.titleLarge),
              const Spacer(),
              Flexible(
                child: Text(
                  'admin_activity_logs · last 20',
                  style: tt.labelSmall?.copyWith(color: colors.inkFaint),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No activity yet', style: tt.bodySmall),
                );
              }
              return Column(
                children: items
                    .map((item) => _ActivityRow(item: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});
  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final accentColor = _actionColor(item.action, colors);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accentColor.withOpacity(0.15),
            child: Text(
              item.actorInitials,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accentColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${item.actorName} ',
                        style: tt.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: item.label,
                        style: tt.bodySmall,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.action,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: accentColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timeAgo(item.createdAt),
            style: tt.labelSmall?.copyWith(color: colors.inkFaint),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String action, AppColors c) {
    if (action.startsWith('lesson_')) return c.primary;
    if (action.startsWith('course_')) return const Color(0xFF2563EB);
    if (action.startsWith('module_')) return c.warn;
    if (action.startsWith('assessment_')) return c.ok;
    return c.inkMuted;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── 5. Latest Courses Table ───────────────────────────────────────────────────

class _LatestCoursesTable extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final asyncCourses = ref.watch(coursesListProvider(
      const CoursesQuery(limit: 5, orderBy: 'created_at', ascending: false),
    ));

    return _Card(
      source: 'courses order by created_at desc limit 5',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Latest courses', style: tt.titleLarge),
              const Spacer(),
              if (_showSourceCaptions)
                Flexible(
                  child: Text('courses · created_at desc · limit 5',
                      style: tt.labelSmall?.copyWith(color: colors.inkFaint),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end),
                ),
              const SizedBox(width: 8),
              TextButton(onPressed: () {}, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 8),
          // Table header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 44),
                Expanded(
                  child: Text('Course name',
                      style: tt.labelMedium
                          ?.copyWith(color: colors.inkMuted)),
                ),
                SizedBox(
                  width: 90,
                  child: Text('Created',
                      style: tt.labelMedium
                          ?.copyWith(color: colors.inkMuted)),
                ),
                SizedBox(
                  width: 200,
                  child: Text('Status',
                      style: tt.labelMedium
                          ?.copyWith(color: colors.inkMuted)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.lineSoft),
          asyncCourses.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load: $e',
                  style: TextStyle(color: colors.danger)),
            ),
            data: (courses) {
              if (courses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No courses yet', style: tt.bodySmall),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: courses.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: colors.lineSoft),
                itemBuilder: (context, i) {
                  final c = courses[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: colors.primaryWash,
                            child: Text(
                              _initials(c.title),
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(c.title,
                              style: tt.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(_fmtDate(c.createdAt),
                              style: tt.bodySmall),
                        ),
                        SizedBox(
                          width: 200,
                          child: _CourseStatsPills(
                              courseId: c.id, locked: c.locked),
                        ),
                        const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _initials(String title) {
    final parts = title.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final p = parts[0];
    return (p.length >= 2 ? p.substring(0, 2) : p[0]).toUpperCase();
  }

  String _fmtDate(dynamic value) {
    if (value == null) return '—';
    DateTime? dt;
    if (value is DateTime) {
      dt = value;
    } else if (value is String) {
      dt = DateTime.tryParse(value);
    }
    if (dt == null) return '—';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _CourseStatsPills extends ConsumerWidget {
  const _CourseStatsPills({required this.courseId, required this.locked});
  final String courseId;
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final lessonsAsync = ref.watch(lessonsCountForCourseProvider(courseId));
    final modulesAsync = ref.watch(modulesCountForCourseProvider(courseId));

    return Row(
      children: [
        _Pill(
          icon: Icons.menu_book_outlined,
          value: lessonsAsync.valueOrNull ?? 0,
          color: const Color(0xFF7C3AED),
        ),
        const SizedBox(width: 6),
        _Pill(
          icon: Icons.view_module_outlined,
          value: modulesAsync.valueOrNull ?? 0,
          color: const Color(0xFF0891B2),
        ),
        const SizedBox(width: 6),
        _LockPill(locked: locked),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.value, required this.color});
  final IconData icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text('$value',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

class _LockPill extends StatelessWidget {
  const _LockPill({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = locked ? colors.danger : colors.ok;
    final bg = locked ? colors.dangerWash : colors.okWash;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              locked ? Icons.lock_outline : Icons.lock_open_outlined,
              size: 12,
              color: color),
          const SizedBox(width: 3),
          Text(locked ? 'Locked' : 'Open',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}

// ── 6. Latest Users Strip ─────────────────────────────────────────────────────

class _LatestUsersStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final asyncUsers = ref.watch(profilesListProvider(
      const ProfilesQuery(limit: 5, orderBy: 'created_at', ascending: false),
    ));

    return _Card(
      source: 'profiles order by created_at desc limit 5',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Latest users', style: tt.titleLarge),
              const Spacer(),
              if (_showSourceCaptions)
                Flexible(
                  child: Text('profiles · created_at desc · limit 5',
                      style: tt.labelSmall?.copyWith(color: colors.inkFaint),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end),
                ),
            ],
          ),
          const SizedBox(height: 12),
          asyncUsers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Text('Error: $e', style: TextStyle(color: colors.danger)),
            data: (users) {
              if (users.isEmpty) {
                return Text('No users yet', style: tt.bodySmall);
              }
              return LayoutBuilder(builder: (context, c) {
                final wide = c.maxWidth > 600;
                if (wide) {
                  return Row(
                    children: users
                        .map((u) =>
                            Expanded(child: _UserChip(profile: u)))
                        .toList(),
                  );
                }
                return Column(
                  children: users
                      .map((u) => _UserChip(profile: u, horizontal: true))
                      .toList(),
                );
              });
            },
          ),
        ],
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({required this.profile, this.horizontal = false});
  final dynamic profile; // Profile from profiles_repository
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tt = Theme.of(context).textTheme;
    final name = (profile.fullName as String).isNotEmpty
        ? profile.fullName as String
        : 'Unnamed';
    final email = (profile.email as String?) ?? '';
    final initials = _ini(name);

    if (horizontal) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: colors.primaryWash,
          child: Text(initials,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary)),
        ),
        title: Text(name,
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(email, style: tt.bodySmall, maxLines: 1),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primaryWash,
            child: Text(initials,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.primary)),
          ),
          const SizedBox(height: 6),
          Text(name.split(' ').first,
              style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(email,
              style: tt.labelSmall?.copyWith(color: colors.inkFaint),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _ini(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final p = parts[0];
    return (p.length >= 2 ? p.substring(0, 2) : p[0]).toUpperCase();
  }
}

// ── Shared primitives ─────────────────────────────────────────────────────────

/// Card wrapper. Pass [source] to render a mono query caption in debug builds.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.source});
  final Widget child;
  final String? source;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: _kCardPad,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(_kBorderRadius),
      ),
      child: child,
    );
  }
}

// ── Misc helpers ──────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n < 10) return '0$n';
  return n.toString();
}
