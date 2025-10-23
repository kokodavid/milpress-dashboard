import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milpress_dashboard/features/auth/admin_profile.dart';

class CurrentUserChip extends ConsumerWidget {
  const CurrentUserChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return _ChipShell(
            avatar: _SquareAvatar(
              size: 36,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: 'Admin User',
            subtitle: 'Admin',
          );
        }
        final profileAsync = ref.watch(adminProfileProvider(user.id));
        return profileAsync.when(
          data: (profile) {
            final name =
                profile?.name ?? (user.email?.split('@').first ?? 'Admin User');
            final initials = computeInitials(profile?.name ?? name);
            final role = formatRole(profile?.role);
            return _ChipShell(
              avatar: _SquareAvatar(
                size: 36,
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: name,
              subtitle: role,
            );
          },
          loading: () => _ChipShell(
            avatar: _SquareAvatar(
              size: 32,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: 'Loading…',
            subtitle: '',
          ),
          error: (_, __) => _ChipShell(
            avatar: _SquareAvatar(
              size: 32,
              child: Icon(
                Icons.error_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: 'Admin User',
            subtitle: 'Admin',
          ),
        );
      },
      loading: () => _ChipShell(
        avatar: _SquareAvatar(
          size: 32,
          child: Icon(
            Icons.person,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: 'Loading…',
        subtitle: '',
      ),
      error: (_, __) => _ChipShell(
        avatar: _SquareAvatar(
          size: 32,
          child: Icon(
            Icons.error_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: 'Admin User',
        subtitle: 'Admin',
      ),
    );
  }
}

class _ChipShell extends StatelessWidget {
  const _ChipShell({
    required this.avatar,
    required this.title,
    required this.subtitle,
  });
  final Widget avatar;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SquareAvatar extends StatelessWidget {
  const _SquareAvatar({required this.child, this.size = 32});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
