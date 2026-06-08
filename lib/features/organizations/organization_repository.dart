import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:milpress_dashboard/features/auth/admin_activity_repository.dart';
import 'package:milpress_dashboard/features/auth/activity_actions.dart';
import 'package:milpress_dashboard/features/subscriptions/subscription_enums.dart';

import 'organization_models.dart';
import 'sponsored_grant_model.dart';

// =============================================================================
// OrganizationRepository
// =============================================================================
class OrganizationRepository {
  final SupabaseClient _client;
  OrganizationRepository(this._client);

  static const String orgsTable   = 'organizations';
  static const String membersTable = 'org_members';
  static const String grantsTable  = 'sponsored_grants';
  static const String orgSubsTable = 'org_subscriptions';

  // ---------------------------------------------------------------------------
  // READ — organisations list
  // ---------------------------------------------------------------------------
  Future<List<Organization>> fetchOrganizations({
    OrganizationsQuery? query,
  }) async {
    // Join owner profile for display email
    dynamic qb = _client.from(orgsTable).select(
      '*, profiles!organizations_owner_profile_fkey(email)',
    );

    if (query?.plan != null) {
      qb = qb.eq('plan', query!.plan!.dbValue);
    }
    if (query?.type != null) {
      qb = qb.eq('type', query!.type!.dbValue);
    }
    if (query?.status != null) {
      qb = qb.eq('status', query!.status!.dbValue);
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

    final List data = await qb;
    final results = data
        .map((e) => Organization.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Client-side search on name / owner email
    final q = query?.search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      return results.where((o) {
        return o.name.toLowerCase().contains(q) ||
               (o.ownerEmail?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // READ — single organisation
  // ---------------------------------------------------------------------------
  Future<Organization?> fetchById(String id) async {
    final data = await _client
        .from(orgsTable)
        .select('*, profiles!organizations_owner_profile_fkey(email)')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Organization.fromMap(Map<String, dynamic>.from(data));
  }

  // ---------------------------------------------------------------------------
  // CREATE — organisation (also creates the org_subscription billing row)
  // ---------------------------------------------------------------------------
  Future<Organization> createOrganization(
    OrgCreate input, {
    BillingCycle billingCycle = BillingCycle.monthly,
  }) async {
    // 1. Insert the org
    final List orgData = await _client
        .from(orgsTable)
        .insert(input.toInsertMap())
        .select('*, profiles!organizations_owner_profile_fkey(email)');
    final org = Organization.fromMap(
      Map<String, dynamic>.from(orgData.first as Map),
    );

    // 2. Insert the billing record (skip for enterprise — billed manually)
    if (org.plan != OrgPlan.enterprise) {
      await _client.from(orgSubsTable).insert({
        'org_id': org.id,
        'plan': org.plan.dbValue,
        'status': SubStatus.active.dbValue,
        'billing_cycle': billingCycle.dbValue,
        'amount_usd': billingCycle == BillingCycle.annual
            ? (org.plan.monthlyPrice! * 12 * 0.85) // 15% annual discount
            : org.plan.monthlyPrice,
        'current_period_start': DateTime.now().toIso8601String(),
        'current_period_end': billingCycle == BillingCycle.annual
            ? DateTime.now().add(const Duration(days: 365)).toIso8601String()
            : DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      });
    }

    return org;
  }

  // ---------------------------------------------------------------------------
  // UPDATE — organisation details
  // ---------------------------------------------------------------------------
  Future<void> updateOrganization(String id, OrgUpdate update) async {
    await _client
        .from(orgsTable)
        .update(update.toUpdateMap())
        .eq('id', id);
  }

  // ---------------------------------------------------------------------------
  // READ — org members
  // ---------------------------------------------------------------------------
  Future<List<OrgMember>> fetchMembers(String orgId) async {
    final List data = await _client
        .from(membersTable)
        .select('*, profiles!org_members_profile_fkey(first_name, last_name, email)')
        .eq('org_id', orgId)
        .order('invited_at', ascending: false);

    return data
        .map((e) => OrgMember.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // CREATE — invite one or more members (bulk insert, ignores duplicates)
  // ---------------------------------------------------------------------------
  Future<List<OrgMember>> inviteMembers(
    List<OrgMemberInvite> invites,
  ) async {
    if (invites.isEmpty) return [];

    final rows = invites.map((i) => i.toInsertMap()).toList();
    // upsert: if the email is already in this org, do nothing
    final List data = await _client
        .from(membersTable)
        .upsert(rows, onConflict: 'org_id,invite_email')
        .select('*, profiles!org_members_profile_fkey(first_name, last_name, email)');

    return data
        .map((e) => OrgMember.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // UPDATE — change a member's role or remove them
  // ---------------------------------------------------------------------------
  Future<void> updateMember(
    String memberId, {
    MemberRole? role,
    MemberStatus? status,
  }) async {
    final payload = <String, dynamic>{};
    if (role != null)   payload['role']   = role.dbValue;
    if (status != null) {
      payload['status'] = status.dbValue;
      if (status == MemberStatus.removed) {
        payload['removed_at'] = DateTime.now().toIso8601String();
      }
    }
    if (payload.isEmpty) return;

    await _client.from(membersTable).update(payload).eq('id', memberId);
  }

  // ---------------------------------------------------------------------------
  // READ — sponsored grants for an org
  // ---------------------------------------------------------------------------
  Future<List<SponsoredGrant>> fetchSponsoredGrants(GrantsQuery query) async {
    dynamic qb = _client
        .from(grantsTable)
        .select('*, organizations(name), profiles!sponsored_grants_profile_fkey(first_name, last_name)')
        .eq('sponsor_org_id', query.orgId);

    if (query.status != null) {
      qb = qb.eq('status', query.status!.dbValue);
    }

    qb = qb.order('created_at', ascending: false).limit(query.limit);

    if (query.offset > 0) {
      qb = qb.range(query.offset, query.offset + query.limit - 1);
    }

    final List data = await qb;
    final results = data
        .map((e) => SponsoredGrant.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    // Client-side search on email or name
    final q = query.search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      return results.where((g) {
        return g.inviteEmail.toLowerCase().contains(q) ||
               g.learnerDisplayName.toLowerCase().contains(q);
      }).toList();
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // CREATE — bulk-create sponsored grants (skips duplicate emails per org)
  // ---------------------------------------------------------------------------
  Future<int> createSponsoredGrants(List<SponsoredGrantCreate> grants) async {
    if (grants.isEmpty) return 0;

    final rows = grants.map((g) => g.toInsertMap()).toList();
    final List data = await _client
        .from(grantsTable)
        .upsert(rows, onConflict: 'sponsor_org_id,invite_email')
        .select('id');

    return data.length;
  }

  // ---------------------------------------------------------------------------
  // UPDATE — revoke a single sponsored grant
  // ---------------------------------------------------------------------------
  Future<void> revokeGrant(String grantId, SponsoredGrantRevoke revoke) async {
    await _client
        .from(grantsTable)
        .update(revoke.toUpdateMap())
        .eq('id', grantId);
  }

  // ---------------------------------------------------------------------------
  // KPIs — summary numbers
  // ---------------------------------------------------------------------------
  Future<OrganizationKpis> fetchKpis() async {
    final List orgs = await _client
        .from(orgsTable)
        .select('id, plan, seats_used, seat_limit, status');

    final active = orgs.where((o) => o['status'] == SubStatus.active.dbValue);

    int totalOrgs      = active.length;
    int totalSeats     = 0;
    int usedSeats      = 0;
    int starterCount   = 0;
    int growthCount    = 0;
    int enterpriseCount = 0;

    for (final o in active) {
      final plan = OrgPlan.fromString(o['plan'] as String?);
      usedSeats  += (o['seats_used'] as int? ?? 0);
      totalSeats += (o['seat_limit'] as int? ?? 0);
      switch (plan) {
        case OrgPlan.starter:    starterCount++;    break;
        case OrgPlan.growth:     growthCount++;     break;
        case OrgPlan.enterprise: enterpriseCount++; break;
      }
    }

    final List grants = await _client
        .from(grantsTable)
        .select('id')
        .eq('status', GrantStatus.active.dbValue);

    return OrganizationKpis(
      totalActiveOrgs: totalOrgs,
      starterCount: starterCount,
      growthCount: growthCount,
      enterpriseCount: enterpriseCount,
      totalSeats: totalSeats,
      usedSeats: usedSeats,
      totalActiveGrants: grants.length,
    );
  }
}

// =============================================================================
// OrganizationKpis model
// =============================================================================
class OrganizationKpis {
  final int totalActiveOrgs;
  final int starterCount;
  final int growthCount;
  final int enterpriseCount;
  final int totalSeats;
  final int usedSeats;
  final int totalActiveGrants;

  const OrganizationKpis({
    required this.totalActiveOrgs,
    required this.starterCount,
    required this.growthCount,
    required this.enterpriseCount,
    required this.totalSeats,
    required this.usedSeats,
    required this.totalActiveGrants,
  });

  double get overallSeatUtilisation =>
      totalSeats == 0 ? 0 : usedSeats / totalSeats;

  static const empty = OrganizationKpis(
    totalActiveOrgs: 0,
    starterCount: 0,
    growthCount: 0,
    enterpriseCount: 0,
    totalSeats: 0,
    usedSeats: 0,
    totalActiveGrants: 0,
  );
}

// =============================================================================
// Providers — repository singleton
// =============================================================================
final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepository(Supabase.instance.client);
});

// Read providers
final organizationsListProvider = FutureProvider.family<
    List<Organization>, OrganizationsQuery?>((ref, query) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.fetchOrganizations(query: query);
});

final organizationByIdProvider =
    FutureProvider.family<Organization?, String>((ref, id) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.fetchById(id);
});

final orgMembersProvider =
    FutureProvider.family<List<OrgMember>, String>((ref, orgId) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.fetchMembers(orgId);
});

final orgSponsoredGrantsProvider =
    FutureProvider.family<List<SponsoredGrant>, GrantsQuery>((ref, query) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.fetchSponsoredGrants(query);
});

final organizationKpisProvider =
    FutureProvider<OrganizationKpis>((ref) async {
  final repo = ref.watch(organizationRepositoryProvider);
  return repo.fetchKpis();
});

// =============================================================================
// Mutation controllers
// =============================================================================

// Create organisation
class CreateOrganizationController
    extends StateNotifier<AsyncValue<Organization?>> {
  final OrganizationRepository _repo;
  final Ref _ref;
  CreateOrganizationController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<Organization?> create(
    OrgCreate data, {
    BillingCycle billingCycle = BillingCycle.monthly,
  }) async {
    state = const AsyncLoading();
    try {
      final org = await _repo.createOrganization(data, billingCycle: billingCycle);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.orgCreated,
        targetType: 'organization',
        targetId: org.id,
        details: {
          'name': org.name,
          'plan': org.plan.dbValue,
          'type': org.type.dbValue,
          'seat_limit': org.seatLimit,
        },
      );
      state = AsyncData(org);
      return org;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createOrganizationProvider = StateNotifierProvider<
    CreateOrganizationController, AsyncValue<Organization?>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return CreateOrganizationController(repo, ref);
});

// Update organisation
class UpdateOrganizationController extends StateNotifier<AsyncValue<void>> {
  final OrganizationRepository _repo;
  final Ref _ref;
  UpdateOrganizationController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> update(String id, OrgUpdate data, Organization old) async {
    state = const AsyncLoading();
    try {
      await _repo.updateOrganization(id, data);
      final changes = <String, dynamic>{};
      if (data.name   != null) changes['name_new']   = data.name;
      if (data.plan   != null) changes['plan_new']   = data.plan!.dbValue;
      if (data.status != null) changes['status_new'] = data.status!.dbValue;
      await _ref.read(adminActivityRepositoryProvider).log(
        action: data.status == SubStatus.active
            ? ActivityActions.orgUpdated
            : ActivityActions.orgSuspended,
        targetType: 'organization',
        targetId: id,
        details: changes,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final updateOrganizationProvider = StateNotifierProvider<
    UpdateOrganizationController, AsyncValue<void>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return UpdateOrganizationController(repo, ref);
});

// Invite members
class InviteMembersController extends StateNotifier<AsyncValue<List<OrgMember>>> {
  final OrganizationRepository _repo;
  final Ref _ref;
  InviteMembersController(this._repo, this._ref)
      : super(const AsyncData([]));

  Future<List<OrgMember>> invite(
    String orgId,
    List<String> emails, {
    MemberRole role = MemberRole.member,
  }) async {
    state = const AsyncLoading();
    try {
      final invites = emails
          .map((e) => OrgMemberInvite(
                orgId: orgId,
                inviteEmail: e.trim().toLowerCase(),
                role: role,
              ))
          .toList();
      final members = await _repo.inviteMembers(invites);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.orgMemberInvited,
        targetType: 'organization',
        targetId: orgId,
        details: {'emails': emails, 'count': emails.length, 'role': role.dbValue},
      );
      state = AsyncData(members);
      return members;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final inviteMembersProvider = StateNotifierProvider<
    InviteMembersController, AsyncValue<List<OrgMember>>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return InviteMembersController(repo, ref);
});

// Remove member
class RemoveMemberController extends StateNotifier<AsyncValue<void>> {
  final OrganizationRepository _repo;
  final Ref _ref;
  RemoveMemberController(this._repo, this._ref)
      : super(const AsyncData(null));

  Future<void> remove(OrgMember member) async {
    state = const AsyncLoading();
    try {
      await _repo.updateMember(
        member.id,
        status: MemberStatus.removed,
      );
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.orgMemberRemoved,
        targetType: 'org_member',
        targetId: member.id,
        details: {
          'org_id': member.orgId,
          'email': member.inviteEmail,
        },
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final removeMemberProvider = StateNotifierProvider<
    RemoveMemberController, AsyncValue<void>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return RemoveMemberController(repo, ref);
});

// Create sponsored grants (bulk)
class CreateGrantsController extends StateNotifier<AsyncValue<int>> {
  final OrganizationRepository _repo;
  final Ref _ref;
  CreateGrantsController(this._repo, this._ref) : super(const AsyncData(0));

  Future<int> createBulk(
    String orgId,
    List<String> emails, {
    DateTime? validUntil,
  }) async {
    state = const AsyncLoading();
    try {
      final grants = emails
          .map((e) => SponsoredGrantCreate(
                sponsorOrgId: orgId,
                inviteEmail: e.trim().toLowerCase(),
                validUntil: validUntil,
              ))
          .toList();
      final count = await _repo.createSponsoredGrants(grants);
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.sponsoredGrantsCreated,
        targetType: 'organization',
        targetId: orgId,
        details: {
          'count': count,
          'valid_until': validUntil?.toIso8601String(),
        },
      );
      state = AsyncData(count);
      return count;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createGrantsProvider =
    StateNotifierProvider<CreateGrantsController, AsyncValue<int>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return CreateGrantsController(repo, ref);
});

// Revoke a single grant
class RevokeGrantController extends StateNotifier<AsyncValue<void>> {
  final OrganizationRepository _repo;
  final Ref _ref;
  RevokeGrantController(this._repo, this._ref) : super(const AsyncData(null));

  Future<void> revoke(SponsoredGrant grant, String reason) async {
    state = const AsyncLoading();
    try {
      await _repo.revokeGrant(grant.id, SponsoredGrantRevoke(reason: reason));
      await _ref.read(adminActivityRepositoryProvider).log(
        action: ActivityActions.sponsoredGrantRevoked,
        targetType: 'sponsored_grant',
        targetId: grant.id,
        details: {
          'org_id': grant.sponsorOrgId,
          'email': grant.inviteEmail,
          'reason': reason,
        },
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final revokeGrantProvider =
    StateNotifierProvider<RevokeGrantController, AsyncValue<void>>((ref) {
  final repo = ref.watch(organizationRepositoryProvider);
  return RevokeGrantController(repo, ref);
});
