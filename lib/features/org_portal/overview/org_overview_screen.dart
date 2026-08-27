import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_colors.dart';
import '../../organizations/organization_models.dart';
import '../../organizations/organization_repository.dart';
import '../../organizations/sponsored_grant_model.dart';
import '../../subscriptions/subscription_enums.dart';
import '../../user_progress/widgets/donut_chart.dart';
import '../auth/org_session_provider.dart';

// =============================================================================
// OrgOverviewScreen — /org/overview
// =============================================================================
class OrgOverviewScreen extends ConsumerWidget {
  const OrgOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentOrgSessionProvider);
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Live org record (refreshes after updates)
    final orgAsync = ref.watch(organizationByIdProvider(session.orgId));
    final membersAsync = ref.watch(orgMembersProvider(session.orgId));
    final grantsAsync = ref.watch(
      orgSponsoredGrantsProvider(GrantsQuery(orgId: session.orgId)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Org name banner ─────────────────────────────────────────────
          orgAsync.when(
            loading: () => const _BannerSkeleton(),
            error: (e, _) => const SizedBox.shrink(),
            data: (org) => org == null
                ? const SizedBox.shrink()
                : _OrgBanner(org: org),
          ),
          const SizedBox(height: 24),

          // ── KPI row ──────────────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 800 ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: [
                  // Seats used
                  orgAsync.when(
                    loading: () => const _KpiCardSkeleton(),
                    error: (_, __) => const _KpiCardSkeleton(),
                    data: (org) => _KpiCard(
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFF3B82F6),
                      label: 'Seats Used',
                      value: org == null
                          ? '—'
                          : '${org.seatsUsed} / ${org.seatLimit ?? '∞'}',
                      subtitle: org == null
                          ? null
                          : org.seatLimit != null
                              ? '${((org.seatsUsed / org.seatLimit!) * 100).round()}% utilisation'
                              : 'Unlimited seats',
                    ),
                  ),

                  // Active members
                  membersAsync.when(
                    loading: () => const _KpiCardSkeleton(),
                    error: (_, __) => const _KpiCardSkeleton(),
                    data: (members) {
                      final active = members
                          .where((m) => m.status == MemberStatus.active)
                          .length;
                      final pending = members
                          .where((m) => m.status == MemberStatus.pending)
                          .length;
                      return _KpiCard(
                        icon: Icons.how_to_reg_outlined,
                        iconColor: const Color(0xFF10B981),
                        label: 'Active Members',
                        value: '$active',
                        subtitle: pending > 0 ? '$pending pending invite${pending == 1 ? '' : 's'}' : null,
                      );
                    },
                  ),

                  // Plan
                  orgAsync.when(
                    loading: () => const _KpiCardSkeleton(),
                    error: (_, __) => const _KpiCardSkeleton(),
                    data: (org) => _KpiCard(
                      icon: Icons.layers_outlined,
                      iconColor: const Color(0xFFE85D04),
                      label: 'Plan',
                      value: org?.plan.label ?? '—',
                      subtitle: org?.status.label,
                    ),
                  ),

                  // Active grants
                  grantsAsync.when(
                    loading: () => const _KpiCardSkeleton(),
                    error: (_, __) => const _KpiCardSkeleton(),
                    data: (grants) {
                      final active = grants
                          .where((g) => g.status == GrantStatus.active)
                          .length;
                      return _KpiCard(
                        icon: Icons.card_giftcard_outlined,
                        iconColor: const Color(0xFF8B5CF6),
                        label: 'Active Grants',
                        value: '$active',
                        subtitle: 'sponsored learners',
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Two-column detail row ─────────────────────────────────────────
          LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _SeatUtilisationCard(orgAsync: orgAsync),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _QuickActionsCard(),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _SeatUtilisationCard(orgAsync: orgAsync),
                const SizedBox(height: 16),
                _QuickActionsCard(),
              ],
            );
          }),
          const SizedBox(height: 24),

          // ── Recent members ───────────────────────────────────────────────
          _RecentMembersCard(membersAsync: membersAsync),
        ],
      ),
    );
  }
}

