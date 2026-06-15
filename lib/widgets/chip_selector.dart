import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Chip-based selector — clean, modern replacement for dropdown fields.
class ChipSelector<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  const ChipSelector({
    super.key,
    required this.label,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values.map((value) {
            final isSelected = value == selected;
            return GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor.withOpacity(0.12)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.grey.shade300,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  labelBuilder(value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryColor : Colors.grey[800],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
