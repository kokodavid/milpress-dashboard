// Shared enums that mirror the Postgres enum types defined in the migration.
// Values must match the DB enum strings exactly.

enum PlanType {
  free,
  premium,
  sponsored;

  static PlanType fromString(String? value) {
    return switch (value) {
      'premium'   => PlanType.premium,
      'sponsored' => PlanType.sponsored,
      _           => PlanType.free,
    };
  }

  String get dbValue => name; // 'free' | 'premium' | 'sponsored'

  String get label => switch (this) {
    PlanType.free      => 'Free',
    PlanType.premium   => 'Premium',
    PlanType.sponsored => 'Sponsored',
  };
}

enum OrgPlan {
  starter,
  growth,
  enterprise;

  static OrgPlan fromString(String? value) {
    return switch (value) {
      'growth'     => OrgPlan.growth,
      'enterprise' => OrgPlan.enterprise,
      _            => OrgPlan.starter,
    };
  }

  String get dbValue => name;

  String get label => switch (this) {
    OrgPlan.starter    => 'Starter',
    OrgPlan.growth     => 'Growth',
    OrgPlan.enterprise => 'Enterprise',
  };

  /// Seat cap — null means unlimited (Enterprise)
  int? get seatLimit => switch (this) {
    OrgPlan.starter    => 30,
    OrgPlan.growth     => 150,
    OrgPlan.enterprise => null,
  };

  /// Monthly price in USD — null for Enterprise (contact us)
  double? get monthlyPrice => switch (this) {
    OrgPlan.starter    => 129.99,
    OrgPlan.growth     => 699.99,
    OrgPlan.enterprise => null,
  };
}

enum SubStatus {
  trialing,
  active,
  pastDue,
  cancelled,
  expired;

  static SubStatus fromString(String? value) {
    return switch (value) {
      'trialing'  => SubStatus.trialing,
      'active'    => SubStatus.active,
      'past_due'  => SubStatus.pastDue,
      'cancelled' => SubStatus.cancelled,
      'expired'   => SubStatus.expired,
      _           => SubStatus.expired,
    };
  }

  String get dbValue => switch (this) {
    SubStatus.pastDue => 'past_due',
    _                 => name,
  };

  String get label => switch (this) {
    SubStatus.trialing  => 'Trialing',
    SubStatus.active    => 'Active',
    SubStatus.pastDue   => 'Past Due',
    SubStatus.cancelled => 'Cancelled',
    SubStatus.expired   => 'Expired',
  };

  bool get isActive => this == SubStatus.active || this == SubStatus.trialing;
}

enum BillingCycle {
  monthly,
  annual;

  static BillingCycle fromString(String? value) {
    return value == 'annual' ? BillingCycle.annual : BillingCycle.monthly;
  }

  String get dbValue => name;

  String get label => switch (this) {
    BillingCycle.monthly => 'Monthly',
    BillingCycle.annual  => 'Annual',
  };
}

enum OrgType {
  school,
  ngo,
  employer,
  government,
  community;

  static OrgType fromString(String? value) {
    return switch (value) {
      'school'     => OrgType.school,
      'ngo'        => OrgType.ngo,
      'employer'   => OrgType.employer,
      'government' => OrgType.government,
      'community'  => OrgType.community,
      _            => OrgType.school,
    };
  }

  String get dbValue => name;

  String get label => switch (this) {
    OrgType.school      => 'School',
    OrgType.ngo         => 'NGO',
    OrgType.employer    => 'Employer',
    OrgType.government  => 'Government',
    OrgType.community   => 'Community',
  };
}

enum MemberRole {
  admin,
  member;

  static MemberRole fromString(String? value) {
    return value == 'admin' ? MemberRole.admin : MemberRole.member;
  }

  String get dbValue => name;
  String get label   => name[0].toUpperCase() + name.substring(1);
}

enum MemberStatus {
  pending,
  active,
  removed;

  static MemberStatus fromString(String? value) {
    return switch (value) {
      'pending' => MemberStatus.pending,
      'active'  => MemberStatus.active,
      'removed' => MemberStatus.removed,
      _         => MemberStatus.pending,
    };
  }

  String get dbValue => name;

  String get label => switch (this) {
    MemberStatus.pending => 'Pending',
    MemberStatus.active  => 'Active',
    MemberStatus.removed => 'Removed',
  };
}

enum GrantStatus {
  active,
  expired,
  revoked;

  static GrantStatus fromString(String? value) {
    return switch (value) {
      'active'  => GrantStatus.active,
      'expired' => GrantStatus.expired,
      'revoked' => GrantStatus.revoked,
      _         => GrantStatus.active,
    };
  }

  String get dbValue => name;

  String get label => switch (this) {
    GrantStatus.active  => 'Active',
    GrantStatus.expired => 'Expired',
    GrantStatus.revoked => 'Revoked',
  };
}
