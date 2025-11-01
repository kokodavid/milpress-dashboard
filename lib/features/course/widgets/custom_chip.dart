import 'package:flutter/material.dart';

class CustomChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isPrimary;
  
  const CustomChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.isPrimary = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? 
        (isPrimary ? Colors.purple.shade100 : Colors.grey.shade100);
    final txtColor = textColor ?? 
        (isPrimary ? Colors.purple.shade700 : Colors.grey.shade700);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: txtColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
