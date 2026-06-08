import '../subscriptions/subscription_enums.dart';

// =============================================================================
// PlanFeature  — mirrors plan_features table
// =============================================================================
class PlanFeature {
  final String id;
  final String planId;
  final String label;
  final bool isIncluded;
  final int sortOrder;
  final DateTime createdAt;

  PlanFeature({
    required this.id,
    required this.planId,
    required this.label,
    required this.isIncluded,
    required this.sortOrder,
    required this.createdAt,
  });

  factory PlanFeature.fromMap(Map<String, dynamic> map) {
    return PlanFeature(
      id:        map['id'] as String,
      planId:    map['plan_id'] as String,
      label:     map['label'] as String,
      isIncluded: (map['is_included'] as bool?) ?? true,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toInsertMap() => {
    'plan_id':    planId,
    'label':      label,
    'is_included': isIncluded,
    'sort_order': sortOrder,
  };

  PlanFeature copyWith({String? label, bool? isIncluded, int? sortOrder}) =>
      PlanFeature(
        id: id, planId: planId,
        label:      label      ?? this.label,
        isIncluded: isIncluded ?? this.isIncluded,
        sortOrder:  sortOrder  ?? this.sortOrder,
        createdAt:  createdAt,
      );

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

// =============================================================================
// SubscriptionPlan  — mirrors subscription_plans table
// =============================================================================
class SubscriptionPlan {
  final String id;
  final String name;
  final String? description;
  final PlanType planType;
  final BillingCycle billingCycle;
  final double priceUsd;
  final bool isActive;
  final bool isHighlighted;
  final int sortOrder;
  final String? stripePriceId;
  final String? rcProductId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Populated via JOIN when fetching with features
  final List<PlanFeature> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.planType,
    required this.billingCycle,
    required this.priceUsd,
    required this.isActive,
    required this.isHighlighted,
    required this.sortOrder,
    this.stripePriceId,
    this.rcProductId,
    required this.createdAt,
    required this.updatedAt,
    this.features = const [],
  });

  String get formattedPrice =>
      priceUsd == 0 ? 'Free' : '\$${priceUsd.toStringAsFixed(2)}';

  String get priceLabel {
    if (priceUsd == 0) return 'Free';
    return '\$${priceUsd.toStringAsFixed(2)} / ${billingCycle.label.toLowerCase()}';
  }

  factory SubscriptionPlan.fromMap(Map<String, dynamic> map) {
    final rawFeatures = map['plan_features'] as List?;
    final features = rawFeatures
            ?.map((f) => PlanFeature.fromMap(Map<String, dynamic>.from(f as Map)))
            .toList() ??
        [];
    features.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return SubscriptionPlan(
      id:            map['id'] as String,
      name:          map['name'] as String,
      description:   map['description'] as String?,
      planType:      PlanType.fromString(map['plan_type'] as String?),
      billingCycle:  BillingCycle.fromString(map['billing_cycle'] as String?),
      priceUsd:      (map['price_usd'] as num?)?.toDouble() ?? 0,
      isActive:      (map['is_active'] as bool?) ?? true,
      isHighlighted: (map['is_highlighted'] as bool?) ?? false,
      sortOrder:     (map['sort_order'] as int?) ?? 0,
      stripePriceId: map['stripe_price_id'] as String?,
      rcProductId:   map['rc_product_id'] as String?,
      createdAt:     _toDateTime(map['created_at']) ?? DateTime.now(),
      updatedAt:     _toDateTime(map['updated_at']) ?? DateTime.now(),
      features:      features,
    );
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}

// =============================================================================
// SubscriptionPlanCreate — payload for inserting a new plan
// =============================================================================
class SubscriptionPlanCreate {
  final String name;
  final String? description;
  final PlanType planType;
  final BillingCycle billingCycle;
  final double priceUsd;
  final bool isHighlighted;
  final int sortOrder;
  final String? stripePriceId;
  final String? rcProductId;

  SubscriptionPlanCreate({
    required this.name,
    this.description,
    required this.planType,
    required this.billingCycle,
    required this.priceUsd,
    this.isHighlighted = false,
    this.sortOrder = 0,
    this.stripePriceId,
    this.rcProductId,
  });

  Map<String, dynamic> toInsertMap() => {
    'name':           name,
    if (description != null) 'description': description,
    'plan_type':      planType.dbValue,
    'billing_cycle':  billingCycle.dbValue,
    'price_usd':      priceUsd,
    'is_active':      true,
    'is_highlighted': isHighlighted,
    'sort_order':     sortOrder,
    if (stripePriceId != null) 'stripe_price_id': stripePriceId,
    if (rcProductId   != null) 'rc_product_id':   rcProductId,
  };
}

// =============================================================================
// SubscriptionPlanUpdate — fields the dashboard can change
// =============================================================================
class SubscriptionPlanUpdate {
  final String? name;
  final String? description;
  final double? priceUsd;
  final bool? isActive;
  final bool? isHighlighted;
  final int? sortOrder;
  final String? stripePriceId;
  final String? rcProductId;

  SubscriptionPlanUpdate({
    this.name,
    this.description,
    this.priceUsd,
    this.isActive,
    this.isHighlighted,
    this.sortOrder,
    this.stripePriceId,
    this.rcProductId,
  });

  Map<String, dynamic> toUpdateMap() => {
    if (name          != null) 'name':           name,
    if (description   != null) 'description':    description,
    if (priceUsd      != null) 'price_usd':      priceUsd,
    if (isActive      != null) 'is_active':      isActive,
    if (isHighlighted != null) 'is_highlighted': isHighlighted,
    if (sortOrder     != null) 'sort_order':     sortOrder,
    if (stripePriceId != null) 'stripe_price_id': stripePriceId,
    if (rcProductId   != null) 'rc_product_id':  rcProductId,
    'updated_at': DateTime.now().toIso8601String(),
  };
}
