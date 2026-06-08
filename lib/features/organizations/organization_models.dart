import '../subscriptions/subscription_enums.dart';

// =============================================================================
// Organization  — mirrors the `organizations` table.
// =============================================================================
class Organization {
  final String id;
  final String name;
  final OrgType type;
  final OrgPlan plan;
  final int? seatLimit;      // null = unlimited (enterprise)
  final int seatsUsed;
  final String? ownerId;
  final String? ownerEmail;  // populated via JOIN with profiles
  final Map<String, dynamic>? customBranding;
  final SubStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Organization({
    required this.id,
    required this.name,
    required this.type,
    required this.plan,
    this.seatLimit,
    this.seatsUsed = 0,
    this.ownerId,
    this.ownerEmail,
    this.customBranding,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  int get seatsAvailable => seatLimit == null ? 9999 : seatLimit! - seatsUsed;
  bool get atSeatLimit   => seatLimit != null && seatsUsed >= seatLimit!;

  /// Seat utilisation 0.0 – 1.0 (always 0 for enterprise)
  double get seatUtilisation =>
      seatLimit == null || seatLimit == 0 ? 0 : seatsUsed / seatLimit!;

  factory Organization.fromMap(Map<String, dynamic> map) {
    final ownerProfile = map['profiles'] as Map<String, dynamic>?;

    return Organization(
      id: map['id'] as String,
      name: map['name'] as String,
      type: OrgType.fromString(map['type'] as String?),
      plan: OrgPlan.fromString(map['plan'] as String?),
      seatLimit: map['seat_limit'] as int?,
      seatsUsed: (map['seats_used'] as int?) ?? 0,
      ownerId: map['owner_id'] as String?,
      ownerEmail: ownerProfile?['email'] as String?,
      customBranding: map['custom_branding'] != null
          ? Map<String, dynamic>.from(map['custom_branding'] as Map)
          : null,
      status: SubStatus.fromString(map['status'] as String?),
      notes: map['notes'] as String?,
      createdAt: _toDateTime(map['created_at'])!,
      updatedAt: _toDateTime(map['updated_at'])!,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  Organization copyWith({
    String? name,
    OrgPlan? plan,
    SubStatus? status,
    int? seatsUsed,
    String? notes,
    Map<String, dynamic>? customBranding,
  }) {
    return Organization(
      id: id,
      name: name ?? this.name,
      type: type,
      plan: plan ?? this.plan,
      seatLimit: plan != null ? (plan.seatLimit) : seatLimit,
      seatsUsed: seatsUsed ?? this.seatsUsed,
      ownerId: ownerId,
      ownerEmail: ownerEmail,
      customBranding: customBranding ?? this.customBranding,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// =============================================================================
// OrgCreate — data needed to create a new organisation from the dashboard.
// =============================================================================
class OrgCreate {
  final String name;
  final OrgType type;
  final OrgPlan plan;
  final String? ownerId;
  final BillingCycle billingCycle;
  final String? notes;

  OrgCreate({
    required this.name,
    required this.type,
    required this.plan,
    this.ownerId,
    this.billingCycle = BillingCycle.monthly,
    this.notes,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'type': type.dbValue,
      'plan': plan.dbValue,
      'seat_limit': plan.seatLimit,
      'seats_used': 0,
      if (ownerId != null) 'owner_id': ownerId,
      'status': SubStatus.active.dbValue,
      if (notes != null) 'notes': notes,
    };
  }
}

// =============================================================================
// OrgUpdate — fields the dashboard can change on an existing org.
// =============================================================================
class OrgUpdate {
  final String? name;
  final OrgPlan? plan;
  final SubStatus? status;
  final String? notes;
  final String? ownerId;

  OrgUpdate({
    this.name,
    this.plan,
    this.status,
    this.notes,
    this.ownerId,
  });

  Map<String, dynamic> toUpdateMap() {
    return {
      if (name != null) 'name': name,
      if (plan != null) ...{
        'plan': plan!.dbValue,
        'seat_limit': plan!.seatLimit,
      },
      if (status != null) 'status': status!.dbValue,
      if (notes != null) 'notes': notes,
      if (ownerId != null) 'owner_id': ownerId,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

// =============================================================================
// OrgMember  — mirrors the `org_members` table.
// User info is populated via JOIN with profiles.
// =============================================================================
class OrgMember {
  final String id;
  final String orgId;
  final String? userId;          // null until invite redeemed
  final String inviteEmail;
  final String? firstName;       // from profiles join
  final String? lastName;
  final MemberRole role;
  final MemberStatus status;
  final DateTime invitedAt;
  final DateTime? joinedAt;
  final DateTime? removedAt;

  OrgMember({
    required this.id,
    required this.orgId,
    this.userId,
    required this.inviteEmail,
    this.firstName,
    this.lastName,
    required this.role,
    required this.status,
    required this.invitedAt,
    this.joinedAt,
    this.removedAt,
  });

  String get displayName {
    final parts = [firstName, lastName]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? inviteEmail : parts.join(' ');
  }

  factory OrgMember.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;

    return OrgMember(
      id: map['id'] as String,
      orgId: map['org_id'] as String,
      userId: map['user_id'] as String?,
      inviteEmail: map['invite_email'] as String,
      firstName: profile?['first_name'] as String?,
      lastName: profile?['last_name'] as String?,
      role: MemberRole.fromString(map['role'] as String?),
      status: MemberStatus.fromString(map['status'] as String?),
      invitedAt: _toDateTime(map['invited_at'])!,
      joinedAt: _toDateTime(map['joined_at']),
      removedAt: _toDateTime(map['removed_at']),
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

// =============================================================================
// OrgMemberInvite — used when inviting one or more members to an org.
// =============================================================================
class OrgMemberInvite {
  final String orgId;
  final String inviteEmail;
  final MemberRole role;

  OrgMemberInvite({
    required this.orgId,
    required this.inviteEmail,
    this.role = MemberRole.member,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'org_id': orgId,
      'invite_email': inviteEmail,
      'role': role.dbValue,
      'status': MemberStatus.pending.dbValue,
    };
  }
}

// =============================================================================
// OrganizationsQuery — filter / sort / paginate the org list.
// =============================================================================
class OrganizationsQuery {
  final String? search;
  final OrgPlan? plan;
  final OrgType? type;
  final SubStatus? status;
  final int limit;
  final int offset;
  final String orderBy;
  final bool ascending;

  const OrganizationsQuery({
    this.search,
    this.plan,
    this.type,
    this.status,
    this.limit = 50,
    this.offset = 0,
    this.orderBy = 'created_at',
    this.ascending = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationsQuery &&
          search == other.search &&
          plan == other.plan &&
          type == other.type &&
          status == other.status &&
          limit == other.limit &&
          offset == other.offset &&
          orderBy == other.orderBy &&
          ascending == other.ascending;

  @override
  int get hashCode => Object.hash(
      search, plan, type, status, limit, offset, orderBy, ascending);
}
