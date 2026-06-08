import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:milpress_dashboard/features/auth/admin_activity_repository.dart';
import 'package:milpress_dashboard/features/auth/activity_actions.dart';

import 'subscription_enums.dart';
import 'subscription_models.dart';

// =============================================================================
// Repository
// =============================================================================
class SubscriptionRepository {
  final SupabaseClient _client;
  SubscriptionRepository(this._client);

  static const String table = 'subscriptions';

  // ---------------------------------------------------------------------------
  // READ — list
  // ---------------------------------------------------------------------------
  Future<List<Subscription>> fetchSubscriptions({
    SubscriptionsQuery? query,
  }) async {
    // Join profiles so the dashboard can display user name & email in one query
    dynamic qb = _client.from(table).select(
      '*, profiles!subscriptions_profile_fkey(first_name, last_name, email)',
    );

    // Plan filter
    if (query?.plan != null) {
      qb = qb.eq('plan', query!.plan!.dbValue);
    }

    // Status filter
    if (query?.status != null) {
      qb = qb.eq('status', query!.status!.dbValue);
    }

    // Billing cycle filter
    if (query?.billingCycle != null) {
      qb = qb.eq('billing_cycle', query!.billingCycle!.dbValue);
    }

    // Text search — searches against the joined profile fields via Postgres
    // We filter client-side after fetching since Supabase doesn't support
    // ilike on joined columns in the JS/Dart client easily.
    final q = query?.search?.trim().toLowerCase();

    qb = qb.order(
      query?.orderBy ?? 'created_at',
      ascending: query?.ascending ?? false,
    );

    qb = qb.limit(query?.limit ?? 50);

    if ((query?.offset ?? 0) > 0) {
      final offset = query!.offset;
      final end    = offset + (query.limit) - 1;
      qb = qb.range(offset, end);
    }

    final List data = await qb;
    final results = data
        .map((e) => Subscription.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Client-side search filter on joined profile columns
    if (q != null && q.isNotEmpty) {
      return results.where((s) {
        return (s.userEmail?.toLowerCase().contains(q) ?? false) ||
               (s.userFirstName?.toLowerCase().contains(q) ?? false) ||
               (s.userLastName?.toLowerCase().contains(q) ?? false) ||
               s.userFullName.toLowerCase().contains(q);
      }).toList();
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // READ — single
  // ---------------------------------------------------------------------------
  Future<Subscription?> fetchByUserId(String userId) async {
    final data = await _client
        .from(table)
        .select('*, profiles!subscriptions_profile_fkey(first_name, last_name, email)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return null;
    return Subscription.fromMap(Map<String, dynamic>.from(data));
  }

  Future<Subscription?> fetchById(String id) async {
    final data = await _client
        .from(table)
        .select('*, profiles!subscriptions_profile_fkey(first_name, last_name, email)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Subscription.fromMap(Map<String, dynamic>.from(data));
  }

  // ---------------------------------------------------------------------------
  // UPDATE — admin manual overrides only
  // (new subscriptions come from the payment provider webhook)
  // ---------------------------------------------------------------------------
  Future<void> updateSubscription(String id, SubscriptionUpdate update) async {
    await _client
        .from(table)
        .update(update.toUpdateMap())
        .eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // KPIs — aggregated numbers for the dashboard strip
  // ---------------------------------------------------------------------------
  Future<SubscriptionKpis> fetchKpis() async {
    // Fetch all active individual subscriptions for aggregation
    final List activeSubs = await _client
        .from(table)
        .select('plan, billing_cycle, status')
        .eq('status', SubStatus.active.dbValue);

    int totalPremium  = 0;
    double mrrUsd     = 0;

    for (final row in activeSubs) {
      final plan  = PlanType.fromString(row['plan'] as String?);
      final cycle = BillingCycle.fromString(row['billing_cycle'] as String?);

      if (plan == PlanType.premium) {
        totalPremium++;
        // MRR contribution: monthly = $4.99, annual = $4.99 × 12 / 12 = $4.99
        mrrUsd += 4.99;
        if (cycle == BillingCycle.annual) {
          // Annual subscribers pay $4.99/mo equivalent — already counted above.
          // If you introduce a discounted annual price, adjust here.
        }
      }
    }

    // Active org subscriptions add to MRR
    final List orgSubs = await _client
        .from('org_subscriptions')
        .select('amount_usd')
        .eq('status', SubStatus.active.dbValue);

    for (final row in orgSubs) {
      final amount = (row['amount_usd'] as num?)?.toDouble() ?? 0;
      mrrUsd += amount;
    }

    // Sponsored learners count
    final List sponsoredGrants = await _client
        .from('sponsored_grants')
        .select('id')
        .eq('status', GrantStatus.active.dbValue);

    // Free users = total profiles minus any active premium/sponsored
    final List allProfiles = await _client
        .from('profiles')
        .select('plan_type');

    final totalSponsored = allProfiles
        .where((p) => p['plan_type'] == PlanType.sponsored.dbValue)
        .length;
    final totalFree = allProfiles
        .where((p) => p['plan_type'] == PlanType.free.dbValue)
        .length;

    // Cancelled this calendar month
    final monthStart = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    );
    final List cancelled = await _client
        .from(table)
        .select('id')
        .eq('status', SubStatus.cancelled.dbValue)
        .gte('cancelled_at', monthStart.toIso8601String());

    return SubscriptionKpis(
      totalPremium: totalPremium,
      totalSponsored: sponsoredGrants.length,
      totalFree: totalFree,
      mrrUsd: mrrUsd,
      cancelledThisMonth: cancelled.length,
    );
  }

  // ---------------------------------------------------------------------------
  // READ — all users with their plan (profiles + optional subscription)
  // ---------------------------------------------------------------------------
  Future<List<UserPlanEntry>> fetchUserPlans({
    SubscriptionsQuery? query,
  }) async {
    // Step 1: query profiles filtered by plan_type
    dynamic qb = _client
        .from('profiles')
        .select('id, first_name, last_name, email, plan_type, created_at');

    if (query?.plan != null) {
      qb = qb.eq('plan_type', query!.plan!.dbValue);
    }

    qb = qb.order(
      query?.orderBy ?? 'created_at',
      ascending: query?.ascending ?? false,
    );
    qb = qb.limit(query?.limit ?? 50);

    if ((query?.offset ?? 0) > 0) {
      final offset = query!.offset;
      qb = qb.range(offset, offset + query.limit - 1);
    }

    final List profileData = await qb;

    // Step 2: enrich with subscription rows for these users
    final userIds =
        profileData.map((p) => p['id'] as String).toList();

    final Map<String, Map<String, dynamic>> subsByUserId = {};
    if (userIds.isNotEmpty) {
      final List subsData = await _client
          .from(table)
          .select(
            'id, user_id, plan, status, billing_cycle, '
            'current_period_start, current_period_end, '
            'cancel_at_period_end, cancelled_at, '
            'payment_provider, external_sub_id',
          )
          .inFilter('user_id', userIds);

      for (final sub in subsData) {
        final uid = sub['user_id'] as String;
        // Keep the most recent subscription per user
        subsByUserId.putIfAbsent(uid, () => Map<String, dynamic>.from(sub));
      }
    }

    // Step 3: merge and apply status / text filters
    var entries = profileData
        .map((p) => UserPlanEntry.fromProfileAndSub(
              profile: Map<String, dynamic>.from(p as Map),
              sub: subsByUserId[p['id'] as String],
            ))
        .toList();

    // Status filter (only meaningful for premium; free/sponsored are always active)
    if (query?.status != null) {
      entries = entries.where((e) {
        if (e.hasPaidSubscription) return e.subStatus == query!.status;
        return query!.status == SubStatus.active;
      }).toList();
    }

    // Text search
    final q = query?.search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      entries = entries.where((e) {
        return (e.email?.toLowerCase().contains(q) ?? false) ||
            e.displayName.toLowerCase().contains(q);
      }).toList();
    }

    return entries;
  }

  // ---------------------------------------------------------------------------
  // READ — single user plan entry (for detail panel)
  // ---------------------------------------------------------------------------
  Future<UserPlanEntry?> fetchUserPlanById(String userId) async {
    final profileData = await _client
        .from('profiles')
        .select('id, first_name, last_name, email, plan_type, created_at')
        .eq('id', userId)
        .maybeSingle();

    if (profileData == null) return null;

    final subData = await _client
        .from(table)
        .select(
          'id, user_id, plan, status, billing_cycle, '
          'current_period_start, current_period_end, '
          'cancel_at_period_end, cancelled_at, '
          'payment_provider, external_sub_id, external_customer_id',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return UserPlanEntry.fromProfileAndSub(
      profile: Map<String, dynamic>.from(profileData),
      sub: subData != null ? Map<String, dynamic>.from(subData) : null,
    );
  }
}

// =============================================================================
// Providers — repository singleton
// =============================================================================
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(Supabase.instance.client);
});

// Read providers
final subscriptionsListProvider = FutureProvider.family<
    List<Subscription>, SubscriptionsQuery?>((ref, query) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchSubscriptions(query: query);
});

final subscriptionByUserProvider =
    FutureProvider.family<Subscription?, String>((ref, userId) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchByUserId(userId);
});

final subscriptionKpisProvider =
    FutureProvider<SubscriptionKpis>((ref) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchKpis();
});

