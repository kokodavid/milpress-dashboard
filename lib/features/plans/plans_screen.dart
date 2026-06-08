import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utils/app_colors.dart';
import '../subscriptions/subscription_enums.dart';
import '../subscriptions/subscriptions_screen.dart' show PlanBadge;
import 'plan_models.dart';
import 'plan_repository.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansListProvider);

    return Scaffold(
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (plans) => _PlansBody(plans: plans),
      ),
    );
  }
}

// =============================================================================
// Body
// =============================================================================
class _PlansBody extends ConsumerWidget {
  final List<SubscriptionPlan> plans;
  const _PlansBody({required this.plans});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${plans.length} plan${plans.length == 1 ? '' : 's'} configured',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _showCreateDialog(context, ref, plans.length),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Plan'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Plan cards
          if (plans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  children: [
                    Icon(Icons.layers_outlined,
                        size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text('No plans yet — create your first one'),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossCount =
                    constraints.maxWidth > 1100 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: plans
                      .map((p) => SizedBox(
                            width: (constraints.maxWidth -
                                    (crossCount - 1) * 16) /
                                crossCount,
                            child: _PlanCard(plan: p),
                          ))
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, WidgetRef ref, int currentCount) {
    showDialog(
      context: context,
      builder: (_) => _PlanFormDialog(
        sortOrder: currentCount,
        onSave: (input) async {
          await ref.read(createPlanProvider.notifier).create(input);
        },
      ),
    );
  }
}

// =============================================================================
// Plan card
// =============================================================================
class _PlanCard extends ConsumerWidget {
  final SubscriptionPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(planActionsProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: plan.isHighlighted
              ? AppColors.primaryColor
              : AppColors.borderColor,
          width: plan.isHighlighted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            decoration: BoxDecoration(
              color: plan.isActive
                  ? AppColors.faintGrey
                  : Colors.grey[100],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkGrey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PlanBadge(plan: plan.planType),
                          if (plan.isHighlighted) ...[
                            const SizedBox(width: 6),
                            _Badge(
                                label: 'Popular',
                                bg: AppColors.primaryColor.withOpacity(0.12),
                                fg: AppColors.primaryColor),
                          ],
                          if (!plan.isActive) ...[
                            const SizedBox(width: 6),
                            _Badge(
                                label: 'Inactive',
                                bg: Colors.grey[200]!,
                                fg: Colors.grey[600]!),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.priceLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkGrey,
                        ),
                      ),
                      if (plan.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          plan.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) => _handleMenu(context, ref, v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_outlined, size: 18),
                        title: Text('Edit plan'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_active',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          plan.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        title: Text(
                            plan.isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_highlighted',
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          plan.isHighlighted
                              ? Icons.star_outlined
                              : Icons.star_border_outlined,
                          size: 18,
                        ),
                        title: Text(plan.isHighlighted
                            ? 'Remove Popular badge'
                            : 'Mark as Popular'),
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.delete_outline,
                            size: 18, color: AppColors.errorColor),
                        title: Text('Delete',
                            style:
                                TextStyle(color: AppColors.errorColor)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Features list
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Features',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.grey,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          _showAddFeatureDialog(context, ref),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (plan.features.isEmpty)
                  const Text(
                    'No features yet',
                    style: TextStyle(fontSize: 12, color: AppColors.grey),
                  )
                else
                  ...plan.features.map((f) => _FeatureRow(
                        feature: f,
                        onDelete: () =>
                            actions.deleteFeature(f.id),
                        onToggle: (v) =>
                            actions.updateFeature(f.id, isIncluded: v),
                      )),
              ],
            ),
          ),

