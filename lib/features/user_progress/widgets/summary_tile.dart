import 'package:flutter/material.dart';

class SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String extra;
  final IconData icon;
  final Color color;
  const SummaryTile({
    super.key,
    required this.label,
    required this.value,
    required this.extra,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0,2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey[700])),
                Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (extra.isNotEmpty) Text(extra, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
              ],
            ),
          )
        ],
      ),
    );
  }
}
