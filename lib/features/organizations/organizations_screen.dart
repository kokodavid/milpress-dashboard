import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../utils/app_colors.dart';
import '../../utils/initials.dart';
import '../../widgets/search_input.dart';
import '../../widgets/app_text_form_field.dart';
import '../../widgets/app_button.dart';
import '../subscriptions/subscription_enums.dart';
import '../subscriptions/subscriptions_screen.dart' show SubStatusBadge;
import 'organization_models.dart';
import 'organization_repository.dart';
import 'sponsored_grant_model.dart';

// Local UI state
final _selectedOrgIdProvider  = StateProvider<String?>((ref) => null);
final _orgSearchProvider      = StateProvider<String>((ref) => '');
final _orgPlanFilterProvider  = StateProvider<OrgPlan?>((ref) => null);

class OrganizationsScreen extends ConsumerWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search    = ref.watch(_orgSearchProvider);
    final planFilter = ref.watch(_orgPlanFilterProvider);
    final query     = OrganizationsQuery(search: search, plan: planFilter);
    final orgsAsync = ref.watch(organizationsListProvider(query));
    final selectedId = ref.watch(_selectedOrgIdProvider);

    Future<void> refresh() async {
      ref.invalidate(organizationsListProvider(query));
      ref.invalidate(organizationKpisProvider);
      if (selectedId != null) ref.invalidate(organizationByIdProvider(selectedId));
      await ref.read(organizationsListProvider(query).future);
    }

    return Scaffold(
      body: Row(
        children: [
          // ── Left panel ──────────────────────────────────────────────────
          Expanded(
            flex: 30,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.faintGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  // KPI mini-strip
                  _OrgKpiStrip(),
                  const Divider(height: 1),
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchInput(
                            hintText: 'Search organisations…',
                            initialValue: search,
                            onChanged: (v) =>
                                ref.read(_orgSearchProvider.notifier).state = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _CreateOrgButton(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OrgPlanFilterChips(),
                  const SizedBox(height: 4),
                  // List
                  Expanded(
                    child: orgsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (orgs) => _OrgList(
                        orgs: orgs,
                        selectedId: selectedId,
                        onRefresh: refresh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right panel ─────────────────────────────────────────────────
          Expanded(
            flex: 70,
            child: selectedId == null
                ? const _EmptyOrgDetail()
                : _OrgDetail(orgId: selectedId),
          ),
        ],
      ),
    );
  }
}

// ── Org KPI strip ─────────────────────────────────────────────────────────────
class _OrgKpiStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(organizationKpisProvider);
    return kpisAsync.when(
      loading: () => const SizedBox(
          height: 72, child: Center(child: LinearProgressIndicator())),
      error: (_, __) => const SizedBox(height: 72),
      data: (k) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _OrgKpiCell('Orgs', k.totalActiveOrgs.toString(),
                AppColors.primaryColor),
            _OrgKpiCell(
                'Seats',
                '${k.usedSeats}/${k.totalSeats}',
                const Color(0xFF4F46E5)),
            _OrgKpiCell('Grants', k.totalActiveGrants.toString(),
                const Color(0xFF0891B2)),
          ],
        ),
      ),
    );
  }
}

class _OrgKpiCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _OrgKpiCell(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// ── Plan filter chips ─────────────────────────────────────────────────────────
class _OrgPlanFilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(_orgPlanFilterProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: OrgPlan.values
            .map((plan) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(plan.label,
                        style: const TextStyle(fontSize: 11)),
                    selected: current == plan,
                    onSelected: (on) => ref
                        .read(_orgPlanFilterProvider.notifier)
                        .state = on ? plan : null,
                    selectedColor:
                        AppColors.primaryColor.withOpacity(0.15),
                    checkmarkColor: AppColors.primaryColor,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Create org button ─────────────────────────────────────────────────────────
class _CreateOrgButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Create organisation',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showCreateOrgDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              const Icon(Icons.add, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  void _showCreateOrgDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => const _CreateOrgDialog(),
    );
  }
}

