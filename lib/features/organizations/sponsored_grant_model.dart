import '../subscriptions/subscription_enums.dart';

// =============================================================================
// SponsoredGrant  — mirrors the `sponsored_grants` table.
// Sponsor org info populated via JOIN with organizations.
// =============================================================================
class SponsoredGrant {
  final String id;
  final String sponsorOrgId;
  final String? sponsorOrgName;    // from organizations join
  final String? learnerId;         // null until invite is redeemed
  final String inviteEmail;
  final String? learnerFirstName;  // from profiles join (once redeemed)
  final String? learnerLastName;
  final PlanType grantType;
  final GrantStatus status;
  final DateTime validFrom;
  final DateTime? validUntil;      // null = open-ended
  final DateTime? redeemedAt;
  final DateTime? revokedAt;
  final String? revokeReason;
  final DateTime createdAt;

  SponsoredGrant({
    required this.id,
    required this.sponsorOrgId,
    this.sponsorOrgName,
    this.learnerId,
    required this.inviteEmail,
    this.learnerFirstName,
    this.learnerLastName,
    required this.grantType,
    required this.status,
    required this.validFrom,
    this.validUntil,
    this.redeemedAt,
    this.revokedAt,
    this.revokeReason,
    required this.createdAt,
  });

  bool get isRedeemed => learnerId != null && redeemedAt != null;
  bool get isExpired  => validUntil != null && validUntil!.isBefore(DateTime.now());

  String get learnerDisplayName {
    final parts = [learnerFirstName, learnerLastName]
        .where((e) => (e ?? '').trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? inviteEmail : parts.join(' ');
  }

  factory SponsoredGrant.fromMap(Map<String, dynamic> map) {
    final org     = map['organizations'] as Map<String, dynamic>?;
    final profile = map['profiles'] as Map<String, dynamic>?;

    return SponsoredGrant(
      id: map['id'] as String,
      sponsorOrgId: map['sponsor_org_id'] as String,
      sponsorOrgName: org?['name'] as String?,
      learnerId: map['learner_id'] as String?,
      inviteEmail: map['invite_email'] as String,
      learnerFirstName: profile?['first_name'] as String?,
      learnerLastName: profile?['last_name'] as String?,
      grantType: PlanType.fromString(map['grant_type'] as String?),
      status: GrantStatus.fromString(map['status'] as String?),
      validFrom: _toDateTime(map['valid_from'])!,
      validUntil: _toDateTime(map['valid_until']),
      redeemedAt: _toDateTime(map['redeemed_at']),
      revokedAt: _toDateTime(map['revoked_at']),
      revokeReason: map['revoke_reason'] as String?,
      createdAt: _toDateTime(map['created_at'])!,
    );
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

// =============================================================================
// SponsoredGrantCreate — used when an admin bulk-creates grants for an org.
// One instance per email address.
// =============================================================================
class SponsoredGrantCreate {
  final String sponsorOrgId;
  final String inviteEmail;
  final DateTime? validUntil;        // null = open-ended
  final PlanType grantType;

  SponsoredGrantCreate({
    required this.sponsorOrgId,
    required this.inviteEmail,
    this.validUntil,
    this.grantType = PlanType.premium,
  });

  Map<String, dynamic> toInsertMap() {
    return {
      'sponsor_org_id': sponsorOrgId,
      'invite_email': inviteEmail.trim().toLowerCase(),
      'grant_type': grantType.dbValue,
      'status': GrantStatus.active.dbValue,
      'valid_from': DateTime.now().toIso8601String(),
      if (validUntil != null) 'valid_until': validUntil!.toIso8601String(),
    };
  }
}

// =============================================================================
// SponsoredGrantRevoke — payload when revoking a single grant.
// =============================================================================
class SponsoredGrantRevoke {
  final String reason;

  SponsoredGrantRevoke({required this.reason});

  Map<String, dynamic> toUpdateMap() {
    return {
      'status': GrantStatus.revoked.dbValue,
      'revoked_at': DateTime.now().toIso8601String(),
      'revoke_reason': reason,
    };
  }
}

// =============================================================================
// GrantsQuery — filter / sort / paginate the grants tab inside an org.
// =============================================================================
class GrantsQuery {
  final String orgId;
  final String? search;           // email or name
  final GrantStatus? status;
  final int limit;
  final int offset;

  const GrantsQuery({
    required this.orgId,
    this.search,
    this.status,
    this.limit = 100,
    this.offset = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GrantsQuery &&
          orgId == other.orgId &&
          search == other.search &&
          status == other.status &&
          limit == other.limit &&
          offset == other.offset;

  @override
  int get hashCode => Object.hash(orgId, search, status, limit, offset);
}
