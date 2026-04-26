import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../assessment_v2/models/assessment_v2_progress_model.dart';
import 'error_box.dart';
import 'status_chip.dart';

class AssignmentProgressList extends StatelessWidget {
  final AsyncValue<List<AssessmentV2Progress>> assignmentProgressAsync;
  final String statusFilter; // 'all' | 'in_progress' | 'completed'

  const AssignmentProgressList({
    super.key,
    required this.assignmentProgressAsync,
    this.statusFilter = 'all',
  });

  @override
  Widget build(BuildContext context) {
    return assignmentProgressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorBox(message: 'Failed to load assignment progress: $e'),
      data: (assignments) {
        final filtered = assignments.where((a) {
          if (statusFilter == 'completed') return a.isPassed;
          if (statusFilter == 'in_progress') return !a.isPassed;
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              'No assignment progress found.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final ap = filtered[index];
            return _AssignmentRow(ap: ap);
          },
        );
      },
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final AssessmentV2Progress ap;
  const _AssignmentRow({required this.ap});

  @override
  Widget build(BuildContext context) {
    final isPassed = ap.isPassed;
    final hasScore = ap.score != null && ap.maxScore != null && ap.maxScore! > 0;
    final scoreLabel = hasScore
        ? '${ap.score}/${ap.maxScore}'
        : (ap.score != null ? '${ap.score}' : null);
    final pctLabel = hasScore
        ? '${(ap.scorePercent * 100).round()}%'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPassed ? const Color(0xFF10B981) : const Color(0xFFE85D04),
            ),
          ),
          const SizedBox(width: 12),

          // Sublevel ID (truncated) — real name would need a sublevel lookup provider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sublevel ${ap.sublevelId.substring(0, 8)}…',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (ap.attempts > 0)
                  Text(
                    '${ap.attempts} attempt${ap.attempts == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Score badge
          if (scoreLabel != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pctLabel != null ? '$scoreLabel ($pctLabel)' : scoreLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ),
            const SizedBox(width: 8),
          ],

          StatusChip(
            label: isPassed ? 'Passed' : 'Failed',
            completed: isPassed,
          ),
        ],
      ),
    );
  }
}
