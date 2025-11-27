import 'package:flutter/material.dart';

class PercentageLabel extends StatelessWidget {
  final double percent; // 0..1
  const PercentageLabel({super.key, required this.percent});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${(percent * 100).round()}%',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
        ),
      ],
    );
  }
}
