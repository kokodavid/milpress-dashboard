import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_message_widget.dart';
import '../../organizations/organization_repository.dart';
import '../../organizations/sponsored_grant_model.dart';
import '../../subscriptions/subscription_enums.dart';
import '../auth/org_session_provider.dart';

// Local filter state
final _grantStatusFilterProvider = StateProvider<GrantStatus?>((ref) => null);
final _grantSearchProvider = StateProvider<String>((ref) => '');

// =============================================================================
// OrgGrantsScreen — /org/grants
// =============================================================================
class OrgGrantsScreen extends ConsumerWidget {
  const OrgGrantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentOrgSessionProvider);
    if (session == null) return const Center(child: CircularProgressIndicator());

    final statusFilter = ref.watch(_grantStatusFilterProvider);
    final search = ref.watch(_grantSearchProvider);
    final query = GrantsQuery(
      orgId: session.orgId,
      status: statusFilter,
      search: search.isEmpty ? null : search,
    );
    final grantsAsync = ref.watch(orgSponsoredGrantsProvider(query));

    void refresh() => ref.invalidate(orgSponsoredGrantsProvider(query));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sponsored Grants',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Invite learners to access premium content at no cost to them.',
                        style: TextStyle(fontSize: 13, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showBulkInviteDialog(context, ref, session.orgId, refresh),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Grants'),
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
            ),
          ),
          const SizedBox(height: 16),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Search
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by email or name…',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.borderColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (v) =>
                        ref.read(_grantSearchProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(width: 12),
                // Status filter chips
                _FilterChip(
                  label: 'All',
                  selected: statusFilter == null,
                  onTap: () =>
                      ref.read(_grantStatusFilterProvider.notifier).state =
                          null,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Active',
                  selected: statusFilter == GrantStatus.active,
                  onTap: () => ref
                      .read(_grantStatusFilterProvider.notifier)
                      .state = GrantStatus.active,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Expired',
                  selected: statusFilter == GrantStatus.expired,
                  onTap: () => ref
                      .read(_grantStatusFilterProvider.notifier)
                      .state = GrantStatus.expired,
                ),
                const SizedBox(width: 6),
                _FilterChip(
                  label: 'Revoked',
                  selected: statusFilter == GrantStatus.revoked,
                  onTap: () => ref
                      .read(_grantStatusFilterProvider.notifier)
                      .state = GrantStatus.revoked,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // Grants table
          Expanded(
            child: grantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (grants) => grants.isEmpty
                  ? const _EmptyGrantsState()
                  : _GrantsTable(
                      grants: grants,
                      orgId: session.orgId,
                      onChanged: refresh,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBulkInviteDialog(
    BuildContext context,
    WidgetRef ref,
    String orgId,
    VoidCallback onDone,
  ) {
    showDialog(
      context: context,
      builder: (_) => _BulkGrantDialog(orgId: orgId),
    ).then((_) => onDone());
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.copBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.copBlue : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// ── Grants table ───────────────────────────────────────────────────────────────
class _GrantsTable extends ConsumerWidget {
  final List<SponsoredGrant> grants;
  final String orgId;
  final VoidCallback onChanged;

  const _GrantsTable({
    required this.grants,
    required this.orgId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F8F8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: _HeaderCell('Learner')),
                  Expanded(flex: 2, child: _HeaderCell('Status')),
                  Expanded(flex: 2, child: _HeaderCell('Granted')),
                  Expanded(flex: 2, child: _HeaderCell('Expires')),
                  Expanded(flex: 2, child: _HeaderCell('Redeemed')),
                  SizedBox(width: 40),
                ],
              ),
            ),
            const Divider(height: 1),
            // Rows
            ...grants.asMap().entries.map((e) {
              final isLast = e.key == grants.length - 1;
              return Column(
                children: [
                  _GrantRow(
                    grant: e.value,
                    orgId: orgId,
                    onChanged: onChanged,
                  ),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.black45,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _GrantRow extends ConsumerWidget {
  final SponsoredGrant grant;
  final String orgId;
  final VoidCallback onChanged;

  const _GrantRow({
    required this.grant,
    required this.orgId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat.yMMMd();
    final isActive = grant.status == GrantStatus.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Learner
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grant.learnerDisplayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  grant.inviteEmail,
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _GrantStatusBadge(status: grant.status),
          ),
          // Granted
          Expanded(
            flex: 2,
            child: Text(
              fmt.format(grant.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          // Expires
          Expanded(
            flex: 2,
            child: Text(
              grant.validUntil != null
                  ? fmt.format(grant.validUntil!)
                  : 'Open-ended',
              style: TextStyle(
                fontSize: 12,
                color: grant.isExpired ? Colors.redAccent : Colors.black54,
              ),
            ),
          ),
          // Redeemed
          Expanded(
            flex: 2,
            child: grant.isRedeemed
                ? Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        fmt.format(grant.redeemedAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Not redeemed',
                    style: TextStyle(fontSize: 11, color: Colors.black38),
                  ),
          ),
          // Revoke button
          SizedBox(
            width: 40,
            child: isActive
                ? IconButton(
                    icon: const Icon(Icons.block, size: 16, color: Colors.redAccent),
                    tooltip: 'Revoke grant',
                    onPressed: () =>
                        _showRevokeDialog(context, ref),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showRevokeDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Revoke Grant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revoke the grant for ${grant.inviteEmail}? '
              'This will remove their sponsored access.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(revokeGrantProvider.notifier)
                    .revoke(grant, reasonController.text.trim());
                onChanged();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}

class _GrantStatusBadge extends StatelessWidget {
  final GrantStatus status;
  const _GrantStatusBadge({required this.status});

  Color get _bg => switch (status) {
    GrantStatus.active  => const Color(0xFFE4F3EC),
    GrantStatus.expired => const Color(0xFFFFF4D6),
    GrantStatus.revoked => const Color(0xFFFFE8E8),
  };

  Color get _fg => switch (status) {
    GrantStatus.active  => const Color(0xFF2E7D5B),
    GrantStatus.expired => const Color(0xFFB07600),
    GrantStatus.revoked => const Color(0xFFC43B3B),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _fg,
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyGrantsState extends StatelessWidget {
  const _EmptyGrantsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.card_giftcard_outlined, size: 52, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'No grants yet.',
            style: TextStyle(color: Colors.black45, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            'Use "Add Grants" to sponsor learners.',
            style: TextStyle(color: Colors.black38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Bulk grant dialog ──────────────────────────────────────────────────────────
class _BulkGrantDialog extends ConsumerStatefulWidget {
  final String orgId;
  const _BulkGrantDialog({required this.orgId});

  @override
  ConsumerState<_BulkGrantDialog> createState() => _BulkGrantDialogState();
}

class _BulkGrantDialogState extends ConsumerState<_BulkGrantDialog> {
  final _emailController = TextEditingController();
  DateTime? _validUntil;
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  List<String> get _emails => _emailController.text
      .split(RegExp(r'[\n,;]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _submit() async {
    final emails = _emails;
    if (emails.isEmpty) {
      setState(() => _error = 'Enter at least one email address.');
      return;
    }
    final invalid = emails.where((e) => !e.contains('@')).toList();
    if (invalid.isNotEmpty) {
      setState(() => _error = 'Invalid email(s): ${invalid.join(', ')}');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      final count = await ref.read(createGrantsProvider.notifier).createBulk(
            widget.orgId,
            emails,
            validUntil: _validUntil,
          );
      setState(() {
        _success = '$count grant${count == 1 ? '' : 's'} created!';
        _emailController.clear();
        _validUntil = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _validUntil = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Sponsored Grants',
                      style: TextStyle(
                        fontSize: 18,
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
                'Each email will receive an invitation for a free premium account, '
                'sponsored by your organization.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'alice@example.com\nbob@example.com\n…',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              // Expiry date
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _validUntil != null
                            ? 'Expires: ${DateFormat.yMMMd().format(_validUntil!)}'
                            : 'No expiry (open-ended)',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Spacer(),
                      if (_validUntil != null)
                        GestureDetector(
                          onTap: () =>
                              setState(() => _validUntil = null),
                          child: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Colors.black45,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                AppMessageWidget(message: _error!, type: MessageType.error),
              ],
              if (_success != null) ...[
                const SizedBox(height: 8),
                AppMessageWidget(
                  message: _success!,
                  type: MessageType.success,
                ),
              ],
              const SizedBox(height: 16),
              AppButton(
                label: _isLoading ? 'Creating…' : 'Create Grants',
                backgroundColor: AppColors.copBlue,
                textColor: Colors.white,
                onPressed: _isLoading ? null : _submit,
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