// ── Org banner ─────────────────────────────────────────────────────────────────
class _OrgBanner extends StatelessWidget {
  final Organization org;
  const _OrgBanner({required this.org});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF142C44), Color(0xFF1E3F5A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${org.type.label} · ${org.plan.label} Plan',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(status: org.status),
        ],
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final SubStatus status;
  const _StatusBadge({required this.status});

  Color get _color => status.isActive ? const Color(0xFF10B981) : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── KPI card ───────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
        ],
      ),
    );
  }
}

class _KpiCardSkeleton extends StatelessWidget {
  const _KpiCardSkeleton();
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
      );
}

// ── Seat utilisation card ──────────────────────────────────────────────────────
class _SeatUtilisationCard extends StatelessWidget {
  final AsyncValue<Organization?> orgAsync;
  const _SeatUtilisationCard({required this.orgAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seat Utilisation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          orgAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (org) {
              if (org == null) return const SizedBox.shrink();
              if (org.seatLimit == null) {
                return const Text(
                  'Unlimited seats on Enterprise plan.',
                  style: TextStyle(color: Colors.black54),
                );
              }
              return Row(
                children: [
                  DonutChart(
                    value: org.seatUtilisation,
                    color: const Color(0xFF3B82F6),
                    size: 80,
                    strokeWidth: 10,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UtilRow(
                          label: 'Seats used',
                          value: '${org.seatsUsed}',
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(height: 8),
                        _UtilRow(
                          label: 'Seats available',
                          value: '${org.seatsAvailable}',
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        _UtilRow(
                          label: 'Total seats',
                          value: '${org.seatLimit}',
                          color: Colors.transparent,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UtilRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isTotal;

  const _UtilRow({
    required this.label,
    required this.value,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!isTotal)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else
          const SizedBox(width: 18),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isTotal ? Colors.black45 : Colors.black54,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isTotal ? FontWeight.w500 : FontWeight.w600,
            color: isTotal ? Colors.black45 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ── Quick actions card ─────────────────────────────────────────────────────────
class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.person_add_outlined,
            label: 'Invite Member',
            color: const Color(0xFF3B82F6),
            onTap: () => context.go('/org/members'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.bar_chart_outlined,
            label: 'View Learner Progress',
            color: const Color(0xFF10B981),
            onTap: () => context.go('/org/progress'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.card_giftcard_outlined,
            label: 'Manage Grants',
            color: const Color(0xFF8B5CF6),
            onTap: () => context.go('/org/grants'),
          ),
          const SizedBox(height: 8),
          _ActionTile(
            icon: Icons.settings_outlined,
            label: 'Organization Settings',
            color: Colors.black54,
            onTap: () => context.go('/org/settings'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ── Recent members card ────────────────────────────────────────────────────────
class _RecentMembersCard extends StatelessWidget {
  final AsyncValue<List<OrgMember>> membersAsync;
  const _RecentMembersCard({required this.membersAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Members',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/org/members'),
                child: const Text('View all →'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          membersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (members) {
              final recent = members
                  .where((m) => m.status != MemberStatus.removed)
                  .take(5)
                  .toList();
              if (recent.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'No members yet. Invite your team!',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                );
              }
              return Column(
                children: recent
                    .map((m) => _MemberRow(member: m))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final OrgMember member;
  const _MemberRow({required this.member});

  @override
  Widget build(BuildContext context) {
    final isPending = member.status == MemberStatus.pending;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              _initials(member.displayName),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  member.inviteEmail,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFFFF4D6)
                  : const Color(0xFFE4F3EC),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              member.status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isPending
                    ? const Color(0xFFB07600)
                    : const Color(0xFF2E7D5B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
