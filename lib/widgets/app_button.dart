import 'package:flutter/material.dart';

/// A reusable app button that supports filled or outlined styles,
/// customizable background and text colors, and a consistent height.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.outlined = false,
    this.height = 48,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final bool outlined;
  final double height;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final br = borderRadius ?? BorderRadius.circular(8);

    if (outlined) {
      final Color sideColor = backgroundColor ?? theme.colorScheme.primary;
      final Color fg = textColor ?? sideColor;
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: fg,
            side: BorderSide(color: sideColor),
            shape: RoundedRectangleBorder(borderRadius: br),
          ),
          child: Text(label),
        ),
      );
    }

    final Color bg = backgroundColor ?? theme.colorScheme.primary;
    final Color fg = textColor ?? theme.colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(borderRadius: br),
        ),
        child: Text(label),
      ),
    );
  }
}
