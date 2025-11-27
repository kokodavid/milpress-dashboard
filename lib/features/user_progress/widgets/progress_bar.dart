import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  const ProgressBar({super.key, required this.value});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey.shade200,
        color: AppColors.primaryColor,
        minHeight: 10,
      ),
    );
  }
}
