import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final bool completed;
  const StatusChip({super.key, required this.label, required this.completed});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: completed ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: completed ? Colors.green.shade200 : Colors.orange.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: completed ? Colors.green.shade700 : Colors.orange.shade700,
        ),
      ),
    );
  }
}
