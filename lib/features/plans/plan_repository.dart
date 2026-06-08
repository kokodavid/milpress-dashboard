import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'plan_models.dart';

// =============================================================================
// PlansRepository
// =============================================================================
class PlansRepository {
  final SupabaseClient _client;
  PlansRepository(this._client);

  static const String _plansTable    = 'subscription_plans';
  static const String _featuresTable = 'plan_features';

  // ---------------------------------------------------------------------------
  // READ — all plans with their features
  // ---------------------------------------------------------------------------
  Future<List<SubscriptionPlan>> fetchPlans({bool activeOnly = false}) async {
    dynamic qb = _client
        .from(_plansTable)
        .select('*, plan_features(*)');

    if (activeOnly) qb = qb.eq('is_active', true);

    qb = qb.order('sort_order', ascending: true);

    final List data = await qb;
    return data
        .map((e) => SubscriptionPlan.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------
  Future<SubscriptionPlan> createPlan(SubscriptionPlanCreate input) async {
    final data = await _client
        .from(_plansTable)
        .insert(input.toInsertMap())
        .select('*, plan_features(*)')
        .single();

    return SubscriptionPlan.fromMap(Map<String, dynamic>.from(data));
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------
  Future<SubscriptionPlan> updatePlan(
      String planId, SubscriptionPlanUpdate update) async {
    final data = await _client
        .from(_plansTable)
        .update(update.toUpdateMap())
        .eq('id', planId)
        .select('*, plan_features(*)')
        .single();

    return SubscriptionPlan.fromMap(Map<String, dynamic>.from(data));
  }

  // ---------------------------------------------------------------------------
  // TOGGLE active / highlighted
  // ---------------------------------------------------------------------------
  Future<void> toggleActive(String planId, bool isActive) async {
    await _client
        .from(_plansTable)
        .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', planId);
  }

  Future<void> toggleHighlighted(String planId, bool isHighlighted) async {
    await _client
        .from(_plansTable)
        .update({'is_highlighted': isHighlighted, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', planId);
  }

  // ---------------------------------------------------------------------------
  // DELETE plan (cascades to features)
  // ---------------------------------------------------------------------------
  Future<void> deletePlan(String planId) async {
    await _client.from(_plansTable).delete().eq('id', planId);
  }

  // ---------------------------------------------------------------------------
  // FEATURES — add
  // ---------------------------------------------------------------------------
  Future<PlanFeature> addFeature(PlanFeature feature) async {
    final data = await _client
        .from(_featuresTable)
        .insert(feature.toInsertMap())
        .select()
        .single();

    return PlanFeature.fromMap(Map<String, dynamic>.from(data));
  }

  // ---------------------------------------------------------------------------
  // FEATURES — update label / included
  // ---------------------------------------------------------------------------
  Future<void> updateFeature(String featureId,
      {String? label, bool? isIncluded}) async {
    await _client.from(_featuresTable).update({
      if (label      != null) 'label':       label,
      if (isIncluded != null) 'is_included': isIncluded,
    }).eq('id', featureId);
  }

  // ---------------------------------------------------------------------------
  // FEATURES — delete
  // ---------------------------------------------------------------------------
  Future<void> deleteFeature(String featureId) async {
    await _client.from(_featuresTable).delete().eq('id', featureId);
  }
}

// =============================================================================
// Providers
// =============================================================================
final plansRepositoryProvider = Provider<PlansRepository>((ref) {
  return PlansRepository(Supabase.instance.client);
});

final plansListProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  return ref.watch(plansRepositoryProvider).fetchPlans();
});

// =============================================================================
// Mutation controllers
// =============================================================================

// Create plan
class CreatePlanController extends StateNotifier<AsyncValue<void>> {
  final PlansRepository _repo;
  final Ref _ref;
  CreatePlanController(this._repo, this._ref) : super(const AsyncData(null));

  Future<SubscriptionPlan?> create(SubscriptionPlanCreate input) async {
    state = const AsyncLoading();
    try {
      final plan = await _repo.createPlan(input);
      _ref.invalidate(plansListProvider);
      state = const AsyncData(null);
      return plan;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createPlanProvider =
    StateNotifierProvider<CreatePlanController, AsyncValue<void>>((ref) {
  return CreatePlanController(ref.watch(plansRepositoryProvider), ref);
});

// Update plan
class UpdatePlanController extends StateNotifier<AsyncValue<void>> {
  final PlansRepository _repo;
  final Ref _ref;
  UpdatePlanController(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> update(String planId, SubscriptionPlanUpdate input) async {
    state = const AsyncLoading();
    try {
      await _repo.updatePlan(planId, input);
      _ref.invalidate(plansListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updatePlanProvider =
    StateNotifierProvider<UpdatePlanController, AsyncValue<void>>((ref) {
  return UpdatePlanController(ref.watch(plansRepositoryProvider), ref);
});

// Toggle / delete
class PlanActionsController extends StateNotifier<AsyncValue<void>> {
  final PlansRepository _repo;
  final Ref _ref;
  PlanActionsController(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> toggleActive(String planId, bool value) async {
    await _repo.toggleActive(planId, value);
    _ref.invalidate(plansListProvider);
  }

  Future<void> toggleHighlighted(String planId, bool value) async {
    await _repo.toggleHighlighted(planId, value);
    _ref.invalidate(plansListProvider);
  }

  Future<void> deletePlan(String planId) async {
    state = const AsyncLoading();
    try {
      await _repo.deletePlan(planId);
      _ref.invalidate(plansListProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> addFeature(PlanFeature feature) async {
    await _repo.addFeature(feature);
    _ref.invalidate(plansListProvider);
  }

  Future<void> updateFeature(String featureId,
      {String? label, bool? isIncluded}) async {
    await _repo.updateFeature(featureId, label: label, isIncluded: isIncluded);
    _ref.invalidate(plansListProvider);
  }

  Future<void> deleteFeature(String featureId) async {
    await _repo.deleteFeature(featureId);
    _ref.invalidate(plansListProvider);
  }
}

final planActionsProvider =
    StateNotifierProvider<PlanActionsController, AsyncValue<void>>((ref) {
  return PlanActionsController(ref.watch(plansRepositoryProvider), ref);
});
