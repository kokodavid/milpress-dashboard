import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../utils/app_colors.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_form_field.dart';
import '../../../widgets/app_message_widget.dart';
import '../../organizations/organization_models.dart';
import '../../organizations/organization_repository.dart';
import '../../subscriptions/subscription_enums.dart';
import '../auth/org_session_provider.dart';

// =============================================================================
// OrgMembersScreen — /org/members
// =============================================================================
class OrgMembersScreen extends ConsumerWidget {
  const OrgMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentOrgSessionProvider);
    if (session == null) return const Center(child: CircularProgressIndicator());

    final membersAsync = ref.watch(orgMembersProvider(session.orgId));
    final org = session.org;

    void refresh() => ref.invalidate(orgMembersProvider(session.orgId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        org.seatLimit != null
                            ? '${org.seatsUsed} of ${org.seatLimit} seats used'
                            : 'Unlimited seats',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Seat limit badge
                if (org.seatLimit != null)
                  _SeatPill(used: org.seatsUsed, limit: org.seatLimit!),
                const SizedBox(width: 12),
                // Invite button
                ElevatedButton.icon(
                  onPressed: org.atSeatLimit
                      ? null
                      : () => _showInviteDialog(context, ref, session),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Invite Members'),
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
          if (org.atSeatLimit)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: AppMessageWidget(
                message:
                    'You\'ve reached your seat limit (${org.seatLimit}). Upgrade your plan to invite more members.',
                type: MessageType.info,
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1),

          // Table
          Expanded(
            child: membersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (members) => _MembersTable(
                members: members,
                session: session,
                onChanged: refresh,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    OrgSession session,
  ) {
    showDialog(
      context: context,
      builder: (_) => _InviteDialog(session: session),
    ).then((_) => ref.invalidate(orgMembersProvider(session.orgId)));
  }
}

// ── Seat pill ──────────────────────────────────────────────────────────────────
class _SeatPill extends StatelessWidget {
  final int used;
  final int limit;
  const _SeatPill({required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final fraction = used / limit;
    final color = fraction >= 1
        ? Colors.red
        : fraction >= 0.8
            ? const Color(0xFFB07600)
            : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$used / $limit seats',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Members table ──────────────────────────────────────────────────────────────
class _MembersTable extends ConsumerWidget {
  final List<OrgMember> members;
  final OrgSession session;
  final VoidCallback onChanged;

  const _MembersTable({
    required this.members,
    required this.session,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active  = members.where((m) => m.status == MemberStatus.active).toList();
    final pending = members.where((m) => m.status == MemberStatus.pending).toList();
    final removed = members.where((m) => m.status == MemberStatus.removed).toList();

    if (members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'No members yet.',
              style: TextStyle(color: Colors.black45, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Use the Invite Members button to add your team.',
              style: TextStyle(color: Colors.black38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active.isNotEmpty) ...[
            _SectionHeader(label: 'Active (${active.length})'),
            _MemberList(
              members: active,
              session: session,
              onChanged: onChanged,
            ),
          ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(label: 'Pending Invites (${pending.length})'),
            _MemberList(
              members: pending,
              session: session,
              onChanged: onChanged,
            ),
          ],
          if (removed.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionHeader(label: 'Removed (${removed.length})'),
            _MemberList(
              members: removed,
              session: session,
              onChanged: onChanged,
              showActions: false,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MemberList extends ConsumerWidget {
  final List<OrgMember> members;
  final OrgSession session;
  final VoidCallback onChanged;
  final bool showActions;

  const _MemberList({
    required this.members,
    required this.session,
    required this.onChanged,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: members.asMap().entries.map((e) {
          final isLast = e.key == members.length - 1;
          return Column(
            children: [
              _MemberTile(
                member: e.value,
                session: session,
                onChanged: onChanged,
                showActions: showActions,
              ),
              if (!isLast)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final OrgMember member;
  final OrgSession session;
  final VoidCallback onChanged;
  final bool showActions;

  const _MemberTile({
    required this.member,
    required this.session,
    required this.onChanged,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = member.status == MemberStatus.pending;
    final isCurrentUser = member.userId == session.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEEF2FF),
            child: Text(
              _initials(member.displayName),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  member.inviteEmail,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                if (member.joinedAt != null)
                  Text(
                    'Joined ${DateFormat.yMMMd().format(member.joinedAt!)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  )
                else if (isPending)
                  Text(
                    'Invited ${DateFormat.yMMMd().format(member.invitedAt)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black38),
                  ),
              ],
            ),
          ),

          // Role badge
          _RoleBadge(role: member.role),
          const SizedBox(width: 12),

          // Status badge
          _StatusBadge(status: member.status),

          // Actions menu
          if (showActions && !isCurrentUser) ...[
            const SizedBox(width: 8),
            _MemberActionsMenu(
              member: member,
              session: session,
              onChanged: onChanged,
            ),
          ],
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

class _RoleBadge extends StatelessWidget {
  final MemberRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == MemberRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFF3E8FF) : const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAdmin ? const Color(0xFF7C3AED) : Colors.black54,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MemberStatus status;
  const _StatusBadge({required this.status});

  Color get _bg => switch (status) {
    MemberStatus.active  => const Color(0xFFE4F3EC),
    MemberStatus.pending => const Color(0xFFFFF4D6),
    MemberStatus.removed => const Color(0xFFFFE8E8),
  };

  Color get _fg => switch (status) {
    MemberStatus.active  => const Color(0xFF2E7D5B),
    MemberStatus.pending => const Color(0xFFB07600),
    MemberStatus.removed => const Color(0xFFC43B3B),
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

// ── Actions popup menu ─────────────────────────────────────────────────────────
class _MemberActionsMenu extends ConsumerWidget {
  final OrgMember member;
  final OrgSession session;
  final VoidCallback onChanged;

  const _MemberActionsMenu({
    required this.member,
    required this.session,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.black45),
      itemBuilder: (_) => [
        if (member.role == MemberRole.member)
          const PopupMenuItem(
            value: 'make_admin',
            child: Text('Make Admin'),
          ),
        if (member.role == MemberRole.admin)
          const PopupMenuItem(
            value: 'make_member',
            child: Text('Make Member'),
          ),
        const PopupMenuItem(
          value: 'remove',
          child: Text('Remove', style: TextStyle(color: Colors.red)),
        ),
      ],
      onSelected: (action) async {
        final repo = ref.read(organizationRepositoryProvider);
        try {
          if (action == 'make_admin') {
            await repo.updateMember(member.id, role: MemberRole.admin);
          } else if (action == 'make_member') {
            await repo.updateMember(member.id, role: MemberRole.member);
          } else if (action == 'remove') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Remove Member'),
                content: Text(
                  'Remove ${member.displayName} from your organization?'
                  ' They will lose access immediately.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await repo.updateMember(
                member.id,
                status: MemberStatus.removed,
              );
            }
          }
          onChanged();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
    );
  }
}

// ── Invite dialog ──────────────────────────────────────────────────────────────
class _InviteDialog extends ConsumerStatefulWidget {
  final OrgSession session;
  const _InviteDialog({required this.session});

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  final _emailController = TextEditingController();
  MemberRole _role = MemberRole.member;
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

  Future<void> _invite() async {
    final emails = _emails;
    if (emails.isEmpty) {
      setState(() => _error = 'Enter at least one email address.');
      return;
    }
    final invalid = emails.where((e) => !e.contains('@')).toList();
    if (invalid.isNotEmpty) {
      setState(
        () => _error = 'Invalid email(s): ${invalid.join(', ')}',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final inviter = ref.read(inviteMembersProvider.notifier);
      await inviter.invite(
        widget.session.orgId,
        emails,
        role: _role,
      );
      setState(() {
        _success = '${emails.length} invite${emails.length == 1 ? '' : 's'} sent!';
        _emailController.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to send invites: $e';
        _isLoading = false;
      });
    }
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
                      'Invite Members',
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
                'Enter one or more email addresses, separated by commas or new lines.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'alice@example.com\nbob@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Role:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('Member'),
                    selected: _role == MemberRole.member,
                    onSelected: (_) =>
                        setState(() => _role = MemberRole.member),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Admin'),
                    selected: _role == MemberRole.admin,
                    onSelected: (_) =>
                        setState(() => _role = MemberRole.admin),
                  ),
                ],
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
              AppButton(
                label: _isLoading ? 'Sending…' : 'Send Invites',
                backgroundColor: AppColors.copBlue,
                textColor: Colors.white,
                onPressed: _isLoading ? null : _invite,
                height: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
