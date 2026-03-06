import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicInput
/// category: atom
/// use_case: Text field untuk input data user, form, pencarian
/// visual_keywords: input, text field, form, kolom, isian
/// {@end}
class MagicInput extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool enabled;
  final String? label;
  final String? errorText;
  final int? maxLines;
  final FocusNode? focusNode;
  final bool autofocus;

  const MagicInput({
    super.key,
    this.hint,
    this.controller,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onTap,
    this.enabled = true,
    this.label,
    this.errorText,
    this.maxLines = 1,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final colors = theme.colors;
    final typo = theme.typography;
    final radius = theme.radius;
    final spacing = theme.spacing;

    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onTap: onTap,
      enabled: enabled,
      maxLines: maxLines,
      focusNode: focusNode,
      autofocus: autofocus,
      style: typo.bodyMedium.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        hintStyle: typo.bodyMedium.copyWith(
          color: colors.onSurface.withValues(alpha: 0.4),
        ),
        labelStyle: typo.label.copyWith(
          color: colors.onSurface.withValues(alpha: 0.7),
        ),
        errorStyle: typo.caption.copyWith(color: colors.error),
        filled: true,
        fillColor: enabled ? colors.surface : colors.disabled,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.sm),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.sm),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.sm),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.sm),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.sm),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.sm),
          borderSide: BorderSide(color: colors.disabled),
        ),
      ),
    );
  }
}