// All users with their plan — drives the Subscriptions screen list
final userPlansListProvider = FutureProvider.family<
    List<UserPlanEntry>, SubscriptionsQuery?>((ref, query) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchUserPlans(query: query);
});

// Single user plan entry — drives the Subscriptions screen detail panel
final userPlanByUserIdProvider =
    FutureProvider.family<UserPlanEntry?, String>((ref, userId) async {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return repo.fetchUserPlanById(userId);
});

// =============================================================================
// Mutation controllers
// =============================================================================

// Cancel a subscription
class CancelSubscriptionController extends StateNotifier<AsyncValue<void>> {
  final SubscriptionRepository _repo;
  final Ref _ref;
  CancelSubscriptionController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> cancel(Subscription sub) async {
    state = const AsyncLoading();
    try {
      final update = SubscriptionUpdate(
        status: SubStatus.cancelled,
        cancelledAt: DateTime.now(),
        cancelAtPeriodEnd: false,
      );
      await _repo.updateSubscription(sub.id, update);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.subscriptionCancelled,
        targetType: 'subscription',
        targetId: sub.id,
        details: {
          'user_id': sub.userId,
          'user_email': sub.userEmail,
          'plan': sub.plan.dbValue,
          'billing_cycle': sub.billingCycle.dbValue,
        },
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final cancelSubscriptionProvider = StateNotifierProvider<
    CancelSubscriptionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return CancelSubscriptionController(repo, ref);
});

// Extend a subscription's period end date
class ExtendSubscriptionController extends StateNotifier<AsyncValue<void>> {
  final SubscriptionRepository _repo;
  final Ref _ref;
  ExtendSubscriptionController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> extend(Subscription sub, DateTime newPeriodEnd) async {
    state = const AsyncLoading();
    try {
      final update = SubscriptionUpdate(
        status: SubStatus.active,
        currentPeriodEnd: newPeriodEnd,
      );
      await _repo.updateSubscription(sub.id, update);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.subscriptionExtended,
        targetType: 'subscription',
        targetId: sub.id,
        details: {
          'user_id': sub.userId,
          'user_email': sub.userEmail,
          'old_period_end': sub.currentPeriodEnd.toIso8601String(),
          'new_period_end': newPeriodEnd.toIso8601String(),
        },
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final extendSubscriptionProvider = StateNotifierProvider<
    ExtendSubscriptionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(subscriptionRepositoryProvider);
  return ExtendSubscriptionController(repo, ref);
});