          // Provider IDs (collapsed by default)
          if (plan.stripePriceId != null || plan.rcProductId != null)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  if (plan.stripePriceId != null)
                    _IdChip(
                        icon: Icons.payment_outlined,
                        label: 'Stripe',
                        value: plan.stripePriceId!),
                  if (plan.rcProductId != null)
                    _IdChip(
                        icon: Icons.store_outlined,
                        label: 'RevenueCat',
                        value: plan.rcProductId!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleMenu(
      BuildContext context, WidgetRef ref, String action) async {
    final actions = ref.read(planActionsProvider.notifier);
    switch (action) {
      case 'edit':
        showDialog(
          context: context,
          builder: (_) => _PlanFormDialog(
            existing: plan,
            onSave: (_) async {},
            onUpdate: (update) async {
              await ref
                  .read(updatePlanProvider.notifier)
                  .update(plan.id, update);
            },
          ),
        );
      case 'toggle_active':
        await actions.toggleActive(plan.id, !plan.isActive);
      case 'toggle_highlighted':
        await actions.toggleHighlighted(plan.id, !plan.isHighlighted);
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete plan?'),
            content: Text(
                'This will permanently delete "${plan.name}" and all its features.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.errorColor),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) await actions.deletePlan(plan.id);
    }
  }

  void _showAddFeatureDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    bool isIncluded = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add feature'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Feature label',
                  hintText: 'e.g. Offline downloads',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Included in plan',
                    style: TextStyle(fontSize: 13)),
                value: isIncluded,
                onChanged: (v) => setState(() => isIncluded = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final label = controller.text.trim();
                if (label.isEmpty) return;
                Navigator.pop(ctx);
                await ref.read(planActionsProvider.notifier).addFeature(
                      PlanFeature(
                        id: '',
                        planId: plan.id,
                        label: label,
                        isIncluded: isIncluded,
                        sortOrder: plan.features.length,
                        createdAt: DateTime.now(),
                      ),
                    );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Feature row
// =============================================================================
class _FeatureRow extends StatelessWidget {
  final PlanFeature feature;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;
  const _FeatureRow({
    required this.feature,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            feature.isIncluded ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: feature.isIncluded
                ? AppColors.successColor
                : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature.label,
              style: TextStyle(
                fontSize: 13,
                color: feature.isIncluded
                    ? AppColors.darkGrey
                    : AppColors.grey,
                decoration: feature.isIncluded
                    ? null
                    : TextDecoration.lineThrough,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onToggle(!feature.isIncluded),
            child: Icon(
              feature.isIncluded
                  ? Icons.toggle_on_outlined
                  : Icons.toggle_off_outlined,
              size: 18,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close, size: 16, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Plan create / edit dialog
// =============================================================================
class _PlanFormDialog extends StatefulWidget {
  final SubscriptionPlan? existing;
  final int sortOrder;
  final Future<void> Function(SubscriptionPlanCreate)? onSave;
  final Future<void> Function(SubscriptionPlanUpdate)? onUpdate;

  const _PlanFormDialog({
    this.existing,
    this.sortOrder = 0,
    this.onSave,
    this.onUpdate,
  });

  @override
  State<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends State<_PlanFormDialog> {
  final _formKey   = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _price;
  late final TextEditingController _stripeId;
  late final TextEditingController _rcId;
  late PlanType      _planType;
  late BillingCycle  _billingCycle;
  late bool          _isHighlighted;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name         = TextEditingController(text: e?.name ?? '');
    _desc         = TextEditingController(text: e?.description ?? '');
    _price        = TextEditingController(
        text: e != null ? e.priceUsd.toStringAsFixed(2) : '0.00');
    _stripeId     = TextEditingController(text: e?.stripePriceId ?? '');
    _rcId         = TextEditingController(text: e?.rcProductId ?? '');
    _planType     = e?.planType     ?? PlanType.premium;
    _billingCycle = e?.billingCycle ?? BillingCycle.monthly;
    _isHighlighted = e?.isHighlighted ?? false;
  }

  @override
  void dispose() {
    _name.dispose(); _desc.dispose(); _price.dispose();
    _stripeId.dispose(); _rcId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit plan' : 'New plan'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Plan name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                // Description
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(
                    labelText: 'Short tagline',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Plan type + Billing cycle
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PlanType>(
                        value: _planType,
                        decoration: const InputDecoration(
                          labelText: 'Plan type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        items: PlanType.values
                            .map((t) => DropdownMenuItem(
                                value: t, child: Text(t.label)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _planType = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<BillingCycle>(
                        value: _billingCycle,
                        decoration: const InputDecoration(
                          labelText: 'Billing cycle',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        items: BillingCycle.values
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c.label)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _billingCycle = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Price
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Price (USD) *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Highlighted toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mark as Popular',
                      style: TextStyle(fontSize: 13)),
                  subtitle: const Text(
                      'Shows a "Popular" badge on the paywall',
                      style: TextStyle(fontSize: 11)),
                  value: _isHighlighted,
                  onChanged: (v) => setState(() => _isHighlighted = v),
                ),
                const Divider(height: 24),
                // Provider IDs (optional)
                Text(
                  'Payment provider IDs (optional)',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.grey),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stripeId,
                  decoration: const InputDecoration(
                    labelText: 'Stripe Price ID',
                    hintText: 'price_xxx',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _rcId,
                  decoration: const InputDecoration(
                    labelText: 'RevenueCat Product ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(isEdit ? 'Save changes' : 'Create plan'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final price = double.parse(_price.text.trim());
      final stripeId = _stripeId.text.trim().isEmpty ? null : _stripeId.text.trim();
      final rcId     = _rcId.text.trim().isEmpty     ? null : _rcId.text.trim();

      if (widget.existing == null) {
        await widget.onSave!(SubscriptionPlanCreate(
          name:          _name.text.trim(),
          description:   _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          planType:      _planType,
          billingCycle:  _billingCycle,
          priceUsd:      price,
          isHighlighted: _isHighlighted,
          sortOrder:     widget.sortOrder,
          stripePriceId: stripeId,
          rcProductId:   rcId,
        ));
      } else {
        await widget.onUpdate!(SubscriptionPlanUpdate(
          name:          _name.text.trim(),
          description:   _desc.text.trim().isEmpty ? null : _desc.text.trim(),
          priceUsd:      price,
          isHighlighted: _isHighlighted,
          stripePriceId: stripeId,
          rcProductId:   rcId,
        ));
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// =============================================================================
// Small helpers
// =============================================================================
class _Badge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Badge({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _IdChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _IdChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.grey),
          const SizedBox(width: 6),
          Text('$label: ',
              style:
                  const TextStyle(fontSize: 11, color: AppColors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.darkGrey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
