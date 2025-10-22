import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milpress_dashboard/utils/app_colors.dart';

enum AppTextFieldStyle { outline, card }

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.label,
    this.validator,
    this.onSaved,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.initialValue,
    this.controller,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.decoration,
    this.enabled,
    this.autofillHints,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onFieldSubmitted,
    this.onTap,
    this.readOnly = false,
    this.style = AppTextFieldStyle.outline,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.showLabel = true,
  });

  final String label;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? initialValue;
  final TextEditingController? controller;
  final int maxLines;
  final int? minLines;
  final bool obscureText;
  final InputDecoration? decoration;
  final bool? enabled;
  final Iterable<String>? autofillHints;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final bool readOnly;
  final AppTextFieldStyle style;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final InputDecoration defaultOutline = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
    );

    final InputDecoration defaultCard = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.6),
      ),
    );

    final baseDecoration = decoration ?? (style == AppTextFieldStyle.card ? defaultCard : defaultOutline);
    final effectiveDecoration = baseDecoration.copyWith(
      // Do NOT put the label inside the field; render it separately above.
      hintText: baseDecoration.hintText ?? hintText,
      prefixIcon: baseDecoration.prefixIcon ?? prefixIcon,
      suffixIcon: baseDecoration.suffixIcon ?? suffixIcon,
    );

    final field = TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: obscureText ? 1 : maxLines,
      minLines: obscureText ? 1 : minLines,
      obscureText: obscureText,
      cursorColor: AppColors.copBlue,
      decoration: effectiveDecoration,
      enabled: enabled,
      autofillHints: autofillHints,
      focusNode: focusNode,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      readOnly: readOnly,
    );

    if (!showLabel) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        field,
      ],
    );
  }
}
