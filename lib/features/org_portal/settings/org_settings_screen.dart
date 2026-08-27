// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_message_widget.dart';
import '../../../widgets/app_text_form_field.dart';
import '../../organizations/organization_models.dart';
import '../../organizations/organization_repository.dart';
import '../../subscriptions/subscription_enums.dart';
import '../auth/org_session_provider.dart';

// =============================================================================
// OrgSettingsScreen — /org/settings
// =============================================================================
class OrgSettingsScreen extends ConsumerWidget {
  const OrgSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentOrgSessionProvider);
    if (session == null) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrgProfileSection(session: session),
            const SizedBox(height: 24),
            _BillingSection(session: session),
            const SizedBox(height: 24),
            _DangerZoneSection(session: session),
          ],
        ),
      ),
    );
  }
}

// ── Section card wrapper ───────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: Colors.black45),
            ),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// ── Org profile section ────────────────────────────────────────────────────────
class _OrgProfileSection extends ConsumerStatefulWidget {
  final OrgSession session;
  const _OrgProfileSection({required this.session});

  @override
  ConsumerState<_OrgProfileSection> createState() => _OrgProfileSectionState();
}

class _OrgProfileSectionState extends ConsumerState<_OrgProfileSection> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.session.org.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(organizationRepositoryProvider).updateOrganization(
        widget.session.orgId,
        OrgUpdate(name: _nameController.text.trim()),
      );
      // Refresh the session so the sidebar name updates
      await ref.read(orgSessionProvider.notifier).refreshOrg();
      setState(() {
        _success = 'Organization profile saved.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to save: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = widget.session.org;
    return _SectionCard(
      title: 'Organization Profile',
      subtitle: 'Update your organization\'s name and details.',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              AppTextFormField(
                label: 'Organization Name',
                controller: _nameController,
                hintText: 'Enter organization name',
                prefixIcon: const Icon(Icons.business_outlined),
                style: AppTextFieldStyle.card,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Organization name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Read-only fields
              _ReadOnlyField(label: 'Organization Type', value: org.type.label),
              const SizedBox(height: 12),
              _ReadOnlyField(
                label: 'Organization ID',
                value: org.id,
                monospace: true,
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          AppMessageWidget(message: _error!, type: MessageType.error),
        ],
        if (_success != null) ...[
          const SizedBox(height: 8),
          AppMessageWidget(message: _success!, type: MessageType.success),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 160,
            child: AppButton(
              label: _isLoading ? 'Saving…' : 'Save Changes',
              backgroundColor: AppColors.copBlue,
              textColor: Colors.white,
              onPressed: _isLoading ? null : _save,
              height: 44,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;

  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Billing section ────────────────────────────────────────────────────────────
class _BillingSection extends ConsumerStatefulWidget {
  final OrgSession session;
  const _BillingSection({required this.session});

  @override
  ConsumerState<_BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends ConsumerState<_BillingSection> {
  bool _checkoutLoading = false;
  bool _portalLoading   = false;
  String? _billingError;

  OrgSession get session => widget.session;

  // ── Stripe helpers ──────────────────────────────────────────────────────

  /// Opens the upgrade plan picker then calls create-checkout-session.
  Future<void> _openUpgradeDialog() async {
    final plan = await showDialog<_UpgradePlanChoice>(
      context: context,
      builder: (_) => _UpgradePlanDialog(currentPlan: session.org.plan),
    );
    if (plan == null || !mounted) return;

    setState(() { _checkoutLoading = true; _billingError = null; });

    try {
      final url = await _fetchCheckoutUrl(plan.priceId);
      // Open in new tab — must use dart:html directly on web because
      // url_launcher called after an async gap is blocked by popup blockers.
      html.window.open(url, '_blank');
    } catch (e) {
      if (mounted) {
        setState(() => _billingError = _friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _checkoutLoading = false);
    }
  }

  /// Calls the create-checkout-session edge function and returns the URL.
  Future<String> _fetchCheckoutUrl(String priceId) async {
    final response = await Supabase.instance.client.functions.invoke(
      'create-checkout-session',
      body: {
        'type':       'org',
        'priceId':    priceId,
        'orgId':      session.orgId,
        'successUrl': '${html.window.location.origin}/org/settings?payment=success',
        'cancelUrl':  '${html.window.location.origin}/org/settings',
      },
    );

    if (response.status != 200) {
      final err = (response.data as Map?)?['error'] as String?
          ?? 'Payment service error (${response.status})';
      throw Exception(err);
    }

    final url = (response.data as Map?)?['url'] as String?;
    if (url == null) throw Exception('No checkout URL in response');
    return url;
  }

  /// Opens the Stripe Customer Portal in a new tab.
  Future<void> _openBillingPortal() async {
    setState(() { _portalLoading = true; _billingError = null; });

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-billing-portal-session',
        body: {
          'type':      'org',
          'orgId':     session.orgId,
          'returnUrl': '${html.window.location.origin}/org/settings',
        },
      );

      if (response.status != 200) {
        final code = (response.data as Map?)?['code'] as String?;
        final err  = code == 'NO_STRIPE_CUSTOMER'
            ? 'No billing account found. Please subscribe to a plan first.'
            : 'Could not open billing portal (${response.status}).';
        setState(() => _billingError = err);
        return;
      }

      final url = (response.data as Map?)?['url'] as String?;
      if (url == null) { setState(() => _billingError = 'No portal URL returned.'); return; }

      html.window.open(url, '_blank');
    } catch (e) {
      if (mounted) setState(() => _billingError = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _portalLoading = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString().replaceFirst('Exception: ', '');
    return msg.isNotEmpty ? msg : 'An unexpected error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final org = session.org;
    final billingAsync = ref.watch(_orgSubscriptionProvider(org.id));
    final hasActiveSub = org.status.isActive;

    return _SectionCard(
      title: 'Billing & Plan',
      subtitle: 'Manage your organization\'s subscription.',
      children: [
        // Current plan + status row
        _PlanInfoRow(plan: org.plan, status: org.status),
        const SizedBox(height: 16),

        // Billing details (from DB)
        billingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (sub) => sub == null
              ? const Text(
                  'No billing record on file yet.',
                  style: TextStyle(color: Colors.black38, fontSize: 13),
                )
              : _BillingDetails(sub: sub),
        ),

        if (_billingError != null) ...[
          const SizedBox(height: 10),
          AppMessageWidget(message: _billingError!, type: MessageType.error),
        ],

        const SizedBox(height: 20),

        // Action buttons
        Row(
          children: [
            // Upgrade Plan
            Expanded(
              child: AppButton(
                label: _checkoutLoading ? 'Opening…' : 'Upgrade Plan',
                backgroundColor: AppColors.copBlue,
                textColor: Colors.white,
                onPressed: _checkoutLoading ? null : _openUpgradeDialog,
                height: 44,
              ),
            ),
            const SizedBox(width: 12),

            // Manage Billing (portal)
            Expanded(
              child: AppButton(
                label: _portalLoading ? 'Opening…' : 'Manage Billing',
                backgroundColor: Colors.white,
                textColor: AppColors.copBlue,
                outlined: true,
                onPressed: hasActiveSub && !_portalLoading
                    ? _openBillingPortal
                    : null,
                height: 44,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Text(
          'Manage Billing opens the Stripe portal where you can update your '
          'payment method, download invoices, or cancel your subscription.',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _PlanInfoRow extends StatelessWidget {
  final OrgPlan plan;
  final SubStatus status;
  const _PlanInfoRow({required this.plan, required this.status});

  Color get _statusColor => status.isActive ? const Color(0xFF10B981) : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.layers_outlined, size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                '${plan.label} Plan',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _statusColor.withOpacity(0.4)),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _statusColor,
            ),
          ),
        ),
      ],
    );
  }
}

// Billing record model (local, from org_subscriptions table)
class _OrgSub {
  final String billingCycle;
  final double amountUsd;
  final DateTime? periodEnd;
  _OrgSub({
    required this.billingCycle,
    required this.amountUsd,
    this.periodEnd,
  });
}

final _orgSubscriptionProvider =
    FutureProvider.family<_OrgSub?, String>((ref, orgId) async {
  final List data = await Supabase.instance.client
      .from('org_subscriptions')
      .select('billing_cycle, amount_usd, current_period_end')
      .eq('org_id', orgId)
      .order('created_at', ascending: false)
      .limit(1);
  if (data.isEmpty) return null;
  final row = data.first as Map;
  return _OrgSub(
    billingCycle: (row['billing_cycle'] as String?) ?? 'monthly',
    amountUsd: (row['amount_usd'] as num?)?.toDouble() ?? 0,
    periodEnd: row['current_period_end'] != null
        ? DateTime.tryParse(row['current_period_end'] as String)
        : null,
  );
});

class _BillingDetails extends StatelessWidget {
  final _OrgSub sub;
  const _BillingDetails({required this.sub});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return Row(
      children: [
        Expanded(
          child: _BillingTile(
            label: 'Amount',
            value: '\$${sub.amountUsd.toStringAsFixed(2)} / ${sub.billingCycle}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BillingTile(
            label: 'Billing cycle',
            value: sub.billingCycle == 'annual' ? 'Annual' : 'Monthly',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BillingTile(
            label: 'Renews on',
            value: sub.periodEnd != null
                ? fmt.format(sub.periodEnd!)
                : 'N/A',
          ),
        ),
      ],
    );
  }
}

class _BillingTile extends StatelessWidget {
  final String label;
  final String value;
  const _BillingTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upgrade plan dialog ────────────────────────────────────────────────────────

class _UpgradePlanChoice {
  final String priceId;
  final String label;
  _UpgradePlanChoice({required this.priceId, required this.label});
}

/// Dialog that lets the org admin pick a new plan + billing cycle.
/// Fetches available org plans from the subscription_plans table so price IDs
/// are always in sync with what's configured in Stripe.
class _UpgradePlanDialog extends ConsumerWidget {
  final OrgPlan currentPlan;
  const _UpgradePlanDialog({required this.currentPlan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(_orgPlansProvider);

    return AlertDialog(
      title: const Text('Upgrade Plan'),
      content: SizedBox(
        width: 480,
        child: plansAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(
            'Could not load plans: $e',
            style: const TextStyle(color: Colors.redAccent),
          ),
          data: (plans) {
            if (plans.isEmpty) {
              return const Text(
                'No org plans are configured yet. Add Stripe Price IDs to '
                'your subscription_plans table to enable self-serve upgrades.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: plans.map((p) => _PlanOption(plan: p)).toList(),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// One selectable plan row inside the upgrade dialog.
class _PlanOption extends StatelessWidget {
  final _OrgPlanRow plan;
  const _PlanOption({required this.plan});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        plan.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        plan.priceLabel,
        style: const TextStyle(fontSize: 13, color: Colors.black54),
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.copBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: () => Navigator.pop(
          context,
          _UpgradePlanChoice(priceId: plan.stripePriceId, label: plan.name),
        ),
        child: const Text('Select'),
      ),
    );
  }
}

// Minimal model for org plans fetched from subscription_plans
class _OrgPlanRow {
  final String id;
  final String name;
  final String stripePriceId;
  final double priceUsd;
  final String billingCycle;

  _OrgPlanRow({
    required this.id,
    required this.name,
    required this.stripePriceId,
    required this.priceUsd,
    required this.billingCycle,
  });

  String get priceLabel {
    if (priceUsd == 0) return 'Free';
    final cycle = billingCycle == 'annual' ? 'yr' : 'mo';
    return '\$${priceUsd.toStringAsFixed(2)} / $cycle';
  }
}

/// Fetches active org-tier plans that have a Stripe price ID configured.
final _orgPlansProvider = FutureProvider<List<_OrgPlanRow>>((ref) async {
  final data = await Supabase.instance.client
      .from('subscription_plans')
      .select('id, name, stripe_price_id, price_usd, billing_cycle')
      .eq('is_active', true)
      // org plans have names containing 'starter', 'growth', or 'enterprise'
      .or('name.ilike.%starter%,name.ilike.%growth%,name.ilike.%enterprise%')
      .not('stripe_price_id', 'is', null)
      .order('price_usd', ascending: true)
      as List;

  return data
      .map((row) => _OrgPlanRow(
            id: row['id'] as String,
            name: row['name'] as String,
            stripePriceId: row['stripe_price_id'] as String,
            priceUsd: (row['price_usd'] as num?)?.toDouble() ?? 0,
            billingCycle: (row['billing_cycle'] as String?) ?? 'monthly',
          ))
      .toList();
});

// ── Danger zone ────────────────────────────────────────────────────────────────
class _DangerZoneSection extends StatelessWidget {
  final OrgSession session;
  const _DangerZoneSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC43B3B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'These actions cannot be undone.',
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancel Subscription',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'You can cancel anytime from the billing portal. '
                      'Access continues until the end of your current billing period.',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => _openBillingPortal(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFC43B3B),
                  side: const BorderSide(color: Color(0xFFC43B3B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Manage / Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openBillingPortal(BuildContext context) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-billing-portal-session',
        body: {
          'type':      'org',
          'orgId':     session.orgId,
          'returnUrl': '${html.window.location.origin}/org/settings',
        },
      );

      if (!context.mounted) return;

      if (response.status != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (response.data as Map?)?['error'] as String?
                  ?? 'Could not open billing portal. Please try again.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final url = (response.data as Map?)?['url'] as String?;
      if (url == null) return;

      html.window.open(url, '_blank');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
