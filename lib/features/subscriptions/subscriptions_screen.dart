import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../utils/app_colors.dart';
import '../../utils/initials.dart';
import '../../widgets/search_input.dart';
import 'subscription_enums.dart';
import 'subscription_models.dart';
import 'subscription_repository.dart';

// Local UI state
// selectedUserId tracks the userId (from profiles), not a subscription row ID
final _selectedUserIdProvider  = StateProvider<String?>((ref) => null);
final _subSearchQueryProvider  = StateProvider<String>((ref) => '');
final _subPlanFilterProvider   = StateProvider<PlanType?>((ref) => null);
final _subStatusFilterProvider = StateProvider<SubStatus?>((ref) => null);

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search   = ref.watch(_subSearchQueryProvider);
    final plan     = ref.watch(_subPlanFilterProvider);
    final status   = ref.watch(_subStatusFilterProvider);
    final query    = SubscriptionsQuery(search: search, plan: plan, status: status);
    // Use userPlansListProvider so free and sponsored users appear too
    final plansAsync = ref.watch(userPlansListProvider(query));
    final selectedUserId = ref.watch(_selectedUserIdProvider);

    Future<void> refresh() async {
      ref.invalidate(userPlansListProvider(query));
      ref.invalidate(subscriptionKpisProvider);
      await ref.read(userPlansListProvider(query).future);
    }

    return Scaffold(
      body: Row(
        children: [
          // ── Left panel: KPIs + list ───────────────────────────────────────
          Expanded(
            flex: 32,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.faintGrey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  _KpiMiniStrip(),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: SearchInput(
                      hintText: 'Search by name or email…',
                      initialValue: search,
                      onChanged: (v) =>
                          ref.read(_subSearchQueryProvider.notifier).state = v,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FilterChips(),
                  const SizedBox(height: 4),
                  Expanded(
                    child: plansAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => _ErrorState(
                        message: e.toString(),
                        onRetry: refresh,
                      ),
                      data: (plans) => _UserPlanList(
                        plans: plans,
                        selectedUserId: selectedUserId,
                        onRefresh: refresh,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right panel: detail ───────────────────────────────────────────
          Expanded(
            flex: 68,
            child: selectedUserId == null
                ? const _EmptyDetail()
                : _UserPlanDetail(userId: selectedUserId),
          ),
        ],
      ),
    );
  }
}

// ── KPI mini-strip ────────────────────────────────────────────────────────────
class _KpiMiniStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpisAsync = ref.watch(subscriptionKpisProvider);
    return kpisAsync.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: LinearProgressIndicator()),
      ),
      error: (_, __) => const SizedBox(height: 72),
      data: (kpis) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _KpiCell(
              label: 'Premium',
              value: kpis.totalPremium.toString(),
              color: const Color(0xFF4F46E5),
            ),
            _KpiCell(
              label: 'Sponsored',
              value: kpis.totalSponsored.toString(),
              color: const Color(0xFF0891B2),
            ),
            _KpiCell(
              label: 'MRR',
              value: '\$${kpis.mrrUsd.toStringAsFixed(0)}',
              color: AppColors.successColor,
            ),
            _KpiCell(
              label: 'Churned',
              value: kpis.cancelledThisMonth.toString(),
              color: AppColors.errorColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _KpiCell({
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter chips ─────────────────────────────────────────────────────────────
class _FilterChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planFilter   = ref.watch(_subPlanFilterProvider);
    final statusFilter = ref.watch(_subStatusFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Plan filters
          for (final plan in [PlanType.premium, PlanType.free, PlanType.sponsored])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(plan.label, style: const TextStyle(fontSize: 11)),
                selected: planFilter == plan,
                onSelected: (on) => ref
                    .read(_subPlanFilterProvider.notifier)
                    .state = on ? plan : null,
                selectedColor: AppColors.primaryColor.withOpacity(0.15),
                checkmarkColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          const SizedBox(width: 8),
          // Status filters
          for (final s in [SubStatus.active, SubStatus.cancelled, SubStatus.pastDue])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(s.label, style: const TextStyle(fontSize: 11)),
                selected: statusFilter == s,
                onSelected: (on) => ref
                    .read(_subStatusFilterProvider.notifier)
                    .state = on ? s : null,
                selectedColor: AppColors.primaryColor.withOpacity(0.15),
                checkmarkColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

// ── User plan list ────────────────────────────────────────────────────────────
class _UserPlanList extends ConsumerWidget {
  final List<UserPlanEntry> plans;
  final String? selectedUserId;
  final Future<void> Function() onRefresh;
  const _UserPlanList({
    required this.plans,
    required this.selectedUserId,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.credit_card_off_outlined, size: 36, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No users found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: plans.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${plans.length} result(s)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            );
          }
          final entry = plans[i - 1];
          final isSelected = selectedUserId == entry.userId;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => ref
                  .read(_selectedUserIdProvider.notifier)
                  .state = entry.userId,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryColor.withOpacity(0.12),
                      child: Text(
                        computeInitials(entry.displayName),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGrey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.email ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PlanBadge(plan: entry.planType),
                        const SizedBox(height: 4),
                        SubStatusBadge(status: entry.effectiveStatus),
                      ],
                    ),
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

// ── User plan detail ──────────────────────────────────────────────────────────
class _UserPlanDetail extends ConsumerWidget {
  final String userId;
  const _UserPlanDetail({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(userPlanByUserIdProvider(userId));

    return entryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entry) {
        if (entry == null) {
          return const Center(child: Text('User not found'));
        }
        final fmt = DateFormat('MMM d, yyyy');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryColor.withOpacity(0.12),
                    child: Text(
                      computeInitials(entry.displayName),
                      style: const TextStyle(
                        fontSize: 16,
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
                        Text(
                          entry.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          entry.email ?? '',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PlanBadge(plan: entry.planType, large: true),
                  const SizedBox(width: 8),
                  SubStatusBadge(status: entry.effectiveStatus, large: true),
                ],
              ),
              const SizedBox(height: 24),

              // Account info card (always shown)
              _DetailCard(
                children: [
                  _DetailRow('Member since', fmt.format(entry.createdAt)),
                  _DetailRow('User ID', entry.userId),
                ],
              ),
              const SizedBox(height: 16),

              // Billing card — only for paid subscribers
              if (entry.hasPaidSubscription) ...[
                Text(
                  'Subscription',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _DetailCard(
                  children: [
                    _DetailRow('Billing cycle', entry.billingCycle!.label),
                    if (entry.currentPeriodStart != null &&
                        entry.currentPeriodEnd != null)
                      _DetailRow(
                        'Current period',
                        '${fmt.format(entry.currentPeriodStart!)} → ${fmt.format(entry.currentPeriodEnd!)}',
                      ),
                    if (entry.currentPeriodEnd != null)
                      _DetailRow(
                        'Renews / Expires',
                        entry.cancelAtPeriodEnd
                            ? 'Cancels on ${fmt.format(entry.currentPeriodEnd!)}'
                            : fmt.format(entry.currentPeriodEnd!),
                      ),
                    if (entry.paymentProvider != null)
                      _DetailRow('Provider', entry.paymentProvider!),
                    if (entry.externalSubId != null)
                      _DetailRow('Provider Sub ID', entry.externalSubId!),
                    if (entry.cancelledAt != null)
                      _DetailRow('Cancelled at', fmt.format(entry.cancelledAt!)),
                  ],
                ),
                const SizedBox(height: 20),

                // Admin actions (only if subscription is active)
                if (entry.subStatus?.isActive ?? false) ...[
                  Text(
                    'Admin Actions',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ActionButton(
                        label: 'Extend Period',
                        icon: Icons.calendar_month_outlined,
                        color: const Color(0xFF4F46E5),
                        onTap: () => _showExtendDialog(context, ref, entry),
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        label: 'Cancel Subscription',
                        icon: Icons.cancel_outlined,
                        color: AppColors.errorColor,
                        onTap: () => _showCancelDialog(context, ref, entry),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                // No subscription — show plan type explanation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.faintGrey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.planType == PlanType.sponsored
                            ? Icons.volunteer_activism_outlined
                            : Icons.person_outline,
                        color: AppColors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.planType == PlanType.sponsored
                            ? 'Access provided via a sponsored grant.'
                            : 'No paid subscription — on the free plan.',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showExtendDialog(
      BuildContext context, WidgetRef ref, UserPlanEntry entry) {
    DateTime picked =
        (entry.currentPeriodEnd ?? DateTime.now()).add(const Duration(days: 30));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Extend Subscription'),
        content: StatefulBuilder(
          builder: (ctx, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('New period end: ${DateFormat('MMM d, yyyy').format(picked)}'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: picked,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date != null) setState(() => picked = date);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Pick date'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              // Build a Subscription shell for the controller
              final sub = await ref
                  .read(subscriptionRepositoryProvider)
                  .fetchByUserId(entry.userId);
              if (sub != null) {
                await ref
                    .read(extendSubscriptionProvider.notifier)
                    .extend(sub, picked);
                ref.invalidate(userPlanByUserIdProvider(entry.userId));
                ref.invalidate(subscriptionKpisProvider);
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
      BuildContext context, WidgetRef ref, UserPlanEntry entry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'This will immediately cancel the subscription. The learner will lose Premium access. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorColor),
            onPressed: () async {
              Navigator.pop(context);
              final sub = await ref
                  .read(subscriptionRepositoryProvider)
                  .fetchByUserId(entry.userId);
              if (sub != null) {
                await ref
                    .read(cancelSubscriptionProvider.notifier)
                    .cancel(sub);
                ref.invalidate(userPlanByUserIdProvider(entry.userId));
                ref.invalidate(subscriptionKpisProvider);
              }
            },
            child: const Text('Cancel subscription'),
          ),
        ],
      ),
    );
  }
}

// ── Shared badge widgets (also used by other screens) ────────────────────────
class PlanBadge extends StatelessWidget {
  final PlanType plan;
  final bool large;
  const PlanBadge({super.key, required this.plan, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (plan) {
      PlanType.premium   => (const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
      PlanType.sponsored => (const Color(0xFFCFFAFE), const Color(0xFF164E63)),
      PlanType.free      => (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        plan.label,
        style: TextStyle(
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class SubStatusBadge extends StatelessWidget {
  final SubStatus status;
  final bool large;
  const SubStatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      SubStatus.active    => (const Color(0xFFD1FAE5), const Color(0xFF065F46)),
      SubStatus.trialing  => (const Color(0xFFE0E7FF), const Color(0xFF3730A3)),
      SubStatus.pastDue   => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      SubStatus.cancelled => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      SubStatus.expired   => (const Color(0xFFF3F4F6), const Color(0xFF374151)),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 7,
        vertical: large ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: large ? 12 : 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final List<Widget> children;
  const _DetailCard({required this.children});
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
            .map((e) => Column(
                  children: [
                    e.value,
                    if (e.key < children.length - 1)
                      Divider(height: 1, color: AppColors.borderColor),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.faintGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: const Text(
          'Select a subscription\nto view details',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.5),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 8),
            const Text('Failed to load'),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700])),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
