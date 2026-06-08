import 'subscription_enums.dart';

// =============================================================================
// UserPlanEntry — a unified view of every user's plan status.
//
// Sourced from `profiles` (always present) enriched with data from
// `subscriptions` (present only for paid/premium users).  Free and sponsored
// learners have a valid UserPlanEntry with subscriptionId == null.
// =============================================================================
class UserPlanEntry {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final PlanType planType;
  final DateTime createdAt;

  // Present only when the user has a row in the subscriptions table
  final String? subscriptionId;
  final SubStatus? subStatus;
  final BillingCycle? billingCycle;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final DateTime? cancelledAt;
  final String? paymentProvider;
  final String? externalSubId;

  UserPlanEntry({
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    required this.planType,
    required this.createdAt,
    this.subscriptionId,
    this.subStatus,
    this.billingCycle,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.cancelledAt,
    this.paymentProvider,
    this.externalSubId,
  });

  bool get hasPaidSubscription => subscriptionId != null;

  /// Effective status: real sub status for paid users, active for everyone else.
  SubStatus get effectiveStatus => subStatus ?? SubStatus.active;

  String get displayName {
    final parts = [firstName, lastName]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? (email ?? userId) : parts.join(' ');
  }

  factory UserPlanEntry.fromProfileAndSub({
    required Map<String, dynamic> profile,
    Map<String, dynamic>? sub,
  }) {
    return UserPlanEntry(
      userId: profile['id'] as String,
      firstName: profile['first_name'] as String?,
      lastName: profile['last_name'] as String?,
      email: profile['email'] as String?,
      planType: PlanType.fromString(profile['plan_type'] as String?),
      createdAt: _toDateTime(profile['created_at']) ?? DateTime.now(),
      subscriptionId: sub?['id'] as String?,
      subStatus: sub != null
          ? SubStatus.fromString(sub['status'] as String?)
          : null,
      billingCycle: sub != null
          ? BillingCycle.fromString(sub['billing_cycle'] as String?)
          : null,
      currentPeriodStart: _toDateTime(sub?['current_period_start']),
      currentPeriodEnd: _toDateTime(sub?['current_period_end']),
      cancelAtPeriodEnd: (sub?['cancel_at_period_end'] as bool?) ?? false,
      cancelledAt: _toDateTime(sub?['cancelled_at']),
      paymentProvider: sub?['payment_provider'] as String?,
      externalSubId: sub?['external_sub_id'] as String?,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

// =============================================================================
// Subscription  — mirrors the `subscriptions` table.
// Joined with `profiles` so the dashboard can display user info without a
// second query.
// =============================================================================
class Subscription {
  final String id;
  final String userId;

  // Denormalised from profiles (populated via JOIN in the repository)
  final String? userFirstName;
  final String? userLastName;
  final String? userEmail;

  final PlanType plan;
  final SubStatus status;
  final BillingCycle billingCycle;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final String? paymentProvider;
  final String? externalSubId;
  final String? externalCustomerId;
  final bool cancelAtPeriodEnd;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    this.userFirstName,
    this.userLastName,
    this.userEmail,
    required this.plan,
    required this.status,
    required this.billingCycle,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.paymentProvider,
    this.externalSubId,
    this.externalCustomerId,
    this.cancelAtPeriodEnd = false,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get userFullName {
    final parts = [userFirstName, userLastName]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? userEmail ?? 'Unknown' : parts.join(' ');
  }

  bool get isActive => status.isActive && currentPeriodEnd.isAfter(DateTime.now());

  factory Subscription.fromMap(Map<String, dynamic> map) {
    // The repository joins profiles — profile fields are nested under 'profiles'
    final profile = map['profiles'] as Map<String, dynamic>?;

    return Subscription(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      userFirstName: profile?['first_name'] as String?,
      userLastName: profile?['last_name'] as String?,
      userEmail: profile?['email'] as String?,
      plan: PlanType.fromString(map['plan'] as String?),
      status: SubStatus.fromString(map['status'] as String?),
      billingCycle: BillingCycle.fromString(map['billing_cycle'] as String?),
      currentPeriodStart: _toDateTime(map['current_period_start'])!,
      currentPeriodEnd: _toDateTime(map['current_period_end'])!,
      paymentProvider: map['payment_provider'] as String?,
      externalSubId: map['external_sub_id'] as String?,
      externalCustomerId: map['external_customer_id'] as String?,
      cancelAtPeriodEnd: (map['cancel_at_period_end'] as bool?) ?? false,
      cancelledAt: _toDateTime(map['cancelled_at']),
      createdAt: _toDateTime(map['created_at'])!,
      updatedAt: _toDateTime(map['updated_at'])!,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Subscription copyWith({
    SubStatus? status,
    bool? cancelAtPeriodEnd,
    DateTime? cancelledAt,
    DateTime? currentPeriodEnd,
  }) {
    return Subscription(
      id: id,
      userId: userId,
      userFirstName: userFirstName,
      userLastName: userLastName,
      userEmail: userEmail,
      plan: plan,
      status: status ?? this.status,
      billingCycle: billingCycle,
      currentPeriodStart: currentPeriodStart,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      paymentProvider: paymentProvider,
      externalSubId: externalSubId,
      externalCustomerId: externalCustomerId,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// =============================================================================
// SubscriptionUpdate — what the dashboard can change manually.
// (Upgrades / new subscriptions are handled by the payment provider webhook.)
// =============================================================================
class SubscriptionUpdate {
  final SubStatus? status;
  final bool? cancelAtPeriodEnd;
  final DateTime? currentPeriodEnd; // admin can extend a period
  final DateTime? cancelledAt;

  SubscriptionUpdate({
    this.status,
    this.cancelAtPeriodEnd,
    this.currentPeriodEnd,
    this.cancelledAt,
  });

  Map<String, dynamic> toUpdateMap() {
    return {
      if (status != null) 'status': status!.dbValue,
      if (cancelAtPeriodEnd != null) 'cancel_at_period_end': cancelAtPeriodEnd,
      if (currentPeriodEnd != null) 'current_period_end': currentPeriodEnd!.toIso8601String(),
      if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// =============================================================================
// SubscriptionKpis — summary numbers shown in the dashboard KPI strip.
// =============================================================================
class SubscriptionKpis {
  final int totalPremium;
  final int totalSponsored;
  final int totalFree;
  final double mrrUsd;         // Monthly Recurring Revenue
  final int cancelledThisMonth;

  const SubscriptionKpis({
    required this.totalPremium,
    required this.totalSponsored,
    required this.totalFree,
    required this.mrrUsd,
    required this.cancelledThisMonth,
  });

  static const empty = SubscriptionKpis(
    totalPremium: 0,
    totalSponsored: 0,
    totalFree: 0,
    mrrUsd: 0,
    cancelledThisMonth: 0,
  );
}

// =============================================================================
// SubscriptionsQuery — filter / sort / paginate the list view.
// =============================================================================
class SubscriptionsQuery {
  final String? search;         // searches user name / email
  final PlanType? plan;
  final SubStatus? status;
  final BillingCycle? billingCycle;
  final int limit;
  final int offset;
  final String orderBy;
  final bool ascending;

  const SubscriptionsQuery({
    this.search,
    this.plan,
    this.status,
    this.billingCycle,
    this.limit = 50,
    this.offset = 0,
    this.orderBy = 'created_at',
    this.ascending = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionsQuery &&
          search == other.search &&
          plan == other.plan &&
          status == other.status &&
          billingCycle == other.billingCycle &&
          limit == other.limit &&
          offset == other.offset &&
          orderBy == other.orderBy &&
          ascending == other.ascending;

  @override
  int get hashCode => Object.hash(
      search, plan, status, billingCycle, limit, offset, orderBy, ascending);
}
