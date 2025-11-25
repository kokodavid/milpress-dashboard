import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/app_colors.dart';
import '../../widgets/search_input.dart';
import '../../widgets/app_button.dart';
import '../auth/admin_profile.dart';
import '../auth/admins_repository.dart';
import '../auth/admin_activity_repository.dart';
import 'widgets/admin_card.dart';
import 'widgets/admin_activity_item.dart';
import 'widgets/admin_edit_dialog.dart';
import 'widgets/settings_card.dart';
import 'utils/settings_helpers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _adminSearch = '';
  String _activityAdminSearch = '';
  DateTime? _activityStartDate;
  DateTime? _activityEndDate;
  // Action filter chips for Admin Activity
  final Set<String> _activityActions = <String>{}; // values: 'created','updated','deleted'

  Future<void> _pickActivityStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityStartDate ?? _activityEndDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _activityStartDate = DateTime(picked.year, picked.month, picked.day);
        // Ensure start <= end
        if (_activityEndDate != null &&
            _activityStartDate!.isAfter(_activityEndDate!)) {
          _activityEndDate = _activityStartDate;
        }
      });
    }
  }

  Future<void> _pickActivityEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _activityEndDate ?? _activityStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _activityEndDate = DateTime(picked.year, picked.month, picked.day);
        // Ensure start <= end
        if (_activityStartDate != null &&
            _activityEndDate!.isBefore(_activityStartDate!)) {
          _activityStartDate = _activityEndDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if current user is a Super Admin
    final userAsync = ref.watch(currentUserProvider);
    final String? _currentUserId = userAsync.maybeWhen(
      data: (u) => u?.id,
      orElse: () => null,
    );
    final isSuperAdmin = _currentUserId == null
        ? false
        : ref
            .watch(adminProfileProvider(_currentUserId))
            .maybeWhen(data: (p) => p?.role == 'super_admin', orElse: () => false);

    final adminsAsync = ref.watch(
      adminProfilesListProvider(_adminSearch.isEmpty ? null : _adminSearch),
    );
    final activityAsync = ref.watch(recentAdminActivityProvider(100));
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 1000;
          final content = [
            SettingsCard(
              title: 'Admins',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchInput(
                    hintText: 'Search',
                    initialValue: _adminSearch,
                    onChanged: (v) => setState(() => _adminSearch = v),
                  ),
                  const SizedBox(height: 8),
                  // Showing count and Add Admin button
                  Builder(
                    builder: (context) {
                      final totalCount = ref
                          .watch(adminProfilesListProvider(null))
                          .maybeWhen(
                            data: (list) => list.length,
                            orElse: () => null,
                          );
                      return Row(
                        children: [
                          Text(
                            'Showing ${adminsAsync.maybeWhen(data: (l) => l.length, orElse: () => 0)} of ${totalCount?.toString() ?? '—'} admins',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          if (isSuperAdmin)
                            SizedBox(
                              width: 160,
                              child: AppButton(
                                label: '+ Add Admin',
                                backgroundColor: AppColors.primaryColor,
                                height: 36,
                                onPressed: _showCreateAdminDialog,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // Admin cards list
                  adminsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Failed to load admins: $err'),
                    ),
                    data: (admins) {
                      if (admins.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 36,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _adminSearch.trim().isEmpty
                                    ? 'No admin profiles found.'
                                    : 'No admins match your search.',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              if (_adminSearch.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      setState(() => _adminSearch = ''),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Clear search'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (var i = 0; i < admins.length; i++) ...[
                            AdminCard(
                              admin: admins[i],
                              onEdit: () => _showEditAdminDialog(admins[i]),
                              canEdit: isSuperAdmin,
                              onDelete: isSuperAdmin
                                  ? () => _confirmAndDeleteAdmin(admins[i])
                                  : null,
                            ),
                            if (i != admins.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            SettingsCard(
              title: 'Admin Activity',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters row
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 320,
                        child: SearchInput(
                          hintText: 'Filter by admin name',
                          initialValue: _activityAdminSearch,
                          onChanged: (v) =>
                              setState(() => _activityAdminSearch = v),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickActivityStartDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(
                          _activityStartDate == null
                              ? 'Start date'
                              : SettingsHelpers.formatDate(_activityStartDate!),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickActivityEndDate,
                        icon: const Icon(Icons.calendar_today_outlined, size: 18),
                        label: Text(
                          _activityEndDate == null
                              ? 'End date'
                              : SettingsHelpers.formatDate(_activityEndDate!),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          foregroundColor: Colors.grey.shade800,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      // Action filter chips
                      FilterChip(
                        label: const Text('Created'),
                        selected: _activityActions.contains('created'),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _activityActions.add('created');
                          } else {
                            _activityActions.remove('created');
                          }
                        }),
                        backgroundColor: Colors.green.shade50,
                        selectedColor: Colors.green.shade100,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      FilterChip(
                        label: const Text('Updated'),
                        selected: _activityActions.contains('updated'),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _activityActions.add('updated');
                          } else {
                            _activityActions.remove('updated');
                          }
                        }),
                        backgroundColor: Colors.amber.shade50,
                        selectedColor: Colors.amber.shade100,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      FilterChip(
                        label: const Text('Deleted'),
                        selected: _activityActions.contains('deleted'),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _activityActions.add('deleted');
                          } else {
                            _activityActions.remove('deleted');
                          }
                        }),
                        backgroundColor: Colors.red.shade50,
                        selectedColor: Colors.red.shade100,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_activityAdminSearch.isNotEmpty ||
                          _activityStartDate != null ||
                          _activityEndDate != null ||
                          _activityActions.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _activityAdminSearch = '';
                            _activityStartDate = null;
                            _activityEndDate = null;
                            _activityActions.clear();
                          }),
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Activity list
                  activityAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Failed to load activity: $err'),
                    ),
                    data: (logs) {
                      // Build filtered list based on date range and admin name
                      final total = logs.length;
                      // Build helper to filter by actor name
                      bool matchActorName(String actorId) {
                        if (_activityAdminSearch.trim().isEmpty) return true;
                        final query = _activityAdminSearch.toLowerCase();
                        final actorAsync = ref.watch(
                          adminProfileProvider(actorId),
                        );
                        final nameOrEmail = actorAsync.maybeWhen(
                          data: (p) => (p?.name?.isNotEmpty == true)
                              ? p!.name!
                              : (p?.email?.isNotEmpty == true
                                    ? p!.email!
                                    : SettingsHelpers.shortId(actorId)),
                          orElse: () => SettingsHelpers.shortId(actorId),
                        );
                        return nameOrEmail.toLowerCase().contains(query);
                      }

                      bool matchDate(DateTime dt) {
                        if (_activityStartDate != null) {
                          final start = DateTime(
                            _activityStartDate!.year,
                            _activityStartDate!.month,
                            _activityStartDate!.day,
                          );
                          if (dt.isBefore(start)) return false;
                        }
                        if (_activityEndDate != null) {
                          final end = DateTime(
                            _activityEndDate!.year,
                            _activityEndDate!.month,
                            _activityEndDate!.day,
                            23,
                            59,
                            59,
                            999,
                          );
                          if (dt.isAfter(end)) return false;
                        }
                        return true;
                      }

                      final filtered = [
                        for (final a in logs)
                          if (matchDate(a.createdAt) &&
                              matchActorName(a.actorId) &&
                              (() {
                                if (_activityActions.isEmpty) return true;
                                final act = a.action.toLowerCase();
                                return _activityActions.any((s) => act.contains(s));
                              }()) )
                            a,
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'Showing ${filtered.length} of $total activities',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                          if (logs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No recent admin activity'),
                            )
                          else if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No activity matches your filters'),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                return AdminActivityItem(
                                  activity: filtered[index],
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              // Increase max width so the Admin Activity panel can utilize more of the screen
              constraints: const BoxConstraints(maxWidth: 1400),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Narrower Admins panel
                        SizedBox(width: 360, child: content[0]),
                        const SizedBox(width: 16),
                        // Wider Activity panel takes remaining space
                        Expanded(child: content[1]),
                      ],
                    )
                  : Column(
                      children: [
                        for (final e in content) ...[
                          e,
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  // Dialogs and CRUD handlers
  void _showCreateAdminDialog() {
    showDialog(
      context: context,
      builder: (context) => AdminEditDialog(
        onSubmit: (name, email, role, isActive) async {
          final result = await ref
              .read(createAdminProvider.notifier)
              .create(name: name, email: email, role: role, isActive: isActive);
          ref.invalidate(adminProfilesListProvider);
          if (result != null) {
            final temp = result.tempPassword;
            final id = result.profile.id;
            if (temp != null && temp.isNotEmpty) {
              // store temp password for display on the admin card
              ref.read(tempAdminPasswordsProvider.notifier).update((state) {
                final next = Map<String, String>.from(state);
                next[id] = temp;
                return next;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Admin created. Temporary password: $temp'),
                  ),
                );
              }
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Admin created.'),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditAdminDialog(AdminProfile admin) {
    showDialog(
      context: context,
      builder: (context) => AdminEditDialog(
        existing: admin,
        onSubmit: (name, email, role, isActive) async {
          await ref
              .read(updateAdminProvider.notifier)
              .update(
                admin.id,
                name: name,
                email: email,
                role: role,
                isActive: isActive,
              );
          // Log activity
          await ref
              .read(adminActivityRepositoryProvider)
              .log(
                action: 'admin_updated',
                targetType: 'admin',
                targetId: admin.id,
                details: {
                  'name': name,
                  'email': email,
                  'role': role,
                  'is_active': isActive,
                },
              );
          ref.invalidate(adminProfilesListProvider);
        },
      ),
    );
  }

  Future<void> _confirmAndDeleteAdmin(AdminProfile admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Text(
                        'Delete Admin',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Body
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Are you sure you want to delete this admin?',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      // Admin preview card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryColor,
                              child: const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    admin.name?.isNotEmpty == true ? admin.name! : (admin.email ?? 'Admin'),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (admin.email != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      admin.email!,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Warning banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorLightShade,
                          border: Border.all(color: AppColors.errorColor.withOpacity(0.4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.errorColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'This action cannot be undone',
                                    style: TextStyle(
                                      color: AppColors.errorColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'This admin\'s account and profile will also be permanently deleted.',
                                    style: TextStyle(color: AppColors.errorColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Footer actions
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete Admin'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(deleteAdminProvider.notifier).delete(admin.id);
      // Clear temp password if present
      ref.read(tempAdminPasswordsProvider.notifier).update((state) {
        final next = Map<String, String>.from(state);
        next.remove(admin.id);
        return next;
      });
      ref.invalidate(adminProfilesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin ${admin.name ?? admin.email ?? ''} deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete admin: $e')),
        );
      }
    }
  }
}
