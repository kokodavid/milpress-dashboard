import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/app_colors.dart';
import '../../auth/admin_activity_repository.dart';
import '../../auth/admin_profile.dart';
import '../utils/settings_helpers.dart';

class AdminActivityItem extends ConsumerWidget {
  final AdminActivity activity;

  const AdminActivityItem({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final when = SettingsHelpers.ago(activity.createdAt);
    final actionLabel = SettingsHelpers.friendlyText(activity.action);
    final icon = SettingsHelpers.actionIcon(activity.action);
    final color = SettingsHelpers.actionColor(activity.action);
    
    final actorAsync = ref.watch(adminProfileProvider(activity.actorId));
    final actorName = actorAsync.maybeWhen(
      data: (p) => (p?.name?.isNotEmpty == true)
          ? p!.name!
          : (p?.email?.isNotEmpty == true ? p!.email! : SettingsHelpers.shortId(activity.actorId)),
      orElse: () => SettingsHelpers.shortId(activity.actorId),
    );
    
    final target = SettingsHelpers.targetDisplay(activity);
    final details = activity.details;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Headline: Action + target + time
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (target.isNotEmpty)
                          Text('on $target', style: const TextStyle(color: Colors.black54)),
                        const Text('•', style: TextStyle(color: Colors.black26)),
                        Text(when, style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Actor
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text('by $actorName', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    if (details != null && details.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailsChips(
                        details: details,
                        action: activity.action,
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing menu (copy ids)
              PopupMenuButton<String>(
                itemBuilder: (context) => [
                  if (activity.targetId != null)
                    const PopupMenuItem(
                      value: 'copyTarget',
                      child: Text('Copy target ID'),
                    ),
                  const PopupMenuItem(
                    value: 'copyAction',
                    child: Text('Copy action'),
                  ),
                ],
                onSelected: (v) async {
                  if (v == 'copyTarget' && activity.targetId != null) {
                    await Clipboard.setData(ClipboardData(text: activity.targetId!));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Target ID copied')),
                      );
                    }
                  }
                  if (v == 'copyAction') {
                    await Clipboard.setData(ClipboardData(text: activity.action));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action copied')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailsChips extends StatelessWidget {
  final Map<String, dynamic> details;
  final String action;

  const _DetailsChips({
    required this.details,
    required this.action,
  });

  String _prettyKey(String k) {
    return k
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _valueToString(dynamic v) {
    if (v is bool) return v ? 'Yes' : 'No';
    return '$v';
  }

  /// Fields to exclude from display as they're metadata or identifiers
  static const _metadataFields = {
    'id',
    'course_id',
    'module_id',
    'lesson_id',
    'created_at',
    'updated_at',
    'actor_id',
  };

  /// Extract changed fields for update actions
  /// Returns a map of field name to (oldValue, newValue) pairs
  Map<String, (dynamic, dynamic)> _getChangedFields() {
    final changes = <String, (dynamic, dynamic)>{};
    
    // Group old/new pairs
    final processedKeys = <String>{};
    
    for (final entry in details.entries) {
      final key = entry.key;
      if (processedKeys.contains(key)) continue;
      
      // Check for _old and _new suffix pattern
      if (key.endsWith('_old')) {
        final fieldName = key.substring(0, key.length - 4);
        final newKey = '${fieldName}_new';
        if (details.containsKey(newKey)) {
          changes[fieldName] = (entry.value, details[newKey]);
          processedKeys.add(key);
          processedKeys.add(newKey);
        }
      }
    }
    
    return changes;
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = action.toLowerCase().contains('updated');
    
    if (isUpdate) {
      // For updates, show old → new format
      final changes = _getChangedFields();
      
      if (changes.isEmpty) {
        return const SizedBox.shrink();
      }
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in changes.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_prettyKey(entry.key)}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          _valueToString(entry.value.$1),
                          style: TextStyle(
                            color: Colors.red.shade700,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                        Text(
                          _valueToString(entry.value.$2),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      // For create/delete, show chips as before
      final relevantDetails = Map.fromEntries(
        details.entries.where((e) => !_metadataFields.contains(e.key)),
      );
      
      if (relevantDetails.isEmpty) {
        return const SizedBox.shrink();
      }
      
      final entries = relevantDetails.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in entries)
            Chip(
              side: BorderSide(color: AppColors.borderColor),
              backgroundColor: Colors.white,
              label: Text('${_prettyKey(e.key)}: ${_valueToString(e.value)}'),
            ),
        ],
      );
    }
  }
}
