// lib/features/dashboard_providers.dart
//
// Data models and Riverpod providers that power the redesigned operator
// dashboard. All queries hit Supabase directly (no abstraction layer) so
// that aggregations that span multiple tables are co-located and easy to
// reason about. Add caching / keepAlive annotations if round-trip latency
// becomes noticeable in production.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Percent change from [prior] to [current].
/// Returns 100 when prior == 0 and current > 0; 0 when both are 0.
double _pctDelta(int current, int prior) {
  if (prior == 0) return current > 0 ? 100.0 : 0.0;
  return ((current - prior) / prior) * 100.0;
}

/// Returns the Monday of the ISO week containing [dt] (UTC).
DateTime _isoWeekStart(DateTime dt) {
  final d = dt.toUtc();
  final daysSinceMon = (d.weekday - 1) % 7; // Mon=1 → 0 offset
  return DateTime.utc(d.year, d.month, d.day - daysSinceMon);
}

String _initials(String? first, String? last) {
  final a = (first ?? '').isNotEmpty ? first![0].toUpperCase() : '';
  final b = (last ?? '').isNotEmpty ? last![0].toUpperCase() : '';
  final i = a + b;
  return i.isEmpty ? 'A' : i;
}

// ── Models ────────────────────────────────────────────────────────────────────

/// Aggregated values for the 5-cell KPI strip.
class KpiSnapshot {
  /// courses table totals
  final int coursesTotal;
  final int coursesLocked;
  final double coursesDelta; // % vs prior period

  /// new_lessons table totals
  final int lessonsTotal;
  final double lessonsDelta;

  /// lesson_steps table totals
  final int stepsTotal;
  final int stepsDistinctTypes; // COUNT(DISTINCT step_type) — types actually in use
  final double stepsDelta;

  /// lesson_step_types table — all registered types (system + custom)
  final int stepTypesTotal;

  /// profiles table totals
  final int learnersTotal;
  final int learnersNew14d;
  final double learnersDelta;

  /// assessment_v2_progress totals
  final int subLevelsPassed; // WHERE is_passed = true
  final int subLevelsAttempts; // COUNT(*)
  final double subLevelsDelta; // % change in passed count vs prior period

  const KpiSnapshot({
    required this.coursesTotal,
    required this.coursesLocked,
    required this.coursesDelta,
    required this.lessonsTotal,
    required this.lessonsDelta,
    required this.stepsTotal,
    required this.stepsDistinctTypes,
    required this.stepsDelta,
    required this.stepTypesTotal,
    required this.learnersTotal,
    required this.learnersNew14d,
    required this.learnersDelta,
    required this.subLevelsPassed,
    required this.subLevelsAttempts,
    required this.subLevelsDelta,
  });
}

/// One data-point in the hero area chart: week boundary + pass count.
class WeeklyPassCount {
  final DateTime weekStart;
  final int count;
  const WeeklyPassCount({required this.weekStart, required this.count});
}

/// One row in the "Step types in use" bar list.
class StepTypeCount {
  final String key; // value stored in lesson_steps.step_type
  final String displayName; // from lesson_step_types
  final String category; // from lesson_step_types
  final int count;
  const StepTypeCount({
    required this.key,
    required this.displayName,
    required this.category,
    required this.count,
  });
}

/// Four derived health metrics for the Catalog health card.
class CatalogHealth {
  final int modulesWithoutLessons; // modules ⟕ new_lessons (null)
  final int lessonsWithNoSteps; // new_lessons ⟕ lesson_steps (0)
  final int lockedCourses; // courses.locked = true
  final int sublevelsWithEmptyQuestions; // assessment_sublevels.questions = []
  const CatalogHealth({
    required this.modulesWithoutLessons,
    required this.lessonsWithNoSteps,
    required this.lockedCourses,
    required this.sublevelsWithEmptyQuestions,
  });
}

/// One daily bar in the "New profiles · 14 days" mini chart.
class DailyProfileCount {
  final DateTime date;
  final int count;
  const DailyProfileCount({required this.date, required this.count});
}

/// One row in the admin activity feed, with actor name resolved.
class ActivityItem {
  final String actorId;
  final String actorInitials;
  final String actorName;
  final String action; // e.g. "lesson_updated"
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;
  const ActivityItem({
    required this.actorId,
    required this.actorInitials,
    required this.actorName,
    required this.action,
    this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });

