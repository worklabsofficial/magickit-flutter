import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicFormField
/// category: molecule
/// use_case: Wrapper form field dengan label, helper text, dan error message
/// visual_keywords: form field, label, input field, form, error, helper
/// {@end}
class MagicFormField extends StatelessWidget {
  /// Label yang ditampilkan di atas field.
  final String label;

  /// Widget input di dalamnya (MagicInput, MagicDropdown, dll).
  final Widget child;

  /// Pesan error. Jika tidak null, teks error akan ditampilkan.
  final String? errorText;

  /// Teks bantuan di bawah field.
  final String? helperText;

  /// Tandai field sebagai wajib diisi dengan asterisk (*).
  final bool isRequired;

  const MagicFormField({
    super.key,
    required this.label,
    required this.child,
    this.errorText,
    this.helperText,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final colors = theme.colors;
    final spacing = theme.spacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        RichText(
          text: TextSpan(
            text: label,
            style: theme.typography.label.copyWith(
              color: errorText != null
                  ? colors.error
                  : colors.onBackground.withValues(alpha: 0.75),
            ),
            children: [
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: theme.typography.label.copyWith(color: colors.error),
                ),
            ],
          ),
        ),
        SizedBox(height: spacing.xs),

        // Field
        child,

        // Helper or Error
        if (errorText != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            errorText!,
            style: theme.typography.caption.copyWith(color: colors.error),
          ),
        ] else if (helperText != null) ...[
          SizedBox(height: spacing.xs),
          Text(
            helperText!,
            style: theme.typography.caption.copyWith(
              color: colors.onBackground.withValues(alpha: 0.5),
            ),
          ),
        ],
      ],
    );
  }
}
