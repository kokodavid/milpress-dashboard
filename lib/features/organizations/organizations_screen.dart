// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/app_colors.dart';
import '../../utils/initials.dart';
import '../../widgets/search_input.dart';
import '../../widgets/chip_selector.dart';
import '../../widgets/app_text_form_field.dart';
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
      backgroundColor: Colors.white,
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
                        _OrgPlanBadge(plan: org.plan, label: org.planLabel),
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
                    _OrgPlanBadge(
                        plan: org.plan, label: org.planLabel, large: true),
                    const SizedBox(width: 8),
                    SubStatusBadge(status: org.status, large: true),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Open the org portal login in a new tab',
                      child: OutlinedButton.icon(
                        onPressed: () => html.window.open(
                          '${html.window.location.origin}/org-login',
                          '_blank',
                        ),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('Org Portal'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.copBlue,
                          side: const BorderSide(color: AppColors.copBlue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
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
            _OrgDetailRow('Plan', org.planLabel),
            _OrgDetailRow('Type', org.type.label),
            _OrgDetailRow('Status', org.status.label),
            _OrgDetailRow(
              'Seats',
              org.seatLimit == null
                  ? '${org.seatsUsed} (unlimited)'
                  : '${org.seatsUsed} / ${org.seatLimit}',
            ),
            _OrgOwnerRow(org: org),
            _OrgDetailRow('Created', fmt.format(org.createdAt)),
            if (org.notes != null && org.notes!.isNotEmpty)
              _OrgDetailRow('Notes', org.notes!),
          ]),
          const SizedBox(height: 16),
          _InviteAdminButton(org: org),
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
class _OrgMembersTab extends ConsumerStatefulWidget {
  final Organization org;
  const _OrgMembersTab({required this.org});

  @override
  ConsumerState<_OrgMembersTab> createState() => _OrgMembersTabState();
}

class _OrgMembersTabState extends ConsumerState<_OrgMembersTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(orgMembersProvider(widget.org.id));

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (members) {
        final query = _query.trim().toLowerCase();
        final filteredMembers = query.isEmpty
            ? members
            : members
                .where((m) =>
                    m.displayName.toLowerCase().contains(query) ||
                    m.inviteEmail.toLowerCase().contains(query))
                .toList();

        return Column(
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
                        _showInviteDialog(context, ref, widget.org.id),
                    icon: const Icon(Icons.person_add_outlined, size: 16),
                    label: const Text('Invite members',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SearchInput(
                hintText: 'Search members by name or email',
                initialValue: _query,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            const Divider(height: 1),
            // List
            Expanded(
              child: members.isEmpty
                  ? const Center(child: Text('No members yet'))
                  : filteredMembers.isEmpty
                      ? Center(
                          child: Text(
                            'No members match "${_query.trim()}"',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filteredMembers.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final m = filteredMembers[i];
                            return _MemberTile(
                              member: m,
                              onRemove: () async {
                                await ref
                                    .read(removeMemberProvider.notifier)
                                    .remove(m);
                                ref.invalidate(
                                    orgMembersProvider(widget.org.id));
                                ref.invalidate(
                                    organizationByIdProvider(widget.org.id));
                              },
                            );
                          },
                        ),
            ),
          ],
        );
      },
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

enum _OrgPlanSelection {
  starter,
  growth,
  enterprise,
  custom;

  String get label => switch (this) {
    _OrgPlanSelection.starter    => 'Starter',
    _OrgPlanSelection.growth     => 'Growth',
    _OrgPlanSelection.enterprise => 'Enterprise',
    _OrgPlanSelection.custom     => 'Custom',
  };

  OrgPlan get orgPlan => switch (this) {
    _OrgPlanSelection.starter    => OrgPlan.starter,
    _OrgPlanSelection.growth     => OrgPlan.growth,
    _OrgPlanSelection.enterprise => OrgPlan.enterprise,
    _OrgPlanSelection.custom     => OrgPlan.enterprise,
  };

  int? get includedSeats => switch (this) {
    _OrgPlanSelection.starter    => OrgPlan.starter.seatLimit,
    _OrgPlanSelection.growth     => OrgPlan.growth.seatLimit,
    _OrgPlanSelection.enterprise => null,
    _OrgPlanSelection.custom     => null,
  };

  double? get monthlyPrice => switch (this) {
    _OrgPlanSelection.starter    => OrgPlan.starter.monthlyPrice,
    _OrgPlanSelection.growth     => OrgPlan.growth.monthlyPrice,
    _OrgPlanSelection.enterprise => null,
    _OrgPlanSelection.custom     => null,
  };

  List<String> get perks => switch (this) {
    _OrgPlanSelection.starter => const [
      'Up to 30 learner seats',
      'Organisation dashboard and member invites',
      'Sponsored access grants',
    ],
    _OrgPlanSelection.growth => const [
      'Up to 150 learner seats',
      'Everything in Starter',
      'Built for multi-classroom or programme teams',
    ],
    _OrgPlanSelection.enterprise => const [
      'Unlimited seats',
      'Custom contract and billing terms',
      'Dedicated onboarding and support',
    ],
    _OrgPlanSelection.custom => const [
      'Choose the exact seat limit',
      'Price updates before the organisation is created',
      'Billed as a custom enterprise allocation',
    ],
  };
}

const double _customSeatMonthlyRateUsd = 4.67;

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
  final _customSeatsCtrl = TextEditingController(text: '200');
  _OrgPlanSelection _planSelection = _OrgPlanSelection.starter;
  OrgType _type = OrgType.school;
  BillingCycle _cycle = BillingCycle.monthly;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _notesCtrl.dispose();
    _customSeatsCtrl.dispose();
    super.dispose();
  }

  int get _customSeats => int.tryParse(_customSeatsCtrl.text.trim()) ?? 0;

  double get _customMonthlyAmount => _customSeats * _customSeatMonthlyRateUsd;

  double? get _selectedMonthlyAmount =>
      _planSelection == _OrgPlanSelection.custom
          ? _customMonthlyAmount
          : _planSelection.monthlyPrice;

  String _formatMoney(double value) {
    final formatter = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    return formatter.format(value);
  }

  String get _selectedPriceLabel {
    final monthly = _selectedMonthlyAmount;
    if (monthly == null) return 'Contact us';

    if (_cycle == BillingCycle.annual) {
      return '${_formatMoney(monthly * 12 * 0.85)}/yr';
    }

    return '${_formatMoney(monthly)}/mo';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Organisation'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextFormField(
                  controller: _nameCtrl,
                  label: 'Organisation name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                ChipSelector<OrgType>(
                  label: 'Type',
                  values: OrgType.values,
                  selected: _type,
                  labelBuilder: (t) => t.label,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 16),
                ChipSelector<_OrgPlanSelection>(
                  label: 'Plan',
                  values: _OrgPlanSelection.values,
                  selected: _planSelection,
                  labelBuilder: (p) => p.monthlyPrice != null
                      ? '${p.label} - ${_formatMoney(p.monthlyPrice!)}/mo'
                      : p.label,
                  onChanged: (v) => setState(() => _planSelection = v),
                ),
                const SizedBox(height: 12),
                if (_planSelection == _OrgPlanSelection.custom) ...[
                  TextFormField(
                    controller: _customSeatsCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Custom seats',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_planSelection != _OrgPlanSelection.custom) {
                        return null;
                      }
                      final seats = int.tryParse(v?.trim() ?? '');
                      if (seats == null || seats < 1) {
                        return 'Enter at least 1 seat';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                ],
                _SelectedPlanSummary(
                  selection: _planSelection,
                  seats: _planSelection == _OrgPlanSelection.custom
                      ? _customSeats
                      : _planSelection.includedSeats,
                  priceLabel: _selectedPriceLabel,
                  annualDiscountApplied: _cycle == BillingCycle.annual &&
                      _selectedMonthlyAmount != null,
                  customRateLabel:
                      '${_formatMoney(_customSeatMonthlyRateUsd)}/seat/mo',
                ),
                const SizedBox(height: 16),
                ChipSelector<BillingCycle>(
                  label: 'Billing cycle',
                  values: BillingCycle.values,
                  selected: _cycle,
                  labelBuilder: (c) => c.label,
                  onChanged: (v) => setState(() => _cycle = v),
                ),
                const SizedBox(height: 16),
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
        plan: _planSelection.orgPlan,
        customSeatLimit: _planSelection == _OrgPlanSelection.custom
            ? _customSeats
            : null,
        customMonthlyAmountUsd: _planSelection == _OrgPlanSelection.custom
            ? _customMonthlyAmount
            : null,
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

class _SelectedPlanSummary extends StatelessWidget {
  final _OrgPlanSelection selection;
  final int? seats;
  final String priceLabel;
  final bool annualDiscountApplied;
  final String customRateLabel;

  const _SelectedPlanSummary({
    required this.selection,
    required this.seats,
    required this.priceLabel,
    required this.annualDiscountApplied,
    required this.customRateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final seatLabel = seats == null ? 'Unlimited seats' : '$seats seats';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.faintGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selection.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Text(
                priceLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            selection == _OrgPlanSelection.custom
                ? '$seatLabel at $customRateLabel'
                : seatLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.grey),
          ),
          if (annualDiscountApplied) ...[
            const SizedBox(height: 4),
            const Text(
              'Annual billing includes the 15% discount.',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
          const SizedBox(height: 12),
          ...selection.perks.map(
            (perk) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.successColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      perk,
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
  final String? label;
  final bool large;
  const _OrgPlanBadge({required this.plan, this.label, this.large = false});

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
      child: Text(label ?? plan.label,
          style: TextStyle(
              fontSize: large ? 12 : 10,
              fontWeight: FontWeight.w700,
              color: fg)),
    );
  }
}

// ── Owner row with "Set Owner" button ─────────────────────────────────────────
class _OrgOwnerRow extends ConsumerWidget {
  final Organization org;
  const _OrgOwnerRow({required this.org});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'Owner',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: org.ownerEmail != null
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          org.ownerEmail!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _showSetOwnerDialog(context, ref, org),
                        icon: const Icon(Icons.swap_horiz, size: 14),
                        label: const Text('Change', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blueGrey,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Text(
                        'No owner set',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () =>
                            _showSetOwnerDialog(context, ref, org),
                        icon: const Icon(Icons.person_add_outlined, size: 14),
                        label: const Text(
                          'Set Owner',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _showSetOwnerDialog(
      BuildContext context, WidgetRef ref, Organization org) {
    showDialog(
      context: context,
      builder: (_) => _SetOwnerDialog(org: org),
    ).then((_) {
      ref.invalidate(organizationByIdProvider(org.id));
      ref.invalidate(organizationsListProvider(null));
    });
  }
}

class _SetOwnerDialog extends ConsumerStatefulWidget {
  final Organization org;
  const _SetOwnerDialog({required this.org});

  @override
  ConsumerState<_SetOwnerDialog> createState() => _SetOwnerDialogState();
}

class _SetOwnerDialogState extends ConsumerState<_SetOwnerDialog> {
  final _emailController = TextEditingController(text: '');
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      // Resolve the user ID from profiles by email
      final List profileRows = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .limit(1);

      if (profileRows.isEmpty) {
        setState(() {
          _error = 'No user account found for "$email". '
              'The user must have a MilPress account first.';
          _isLoading = false;
        });
        return;
      }

      final userId = profileRows.first['id'] as String;

      await ref.read(updateOrganizationProvider.notifier).update(
            widget.org.id,
            OrgUpdate(ownerId: userId),
            widget.org,
          );

      // Also ensure they're an admin member of the org
      await ref.read(inviteMembersProvider.notifier).invite(
        widget.org.id,
        [email],
        role: MemberRole.admin,
      );

      setState(() {
        _success = 'Owner set to $email. '
            'They can now log in at /org-login.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.org.ownerEmail != null
                          ? 'Change Organization Owner'
                          : 'Set Organization Owner',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'The owner will be able to log in at /org-login and manage '
                '${widget.org.name}. They must already have a MilPress account.',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Owner Email Address',
                  hintText: 'owner@organization.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFC43B3B)),
                  ),
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F3EC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _success!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF2E7D5B)),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.copBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _isLoading ? 'Saving…' : 'Set Owner',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

// ── Invite Admin button ───────────────────────────────────────────────────────
class _InviteAdminButton extends StatelessWidget {
  final Organization org;
  const _InviteAdminButton({required this.org});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => _InviteAdminDialog(org: org),
      ),
      icon: const Icon(Icons.person_add_outlined, size: 16),
      label: const Text('Invite Org Admin'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.copBlue,
        side: const BorderSide(color: AppColors.copBlue),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// ── Invite Admin dialog ───────────────────────────────────────────────────────
class _InviteAdminDialog extends StatefulWidget {
  final Organization org;
  const _InviteAdminDialog({required this.org});

  @override
  State<_InviteAdminDialog> createState() => _InviteAdminDialogState();
}

class _InviteAdminDialogState extends State<_InviteAdminDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final origin = html.window.location.origin;
      final response = await Supabase.instance.client.functions.invoke(
        'invite-org-admin',
        body: {
          'email': email,
          'orgId': widget.org.id,
          'orgPortalUrl': '$origin/#/org-login',
        },
      );

      if (response.status != 200) {
        final body = response.data;
        final msg = (body is Map ? body['error'] as String? : null) ??
            'Invite failed (${response.status})';
        setState(() {
          _error = msg;
          _isLoading = false;
        });
        return;
      }

      final created = (response.data is Map)
          ? (response.data['created'] as bool? ?? false)
          : false;

      setState(() {
        _success = created
            ? 'Account created and invite sent to $email.'
            : 'Admin access granted and invite sent to $email.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Invite Admin — ${widget.org.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'An account will be created automatically if this email '
                'isn\'t registered yet. A temporary password will be sent '
                'to them via email.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Email field
              TextField(
                controller: _emailController,
                enabled: _success == null,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'admin@organization.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _success == null ? _invite() : null,
              ),

              // Error
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFC43B3B)),
                  ),
                ),
              ],

              // Success
              if (_success != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F3EC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Color(0xFF2E7D5B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _success!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF2E7D5B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      _success != null ? 'Done' : 'Cancel',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  if (_success == null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _invite,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined, size: 16),
                      label: Text(_isLoading ? 'Sending…' : 'Send Invite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.copBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
