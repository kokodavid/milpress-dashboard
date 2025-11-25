import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/app_colors.dart';
import '../../auth/admin_profile.dart';
import '../../auth/admins_repository.dart';

class AdminCard extends ConsumerWidget {
  final AdminProfile admin;
  final VoidCallback onEdit;
  final bool canEdit;
  final VoidCallback? onDelete;

  const AdminCard({
    super.key,
    required this.admin,
    required this.onEdit,
    this.canEdit = true,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = formatRole(admin.role);
    final isActive = admin.isActive == true;
    final lastLogin = admin.lastLogin != null ? _formatDate(admin.lastLogin!) : '—';
    final tempMap = ref.watch(tempAdminPasswordsProvider);
    final tempPassword = tempMap[admin.id];
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Edit (top right)
            Row(
              children: [
                Expanded(
                  child: Text(
                    admin.name ?? '(No Name)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey,
                          fontSize: 16,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canEdit) ...[
                  IconButton(
                    tooltip: 'Edit Admin',
                    icon: Image.asset(
                      'assets/edit_pencil.png',
                      width: 20,
                      height: 20,
                    ),
                    onPressed: onEdit,
                  ),
                  if (onDelete != null)
                    IconButton(
                      tooltip: 'Delete Admin',
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Email (no icon)
            Text(
              admin.email ?? '—',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Meta chips row: Role, Status, Last Login
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(isActive: isActive),
                _RoleChip(role: role, admin: admin),
                // Plain info chip without icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Last Login: $lastLogin',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (canEdit && tempPassword != null && tempPassword.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF7E09B)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_outlined, size: 18, color: Color(0xFF8A6D3B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Temporary password: $tempPassword',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A6D3B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy password',
                      icon: const Icon(Icons.copy, size: 18, color: Color(0xFF8A6D3B)),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: tempPassword));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Temporary password copied')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Dismiss',
                      icon: const Icon(Icons.close, size: 18, color: Color(0xFF8A6D3B)),
                      onPressed: () {
                        ref.read(tempAdminPasswordsProvider.notifier).update((state) {
                          final next = Map<String, String>.from(state);
                          next.remove(admin.id);
                          return next;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  final AdminProfile admin;

  const _RoleChip({required this.role, required this.admin});

  @override
  Widget build(BuildContext context) {
    final isSuper = admin.role == 'super_admin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuper ? Colors.deepPurple.shade100 : Colors.blue.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: isSuper ? Colors.deepPurple.shade700 : Colors.blue.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
