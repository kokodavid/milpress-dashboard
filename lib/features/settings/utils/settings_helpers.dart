import 'package:flutter/material.dart';
import '../../auth/admin_activity_repository.dart';

class SettingsHelpers {
  SettingsHelpers._();

  static String friendlyText(String raw) {
    if (raw.isEmpty) return raw;
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static IconData actionIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains('created')) return Icons.add_circle_outline;
    if (a.contains('updated')) return Icons.edit_outlined;
    if (a.contains('deleted')) return Icons.delete_outline;
    return Icons.history;
  }

  static Color actionColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('created')) return Colors.green.shade600;
    if (a.contains('updated')) return Colors.amber.shade800;
    if (a.contains('deleted')) return Colors.red.shade600;
    return Colors.blueGrey;
  }

  static String shortId(String id) => id.length > 6 ? id.substring(0, 6) : id;

  static String targetDisplay(AdminActivity a) {
    final type = a.targetType ?? '';
    final d = a.details ?? const {};
    String label = '';
    
    if (type == 'course') {
      final t = (d['title'] as String?)?.trim();
      if (t != null && t.isNotEmpty) label = 'course "$t"';
    } else if (type == 'module') {
      final desc = (d['description'] as String?)?.trim();
      final pos = d['position'];
      if (desc != null && desc.isNotEmpty) {
        label = 'module "$desc"';
      } else if (pos != null) {
        label = 'module #$pos';
      } else {
        label = 'module';
      }
    } else if (type == 'lesson') {
      final title = (d['title'] as String?)?.trim();
      final pos = d['position'];
      if (title != null && title.isNotEmpty) {
        label = 'lesson "$title"';
      } else if (pos != null) {
        label = 'lesson #$pos';
      } else {
        label = 'lesson';
      }
    } else if (type == 'lesson_quiz') {
      final stage = (d['stage'] as String?)?.trim();
      final qtype = (d['question_type'] as String?)?.trim();
      if (stage != null && stage.isNotEmpty && qtype != null && qtype.isNotEmpty) {
        label = 'quiz [$stage/$qtype]';
      } else if (qtype != null && qtype.isNotEmpty) {
        label = 'quiz ($qtype)';
      } else {
        label = 'quiz';
      }
    } else if (type == 'admin') {
      final n = (d['name'] as String?)?.trim();
      if (n != null && n.isNotEmpty) label = 'admin "$n"';
    }
    
    if (label.isEmpty && type.isNotEmpty) {
      label = type + (a.targetId != null ? '(${shortId(a.targetId!)})' : '');
    }
    return label;
  }

  static String formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static String ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return '${d.inSeconds}s ago';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