  /// Human-readable label derived from action + details.
  String get label {
    final parts = action.split('_');
    if (parts.length < 2) return action;
    final entity = parts.sublist(0, parts.length - 1).join(' ');
    final verb = parts.last;
    final title = (details?['title'] as String?) ??
        (details?['title_new'] as String?) ?? '';
    final base = '${entity[0].toUpperCase()}${entity.substring(1)}';
    return title.isNotEmpty ? '$base · $title' : '$base $verb';
  }
}

/// Per-course pass rate for the course progress donut list.
class CoursePassRate {
  final String courseId;
  final String courseTitle;
  final int passed; // distinct sublevels passed in this course's assessment
  final int total; // total sublevels in this course's assessment
  const CoursePassRate({
    required this.courseId,
    required this.courseTitle,
    required this.passed,
    required this.total,
  });

  double get fraction => total == 0 ? 0.0 : (passed / total).clamp(0.0, 1.0);
  int get percent => (fraction * 100).round();
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Selected time-range in days: 7, 30, 90, or 365 (YTD).
final dashboardRangeDaysProvider = StateProvider<int>((ref) => 30);

/// All five KPI values + deltas for the selected range.
final kpiSnapshotProvider =
    FutureProvider.family<KpiSnapshot, int>((ref, days) async {
  final client = Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final cs = now.subtract(Duration(days: days)).toIso8601String();
  final ps = now.subtract(Duration(days: days * 2)).toIso8601String();

  // — Courses ————————————————————————————————————————————————————————————————
  final List coursesAll =
      await client.from('courses').select('id, locked');
  final List coursesCurr =
      await client.from('courses').select('id').gte('created_at', cs);
  final List coursesPrior = await client
      .from('courses')
      .select('id')
      .gte('created_at', ps)
      .lt('created_at', cs);

  // — Lessons ————————————————————————————————————————————————————————————————
  final List lessonsAll = await client.from('new_lessons').select('id');
  final List lessonsCurr =
      await client.from('new_lessons').select('id').gte('created_at', cs);
  final List lessonsPrior = await client
      .from('new_lessons')
      .select('id')
      .gte('created_at', ps)
      .lt('created_at', cs);

  // — Step types ————————————————————————————————————————————————————————————
  // All registered types (system + custom) from the definition table
  final List stepTypesDef =
      await client.from('lesson_step_types').select('id');

  // — Steps ——————————————————————————————————————————————————————————————————
  final List stepsAll =
      await client.from('lesson_steps').select('id, step_type');
  int stepsCurrLen = 0, stepsPriorLen = 0;
  try {
    final List sc =
        await client.from('lesson_steps').select('id').gte('created_at', cs);
    final List sp = await client
        .from('lesson_steps')
        .select('id')
        .gte('created_at', ps)
        .lt('created_at', cs);
    stepsCurrLen = sc.length;
    stepsPriorLen = sp.length;
  } catch (_) {
    // lesson_steps may not have created_at indexed — skip delta
  }

  // — Profiles ———————————————————————————————————————————————————————————————
  final List profilesAll = await client.from('profiles').select('id');
  final List profilesCurr =
      await client.from('profiles').select('id').gte('created_at', cs);
  final List profilesPrior = await client
      .from('profiles')
      .select('id')
      .gte('created_at', ps)
      .lt('created_at', cs);
  final List profiles14d = await client
      .from('profiles')
      .select('id')
      .gte('created_at',
          now.subtract(const Duration(days: 14)).toIso8601String());

  // — Assessment progress ————————————————————————————————————————————————————
  // Table is 'course_assessment_progress' (not 'assessment_v2_progress')
  final List progressAll =
      await client.from('course_assessment_progress').select('id, is_passed');
  final int passedAll =
      progressAll.where((p) => (p['is_passed'] as bool?) == true).length;
  int passedCurr = 0, passedPrior = 0;
  try {
    final List pc = await client
        .from('course_assessment_progress')
        .select('id, is_passed')
        .gte('created_at', cs);
    passedCurr =
        (pc).where((p) => (p['is_passed'] as bool?) == true).length;
    final List pp = await client
        .from('course_assessment_progress')
        .select('id, is_passed')
        .gte('created_at', ps)
        .lt('created_at', cs);
    passedPrior =
        (pp).where((p) => (p['is_passed'] as bool?) == true).length;
  } catch (_) {}

  // — Derived ————————————————————————————————————————————————————————————————
  final distinctTypes = stepsAll
      .map((s) => s['step_type'] as String?)
      .whereType<String>()
      .toSet()
      .length;
  final lockedCourses =
      coursesAll.where((c) => (c['locked'] as bool?) == true).length;

  return KpiSnapshot(
    coursesTotal: coursesAll.length,
    coursesLocked: lockedCourses,
    coursesDelta: _pctDelta(coursesCurr.length, coursesPrior.length),
    lessonsTotal: lessonsAll.length,
    lessonsDelta: _pctDelta(lessonsCurr.length, lessonsPrior.length),
    stepsTotal: stepsAll.length,
    stepsDistinctTypes: distinctTypes,
    stepsDelta: _pctDelta(stepsCurrLen, stepsPriorLen),
    stepTypesTotal: stepTypesDef.length,
    learnersTotal: profilesAll.length,
    learnersNew14d: profiles14d.length,
    learnersDelta: _pctDelta(profilesCurr.length, profilesPrior.length),
    subLevelsPassed: passedAll,
    subLevelsAttempts: progressAll.length,
    subLevelsDelta: _pctDelta(passedCurr, passedPrior),
  );
});

/// course_assessment_progress where is_passed=true, grouped by ISO week, last 12w.
/// Source: course_assessment_progress · is_passed=true · last 12w
final assessmentProgressWeeklyProvider =
    FutureProvider<List<WeeklyPassCount>>((ref) async {
  final client = Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final cutoff = now.subtract(const Duration(days: 84));

  final List data = await client
      .from('course_assessment_progress')
      .select('created_at')
      .eq('is_passed', true)
      .gte('created_at', cutoff.toIso8601String())
      .order('created_at', ascending: true);

  // Build 12 ordered week buckets (Mon-based)
  final thisWeekMon = _isoWeekStart(now);
  final buckets = <DateTime, int>{};
  for (int i = 11; i >= 0; i--) {
    buckets[thisWeekMon.subtract(Duration(days: i * 7))] = 0;
  }
  final weekKeys = buckets.keys.toList()..sort();

  for (final row in data) {
    final raw = row['created_at'];
    if (raw == null) continue;
    final dt = DateTime.tryParse(raw as String)?.toUtc();
    if (dt == null) continue;
    final ws = _isoWeekStart(dt);
    // Place in the matching (or nearest past) bucket
    DateTime? matched;
    for (final k in weekKeys) {
      if (!ws.isBefore(k)) matched = k;
    }
    if (matched != null) buckets[matched] = (buckets[matched] ?? 0) + 1;
  }

  return weekKeys
      .map((k) => WeeklyPassCount(weekStart: k, count: buckets[k] ?? 0))
      .toList();
});

/// Per-course pass rate: passed sublevels ÷ total sublevels.
/// Source: course_assessment_progress / assessment_sublevels joined via levels
final coursePassRatesProvider =
    FutureProvider<List<CoursePassRate>>((ref) async {
  final client = Supabase.instance.client;

  // All four tables needed for the join
  final List assessments =
      await client.from('course_assessments').select('id, course_id, title');
  final List courses = await client.from('courses').select('id, title');
  final List levels =
      await client.from('assessment_levels').select('id, assessment_id');
  final List sublevels =
      await client.from('assessment_sublevels').select('id, level_id');
  final List passed = await client
      .from('course_assessment_progress')
      .select('sublevel_id, assessment_id')
      .eq('is_passed', true);

  // Build lookup maps
  final courseNames = <String, String>{
    for (final c in courses) c['id'] as String: (c['title'] as String?) ?? ''
  };
  final levelsByAssessment = <String, Set<String>>{};
  for (final l in levels) {
    levelsByAssessment
        .putIfAbsent(l['assessment_id'] as String, () => {})
        .add(l['id'] as String);
  }
  final sublevelsByLevel = <String, Set<String>>{};
  for (final s in sublevels) {
    sublevelsByLevel
        .putIfAbsent(s['level_id'] as String, () => {})
        .add(s['id'] as String);
  }
  // assessment_id → Set of distinct passed sublevel_ids
  final passedByAssessment = <String, Set<String>>{};
  for (final p in passed) {
    passedByAssessment
        .putIfAbsent(p['assessment_id'] as String, () => {})
        .add(p['sublevel_id'] as String);
  }

  return assessments.map((a) {
    final assessmentId = a['id'] as String;
    final courseId = a['course_id'] as String;
    final title = courseNames[courseId] ?? (a['title'] as String? ?? '');

    // All sublevel IDs for this assessment
    final levelIds = levelsByAssessment[assessmentId] ?? {};
    final allSublevelIds = <String>{};
    for (final lid in levelIds) {
      allSublevelIds.addAll(sublevelsByLevel[lid] ?? {});
    }
    final passedSet = passedByAssessment[assessmentId] ?? {};
    final passedInAssessment = passedSet.intersection(allSublevelIds);

    return CoursePassRate(
      courseId: courseId,
      courseTitle: title,
      passed: passedInAssessment.length,
      total: allSublevelIds.length,
    );
  }).toList();
});

/// lesson_steps GROUP BY step_type, top 5, joined with lesson_step_types for display_name.
/// Source: lesson_steps group by step_type · lesson_step_types is_system=true
final stepTypeBreakdownProvider =
    FutureProvider<List<StepTypeCount>>((ref) async {
  final client = Supabase.instance.client;

  final List steps =
      await client.from('lesson_steps').select('step_type');
  final List types =
      await client.from('lesson_step_types').select('key, display_name, category');

  // Build display name / category lookup
  final typeMeta = <String, Map<String, String>>{};
  for (final t in types) {
    typeMeta[t['key'] as String] = {
      'displayName': (t['display_name'] as String?) ?? (t['key'] as String),
      'category': (t['category'] as String?) ?? '',
    };
  }

  // Count occurrences per step_type key
  final counts = <String, int>{};
  for (final s in steps) {
    final key = (s['step_type'] as String?) ?? 'unknown';
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top5 = sorted.take(5);

  return top5.map((e) {
    final meta = typeMeta[e.key];
    return StepTypeCount(
      key: e.key,
      displayName: meta?['displayName'] ?? e.key,
      category: meta?['category'] ?? '',
      count: e.value,
    );
  }).toList();
});

/// Four catalog health counts derived from cross-table queries.
/// Source: modules ⟕ new_lessons · new_lessons ⟕ lesson_steps · courses.locked · assessment_sublevels.questions
final catalogHealthProvider = FutureProvider<CatalogHealth>((ref) async {
  final client = Supabase.instance.client;

  // 1. Modules without lessons: modules whose id doesn't appear in new_lessons.module_id
  final List moduleIds =
      await client.from('modules').select('id');
  final List lessonModuleIds =
      await client.from('new_lessons').select('module_id');
  final coveredModules =
      lessonModuleIds.map((l) => l['module_id'] as String).toSet();
  final modulesWithoutLessons = moduleIds
      .where((m) => !coveredModules.contains(m['id'] as String))
      .length;

  // 2. Lessons with no steps: new_lessons whose id doesn't appear in lesson_steps.lesson_id
  final List lessonIds =
      await client.from('new_lessons').select('id');
  final List stepLessonIds =
      await client.from('lesson_steps').select('lesson_id');
  final coveredLessons =
      stepLessonIds.map((s) => s['lesson_id'] as String).toSet();
  final lessonsWithNoSteps = lessonIds
      .where((l) => !coveredLessons.contains(l['id'] as String))
      .length;

  // 3. Locked courses
  final List lockedList =
      await client.from('courses').select('id').eq('locked', true);

  // 4. Sublevels with empty questions array
  final List allSublevels =
      await client.from('assessment_sublevels').select('id, questions');
  final emptyQuestions = allSublevels
      .where((s) {
        final q = s['questions'];
        if (q == null) return true;
        if (q is List) return q.isEmpty;
        return false;
      })
      .length;

  return CatalogHealth(
    modulesWithoutLessons: modulesWithoutLessons,
    lessonsWithNoSteps: lessonsWithNoSteps,
    lockedCourses: lockedList.length,
    sublevelsWithEmptyQuestions: emptyQuestions,
  );
});

/// profiles.created_at daily bins, last 14 days.
/// Source: profiles.created_at · last 14d
final newProfilesDailyProvider =
    FutureProvider<List<DailyProfileCount>>((ref) async {
  final client = Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final cutoff = DateTime.utc(now.year, now.month, now.day - 13);

  final List data = await client
      .from('profiles')
      .select('created_at')
      .gte('created_at', cutoff.toIso8601String());

  // Build 14 day buckets
  final buckets = <String, int>{};
  for (int i = 13; i >= 0; i--) {
    final d = DateTime.utc(now.year, now.month, now.day - i);
    buckets['${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'] = 0;
  }

  for (final row in data) {
    final raw = row['created_at'];
    if (raw == null) continue;
    final dt = DateTime.tryParse(raw as String)?.toUtc();
    if (dt == null) continue;
    final key =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    if (buckets.containsKey(key)) buckets[key] = buckets[key]! + 1;
  }

  return buckets.entries
      .map((e) => DailyProfileCount(
            date: DateTime.parse(e.key),
            count: e.value,
          ))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

/// admin_activity_logs order by created_at desc limit 6, with actor names resolved.
/// Source: admin_activity_logs · last 6 · joined profiles for actor name
final recentActivityWithActorProvider =
    FutureProvider<List<ActivityItem>>((ref) async {
  final client = Supabase.instance.client;

  final List activities = await client
      .from('admin_activity_logs')
      .select('id, actor_id, action, target_type, target_id, details, created_at')
      .order('created_at', ascending: false)
      .limit(6);

  if (activities.isEmpty) return [];

  // Fetch all profiles and match client-side (admin tool — small dataset)
  final List profilesAll =
      await client.from('profiles').select('id, first_name, last_name');
  final actorIds =
      activities.map((a) => a['actor_id'] as String).toSet();
  final nameMap = <String, String>{};
  for (final p in profilesAll) {
    final id = p['id'] as String;
    if (!actorIds.contains(id)) continue;
    final fn = (p['first_name'] as String?) ?? '';
    final ln = (p['last_name'] as String?) ?? '';
    final name = '$fn $ln'.trim();
    nameMap[id] = name.isEmpty ? 'Admin' : name;
  }

  return activities.map((a) {
    final actorId = a['actor_id'] as String;
    final name = nameMap[actorId] ?? 'Admin';
    final nameParts = name.split(' ');
    final fn = nameParts.isNotEmpty ? nameParts.first : '';
    final ln = nameParts.length > 1 ? nameParts.last : '';
    return ActivityItem(
      actorId: actorId,
      actorInitials: _initials(fn, ln),
      actorName: name,
      action: (a['action'] as String?) ?? '',
      targetType: a['target_type'] as String?,
      targetId: a['target_id'] as String?,
      details: a['details'] != null
          ? Map<String, dynamic>.from(a['details'] as Map)
          : null,
      createdAt: DateTime.tryParse((a['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }).toList();
});

/// One data-point in the "Catalog growth" two-series area chart.
/// Both counts are cumulative (running total up to the end of [weekStart]'s week).
class CatalogGrowthPoint {
  final DateTime weekStart;
  final int cumulativeLessons;
  final int cumulativeSteps;
  const CatalogGrowthPoint({
    required this.weekStart,
    required this.cumulativeLessons,
    required this.cumulativeSteps,
  });
}

/// Cumulative weekly counts for new_lessons and lesson_steps, last 12 weeks.
/// Both series are monotonically non-decreasing (all-time totals up to each week).
/// Source: new_lessons.created_at · lesson_steps.created_at · cumulative 12w
final catalogGrowthProvider =
    FutureProvider<List<CatalogGrowthPoint>>((ref) async {
  final client = Supabase.instance.client;
  final now = DateTime.now().toUtc();

  // Build 12 ordered Monday boundaries (oldest → newest)
  final thisWeekMon = _isoWeekStart(now);
  final weekBoundaries = <DateTime>[
    for (int i = 11; i >= 0; i--)
      thisWeekMon.subtract(Duration(days: i * 7))
  ];

  // Fetch ALL created_at values — needed for cumulative count
  final List lessonsRaw =
      await client.from('new_lessons').select('created_at');
  final List stepsRaw =
      await client.from('lesson_steps').select('created_at');

  List<DateTime> _parseDates(List rows) => rows
      .map((r) {
        final v = r['created_at'];
        if (v == null) return null;
        return DateTime.tryParse(v as String)?.toUtc();
      })
      .whereType<DateTime>()
      .toList()
    ..sort();

  final lessonDates = _parseDates(lessonsRaw);
  final stepDates = _parseDates(stepsRaw);

  // For each week, count all items created BEFORE the end of that week
  // (end = start of next week), giving a monotonic cumulative series.
  return weekBoundaries.map((weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return CatalogGrowthPoint(
      weekStart: weekStart,
      cumulativeLessons: lessonDates.where((d) => d.isBefore(weekEnd)).length,
      cumulativeSteps: stepDates.where((d) => d.isBefore(weekEnd)).length,
    );
  }).toList();
});

/// Name of the currently signed-in admin from the profiles table.
final currentAdminNameProvider = FutureProvider<String>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return 'Admin';
  final client = Supabase.instance.client;
  final data = await client
      .from('profiles')
      .select('first_name, last_name')
      .eq('id', user.id)
      .maybeSingle();
  if (data == null) return user.email?.split('@').first ?? 'Admin';
  final fn = (data['first_name'] as String?) ?? '';
  final ln = (data['last_name'] as String?) ?? '';
  final name = '$fn $ln'.trim();
  return name.isEmpty
      ? (user.email?.split('@').first ?? 'Admin')
      : name.split(' ').first; // first name only in greeting
});
