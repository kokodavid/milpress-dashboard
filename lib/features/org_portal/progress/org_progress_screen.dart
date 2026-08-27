import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../utils/app_colors.dart';
import '../../auth/profile_models.dart';
import '../../auth/profiles_repository.dart';
import '../../user_progress/widgets/user_details_view.dart';
import '../auth/org_session_provider.dart';

// =============================================================================
// Provider: learners belonging to the current session's org
// =============================================================================
final _orgLearnersProvider = FutureProvider.family<List<Profile>, String>(
  (ref, orgId) async {
    final List data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('org_id', orgId)
        .order('created_at', ascending: false);
    return data
        .map((e) => Profile.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  },
);

// Selected learner state
final _selectedLearnerIdProvider = StateProvider<String?>((ref) => null);
final _learnerSearchProvider = StateProvider<String>((ref) => '');

// =============================================================================
// OrgProgressScreen — /org/progress
// Two-pane: learner list (left) + progress detail (right)
// =============================================================================
class OrgProgressScreen extends ConsumerWidget {
  const OrgProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(currentOrgSessionProvider);
    if (session == null) return const Center(child: CircularProgressIndicator());

    final learnersAsync = ref.watch(_orgLearnersProvider(session.orgId));
    final selectedId = ref.watch(_selectedLearnerIdProvider);
    final search = ref.watch(_learnerSearchProvider);

    return Row(
      children: [
        // ── Left: Learner list ──────────────────────────────────────────
        Container(
          width: 300,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
            color: Color(0xFFFAFAFA),
          ),
          child: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search learners…',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) =>
                      ref.read(_learnerSearchProvider.notifier).state = v,
                ),
              ),

              // Count
              learnersAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (learners) {
                  final filtered = _filter(learners, search);
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filtered.length} learner${filtered.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),

              Expanded(
                child: learnersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: $e',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  data: (learners) {
                    final filtered = _filter(learners, search);
                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No learners found.',
                          style: TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final l = filtered[i];
                        final isSelected = l.id == selectedId;
                        return InkWell(
                          onTap: () => ref
                              .read(_selectedLearnerIdProvider.notifier)
                              .state = l.id,
                          child: Container(
                            color: isSelected
                                ? AppColors.primaryColor.withOpacity(0.08)
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFFEEF2FF),
                                  child: Text(
                                    _initials(l),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l.fullName.isNotEmpty
                                            ? l.fullName
                                            : l.email ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (l.email != null)
                                        Text(
                                          l.email!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black38,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: AppColors.primaryColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Right: Progress detail ──────────────────────────────────────
        Expanded(
          child: selectedId == null
              ? const _EmptyProgressState()
              : UserDetailsView(userId: selectedId),
        ),
      ],
    );
  }

  List<Profile> _filter(List<Profile> all, String q) {
    if (q.trim().isEmpty) return all;
    final lq = q.trim().toLowerCase();
    return all.where((p) {
      return (p.fullName.toLowerCase().contains(lq)) ||
          (p.email?.toLowerCase().contains(lq) ?? false);
    }).toList();
  }

  String _initials(Profile p) {
    if (p.fullName.isNotEmpty) {
      final parts =
          p.fullName.trim().split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return (p.email?[0] ?? '?').toUpperCase();
  }
}

class _EmptyProgressState extends StatelessWidget {
  const _EmptyProgressState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_outlined, size: 52, color: Colors.black26),
          SizedBox(height: 12),
          Text(
            'Select a learner to view progress',
            style: TextStyle(color: Colors.black45, fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            'Choose from the list on the left.',
            style: TextStyle(color: Colors.black38, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
