import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../organizations/organization_models.dart';
import '../../organizations/organization_repository.dart';
import '../../subscriptions/subscription_enums.dart';

// =============================================================================
// OrgSession — holds the resolved org context after org-portal login.
// =============================================================================
class OrgSession {
  final String userId;
  final String orgId;
  final MemberRole role;
  final Organization org;

  const OrgSession({
    required this.userId,
    required this.orgId,
    required this.role,
    required this.org,
  });
}

// =============================================================================
// OrgSessionNotifier — manages the lifecycle of the org session.
// Call [resolve] after a successful Supabase login to load the session.
// Call [clear] on logout.
// =============================================================================
class OrgSessionNotifier extends StateNotifier<AsyncValue<OrgSession?>> {
  final OrganizationRepository _orgRepo;

  OrgSessionNotifier(this._orgRepo) : super(const AsyncData(null));

  /// Resolves the org context for the currently authenticated Supabase user.
  /// Returns the session on success, null if the user is not an org admin.
  /// Throws if an unexpected error occurs.
  Future<OrgSession?> resolve() async {
    state = const AsyncLoading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        state = const AsyncData(null);
        return null;
      }

      // Find an org where this user is an active admin member
      final List memberRows = await Supabase.instance.client
          .from('org_members')
          .select('org_id, role')
          .eq('user_id', user.id)
          .eq('status', MemberStatus.active.dbValue)
          .eq('role', MemberRole.admin.dbValue)
          .limit(1);

      // Also check if they're the owner of any org
      String? orgId;
      MemberRole role = MemberRole.admin;

      if (memberRows.isNotEmpty) {
        orgId = memberRows.first['org_id'] as String;
        role = MemberRole.fromString(memberRows.first['role'] as String?);
      } else {
        // Check owner_id
        final List ownerRows = await Supabase.instance.client
            .from('organizations')
            .select('id')
            .eq('owner_id', user.id)
            .limit(1);

        if (ownerRows.isNotEmpty) {
          orgId = ownerRows.first['id'] as String;
          role = MemberRole.admin;
        }
      }

      if (orgId == null) {
        state = const AsyncData(null);
        return null;
      }

      final org = await _orgRepo.fetchById(orgId);
      if (org == null) {
        state = const AsyncData(null);
        return null;
      }

      // Check org is active
      if (!org.status.isActive) {
        state = AsyncError(
          OrgPortalError.subscriptionInactive,
          StackTrace.current,
        );
        return null;
      }

      final session = OrgSession(
        userId: user.id,
        orgId: orgId,
        role: role,
        org: org,
      );
      state = AsyncData(session);
      return session;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> refreshOrg() async {
    final current = state.valueOrNull;
    if (current == null) return;
    final org = await _orgRepo.fetchById(current.orgId);
    if (org != null) {
      state = AsyncData(OrgSession(
        userId: current.userId,
        orgId: current.orgId,
        role: current.role,
        org: org,
      ));
    }
  }

  void clear() {
    state = const AsyncData(null);
  }
}

// =============================================================================
// Typed errors for the org portal auth flow.
// =============================================================================
enum OrgPortalError {
  notAnOrgAdmin,
  subscriptionInactive,
  unknownError;

  String get message => switch (this) {
    OrgPortalError.notAnOrgAdmin =>
      'No organization admin account found for this email.',
    OrgPortalError.subscriptionInactive =>
      'Your organization\'s subscription is inactive. Please contact support.',
    OrgPortalError.unknownError =>
      'An unexpected error occurred. Please try again.',
  };
}

// =============================================================================
// Providers
// =============================================================================

final orgSessionProvider = StateNotifierProvider<OrgSessionNotifier, AsyncValue<OrgSession?>>(
  (ref) {
    final repo = ref.watch(organizationRepositoryProvider);
    return OrgSessionNotifier(repo);
  },
);

/// Convenience read — returns the session synchronously or null.
final currentOrgSessionProvider = Provider<OrgSession?>((ref) {
  return ref.watch(orgSessionProvider).valueOrNull;
});
