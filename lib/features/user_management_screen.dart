import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_colors.dart';
import '../utils/initials.dart';
import '../widgets/search_input.dart' as shell_search; // avoid name clash if needed
import 'auth/profile_models.dart';
import 'auth/profiles_repository.dart';
// user progress UI and logic are encapsulated in widgets
import 'user_progress/widgets/user_details_view.dart';

class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(profilesListProvider(null));
    final selectedUserId = ref.watch(_selectedUserIdProvider);
    final searchQuery = ref.watch(_userSearchQueryProvider);

    Future<void> refreshUsers() async {
      ref.invalidate(profilesListProvider(null));
      await ref.read(profilesListProvider(null).future);
    }

    return Scaffold(
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent),
                const SizedBox(height: 8),
                const Text('Failed to load users'),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: refreshUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (users) {
          return Row(
            children: [
              // Left panel: list & filters
              Expanded(
                flex: 30,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.faintGrey,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderColor,
                      width: 1,
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: refreshUsers,
                    child: Builder(
                      builder: (context) {
                        final query = searchQuery.trim().toLowerCase();
                        final List<Profile> filtered = query.isEmpty
                            ? users
                            : users
                                .where((p) =>
                                    (p.fullName.toLowerCase()).contains(query) ||
                                    (p.email ?? '').toLowerCase().contains(query))
                                .toList();

                        final items = <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                            child: shell_search.SearchInput(
                              hintText: 'Search users by name or email',
                              initialValue: searchQuery,
                              onChanged: (value) =>
                                  ref.read(_userSearchQueryProvider.notifier).state = value,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                            child: Text(
                              'Showing ${filtered.length} of ${users.length} users',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ];

                        if (filtered.isEmpty) {
                          items.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 48,
                              ),
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
                                    'No users match your search.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        ref.read(_userSearchQueryProvider.notifier).state = '',
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Clear search'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          for (var i = 0; i < filtered.length; i++) {
                            final user = filtered[i];
                            final isSelected = selectedUserId == user.id;
                            items.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  curve: Curves.easeOut,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryColor
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(8),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => ref
                                        .read(_selectedUserIdProvider.notifier)
                                        .state = user.id,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                child: Text(
                                                  computeInitials(user.fullName.isNotEmpty
                                                      ? user.fullName
                                                      : (user.email ?? 'U')),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  user.fullName.isNotEmpty
                                                      ? user.fullName
                                                      : (user.email ?? 'Unnamed User'),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight: FontWeight.w600,
                                                        color: AppColors.darkGrey,
                                                        fontSize: 16,
                                                      ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if ((user.email ?? '').isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.mail_outline,
                                                  size: 16,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    user.email!,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                            if (i != filtered.length - 1) {
                              items.add(const SizedBox(height: 8));
                            }
                          }
                        }

                        items.add(const SizedBox(height: 24));

                        return ListView(
                          padding: EdgeInsets.zero,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: items,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Right panel: placeholder for details
              Expanded(
                flex: 70,
                child: selectedUserId == null
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.faintGrey,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'Select a user to view\ndetails',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      )
                    : UserDetailsView(userId: selectedUserId),
              ),
            ],
          );
        },
      ),
    );
  }

  // initials logic moved to utils/initials.dart
}

final _selectedUserIdProvider = StateProvider<String?>((ref) => null);
final _userSearchQueryProvider = StateProvider<String>((ref) => '');