// ── Org list ──────────────────────────────────────────────────────────────────
class _OrgList extends ConsumerWidget {
  final List<Organization> orgs;
  final String? selectedId;
  final Future<void> Function() onRefresh;
  const _OrgList(
      {required this.orgs,
      required this.selectedId,
      required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orgs.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.business_outlined, size: 36, color: Colors.grey),
          SizedBox(height: 12),
          Text('No organisations found'),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: orgs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, i) {
          final org = orgs[i];
          final isSelected = selectedId == org.id;
          final util = org.seatUtilisation;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1))
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () =>
                  ref.read(_selectedOrgIdProvider.notifier).state = org.id,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            org.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _OrgPlanBadge(plan: org.plan),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${org.type.label} · ${org.seatsUsed}${org.seatLimit != null ? '/${org.seatLimit}' : ''} seats',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey),
                    ),
                    // Seat utilisation bar (hidden for enterprise)
                    if (org.seatLimit != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: util.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          color: util > 0.9
                              ? AppColors.errorColor
                              : util > 0.7
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.successColor,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Org detail (right panel with tabs) ───────────────────────────────────────
class _OrgDetail extends ConsumerWidget {
  final String orgId;
  const _OrgDetail({required this.orgId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgAsync = ref.watch(organizationByIdProvider(orgId));

    return orgAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (org) {
        if (org == null) return const Center(child: Text('Not found'));
        return DefaultTabController(
          length: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          AppColors.primaryColor.withOpacity(0.12),
                      child: Text(
                        computeInitials(org.name),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(org.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            '${org.type.label} · ${org.ownerEmail ?? 'No owner'}',
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    _OrgPlanBadge(plan: org.plan, large: true),
                    const SizedBox(width: 8),
                    SubStatusBadge(status: org.status, large: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const TabBar(
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.grey,
                indicatorColor: AppColors.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 16),
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Members'),
                  Tab(text: 'Sponsored Grants'),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: TabBarView(
                  children: [
                    _OrgOverviewTab(org: org),
                    _OrgMembersTab(org: org),
                    _OrgGrantsTab(org: org),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────
class _OrgOverviewTab extends StatelessWidget {
  final Organization org;
  const _OrgOverviewTab({required this.org});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrgDetailCard(children: [
            _OrgDetailRow('Plan', org.plan.label),
            _OrgDetailRow('Type', org.type.label),
            _OrgDetailRow('Status', org.status.label),
            _OrgDetailRow(
              'Seats',
              org.seatLimit == null
                  ? '${org.seatsUsed} (unlimited)'
                  : '${org.seatsUsed} / ${org.seatLimit}',
            ),
            if (org.ownerEmail != null)
              _OrgDetailRow('Owner', org.ownerEmail!),
            _OrgDetailRow('Created', fmt.format(org.createdAt)),
            if (org.notes != null && org.notes!.isNotEmpty)
              _OrgDetailRow('Notes', org.notes!),
          ]),
          // Seat bar
          if (org.seatLimit != null) ...[
            const SizedBox(height: 20),
            Text('Seat Utilisation',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: org.seatUtilisation.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: org.seatUtilisation > 0.9
                    ? AppColors.errorColor
                    : org.seatUtilisation > 0.7
                        ? const Color(0xFFF59E0B)
                        : AppColors.successColor,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(org.seatUtilisation * 100).toStringAsFixed(0)}% used — ${org.seatsUsed} of ${org.seatLimit} seats',
              style: const TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Members tab ───────────────────────────────────────────────────────────────
class _OrgMembersTab extends ConsumerWidget {
  final Organization org;
  const _OrgMembersTab({required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(orgMembersProvider(org.id));

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) => Column(
        children: [
          // Invite bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('${members.length} member(s)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600])),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showInviteDialog(context, ref, org.id),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Invite members',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: members.isEmpty
                ? const Center(child: Text('No members yet'))
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: members.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final m = members[i];
                      return _MemberTile(
                        member: m,
                        onRemove: () async {
                          await ref
                              .read(removeMemberProvider.notifier)
                              .remove(m);
                          ref.invalidate(orgMembersProvider(org.id));
                          ref.invalidate(
                              organizationByIdProvider(org.id));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(
      BuildContext context, WidgetRef ref, String orgId) {
    showDialog(
      context: context,
      builder: (_) => _InviteMembersDialog(orgId: orgId),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final OrgMember member;
  final VoidCallback onRemove;
  const _MemberTile({required this.member, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusFg) = switch (member.status) {
      MemberStatus.active  => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      MemberStatus.pending => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      MemberStatus.removed => (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.copBlue.withOpacity(0.1),
            child: Text(
              computeInitials(member.displayName),
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.copBlue),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(member.inviteEmail,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Role chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: member.role == MemberRole.admin
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.role.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: member.role == MemberRole.admin
                    ? AppColors.primaryColor
                    : AppColors.grey,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Status chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(member.status.label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusFg)),
          ),
          // Remove action
          if (member.status == MemberStatus.active) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_outlined,
                  size: 16, color: AppColors.errorColor),
              tooltip: 'Remove member',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Sponsored grants tab ──────────────────────────────────────────────────────
class _OrgGrantsTab extends ConsumerWidget {
  final Organization org;
  const _OrgGrantsTab({required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = GrantsQuery(orgId: org.id);
    final grantsAsync = ref.watch(orgSponsoredGrantsProvider(query));
    final fmt = DateFormat('MMM d, yyyy');

    return grantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (grants) => Column(
        children: [
          // Action bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('${grants.length} grant(s)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600])),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () =>
                      _showCreateGrantsDialog(context, ref, org.id),
                  icon: const Icon(Icons.card_giftcard_outlined,
                      size: 16),
                  label: const Text('Sponsor learners',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: grants.isEmpty
                ? const Center(
                    child: Text('No grants issued yet'))
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: grants.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final g = grants[i];
                      final (bg, fg) = switch (g.status) {
                        GrantStatus.active  => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
                        GrantStatus.expired => (const Color(0xFFF3F4F6), const Color(0xFF374151)),
                        GrantStatus.revoked => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                      };
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(g.inviteEmail,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.darkGrey),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis),
                                  if (g.isRedeemed)
                                    Text(
                                        'Redeemed ${fmt.format(g.redeemedAt!)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey)),
                                  if (g.validUntil != null)
                                    Text(
                                        'Valid until ${fmt.format(g.validUntil!)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.grey)),
                                ],
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius:
                                      BorderRadius.circular(20)),
                              child: Text(g.status.label,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: fg)),
                            ),
                            // Revoke action
                            if (g.status == GrantStatus.active) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                    Icons.block_outlined,
                                    size: 16,
                                    color: AppColors.errorColor),
                                tooltip: 'Revoke grant',
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    _showRevokeDialog(
                                        context, ref, g, query),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateGrantsDialog(
      BuildContext context, WidgetRef ref, String orgId) {
    showDialog(
      context: context,
      builder: (_) => _CreateGrantsDialog(orgId: orgId),
    );
  }

  void _showRevokeDialog(BuildContext context, WidgetRef ref,
      SponsoredGrant grant, GrantsQuery query) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revoke Grant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Revoke access for ${grant.inviteEmail}?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(revokeGrantProvider.notifier)
                  .revoke(grant, reasonCtrl.text.trim());
              ref.invalidate(orgSponsoredGrantsProvider(query));
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}

// ── Create org dialog ─────────────────────────────────────────────────────────
class _CreateOrgDialog extends ConsumerStatefulWidget {
  const _CreateOrgDialog();
  @override
  ConsumerState<_CreateOrgDialog> createState() => _CreateOrgDialogState();
}

class _CreateOrgDialogState extends ConsumerState<_CreateOrgDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  OrgPlan _plan = OrgPlan.starter;
  OrgType _type = OrgType.school;
  BillingCycle _cycle = BillingCycle.monthly;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Organisation'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextFormField(
                controller: _nameCtrl,
                label: 'Organisation name',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              // Type dropdown
              DropdownButtonFormField<OrgType>(
                value: _type,
                decoration:
                    const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: OrgType.values
                    .map((t) => DropdownMenuItem(
                        value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              // Plan dropdown
              DropdownButtonFormField<OrgPlan>(
                value: _plan,
                decoration:
                    const InputDecoration(labelText: 'Plan', border: OutlineInputBorder()),
                items: OrgPlan.values
                    .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                            '${p.label}${p.monthlyPrice != null ? ' — \$${p.monthlyPrice}/mo' : ' — Contact us'}')))
                    .toList(),
                onChanged: (v) => setState(() => _plan = v!),
              ),
              const SizedBox(height: 12),
              // Billing cycle
              DropdownButtonFormField<BillingCycle>(
                value: _cycle,
                decoration: const InputDecoration(
                    labelText: 'Billing cycle',
                    border: OutlineInputBorder()),
                items: BillingCycle.values
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) => setState(() => _cycle = v!),
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _ownerCtrl,
                label: 'Owner user ID (optional)',
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _notesCtrl,
                label: 'Internal notes (optional)',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final input = OrgCreate(
        name: _nameCtrl.text.trim(),
        type: _type,
        plan: _plan,
        ownerId:
            _ownerCtrl.text.trim().isEmpty ? null : _ownerCtrl.text.trim(),
        billingCycle: _cycle,
        notes:
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await ref.read(createOrganizationProvider.notifier).create(
            input,
            billingCycle: _cycle,
          );
      ref.invalidate(organizationsListProvider(null));
      ref.invalidate(organizationKpisProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Invite members dialog ─────────────────────────────────────────────────────
class _InviteMembersDialog extends ConsumerStatefulWidget {
  final String orgId;
  const _InviteMembersDialog({required this.orgId});
  @override
  ConsumerState<_InviteMembersDialog> createState() =>
      _InviteMembersDialogState();
}

class _InviteMembersDialogState
    extends ConsumerState<_InviteMembersDialog> {
  final _ctrl = TextEditingController();
  MemberRole _role = MemberRole.member;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite Members'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste one email per line, or comma-separated.',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'user@email.com\nother@email.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MemberRole>(
              value: _role,
              decoration: const InputDecoration(
                  labelText: 'Role', border: OutlineInputBorder()),
              items: MemberRole.values
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Send invites'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final raw = _ctrl.text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.contains('@'))
        .toList();
    if (raw.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(inviteMembersProvider.notifier)
          .invite(widget.orgId, raw, role: _role);
      ref.invalidate(orgMembersProvider(widget.orgId));
      ref.invalidate(organizationByIdProvider(widget.orgId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Create grants dialog ──────────────────────────────────────────────────────
class _CreateGrantsDialog extends ConsumerStatefulWidget {
  final String orgId;
  const _CreateGrantsDialog({required this.orgId});
  @override
  ConsumerState<_CreateGrantsDialog> createState() =>
      _CreateGrantsDialogState();
}

class _CreateGrantsDialogState
    extends ConsumerState<_CreateGrantsDialog> {
  final _ctrl = TextEditingController();
  DateTime? _validUntil;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return AlertDialog(
      title: const Text('Sponsor Learners'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste one email per line. Each learner will receive Premium access.',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'learner@email.com\nanother@email.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _validUntil == null
                      ? 'Expires: Open-ended'
                      : 'Expires: ${fmt.format(_validUntil!)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.darkGrey),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now()
                          .add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 1460)),
                    );
                    if (date != null) {
                      setState(() => _validUntil = date);
                    }
                  },
                  child: const Text('Set expiry'),
                ),
                if (_validUntil != null)
                  TextButton(
                    onPressed: () =>
                        setState(() => _validUntil = null),
                    child: const Text('Clear'),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Sponsor'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final emails = _ctrl.text
        .split(RegExp(r'[,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.contains('@'))
        .toList();
    if (emails.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref
          .read(createGrantsProvider.notifier)
          .createBulk(widget.orgId, emails, validUntil: _validUntil);
      ref.invalidate(
          orgSponsoredGrantsProvider(GrantsQuery(orgId: widget.orgId)));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _OrgPlanBadge extends StatelessWidget {
  final OrgPlan plan;
  final bool large;
  const _OrgPlanBadge({required this.plan, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (plan) {
      OrgPlan.starter    => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      OrgPlan.growth     => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      OrgPlan.enterprise => (const Color(0xFFEDE9FE), const Color(0xFF4C1D95)),
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7, vertical: large ? 4 : 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(plan.label,
          style: TextStyle(
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }
}

class _OrgDetailCard extends StatelessWidget {
  final List<Widget> children;
  const _OrgDetailCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: children
            .asMap()
            .entries
            .map((e) => Column(children: [
                  e.value,
                  if (e.key < children.length - 1)
                    Divider(height: 1, color: AppColors.borderColor),
                ]))
            .toList(),
      ),
    );
  }
}

class _OrgDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _OrgDetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGrey)),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrgDetail extends StatelessWidget {
  const _EmptyOrgDetail();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.faintGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: const Text(
          'Select an organisation\nto view details',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 15, color: Colors.black54, height: 1.5),
        ),
      ),
    );
  }
}
