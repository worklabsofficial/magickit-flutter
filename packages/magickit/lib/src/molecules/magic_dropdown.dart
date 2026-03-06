import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

class MagicDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;

  const MagicDropdownItem({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// {@magickit}
/// name: MagicDropdown
/// category: molecule
/// use_case: Selector dropdown untuk memilih satu opsi dari daftar
/// visual_keywords: dropdown, select, pilihan, selector, combobox
/// {@end}
class MagicDropdown<T> extends StatelessWidget {
  final List<MagicDropdownItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool enabled;
  final String? errorText;

  const MagicDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.hint,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final colors = theme.colors;
    final radius = theme.radius;
    final spacing = theme.spacing;
    final typo = theme.typography;

    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius.sm),
      borderSide: BorderSide(color: colors.outline),
    );

    return DropdownButtonFormField<T>(
      initialValue: value,
      onChanged: enabled ? onChanged : null,
      isExpanded: true,
      style: typo.bodyMedium.copyWith(color: colors.onSurface),
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colors.onSurface.withValues(alpha: 0.5),
      ),
      dropdownColor: colors.surface,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 16, color: colors.onSurface),
                    SizedBox(width: spacing.sm),
                  ],
                  Text(item.label),
                ],
              ),
            ),
          )
          .toList(),
      hint: hint != null
          ? Text(
              hint!,
              style: typo.bodyMedium.copyWith(
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            )
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? colors.surface : colors.disabled,
        errorText: errorText,
        errorStyle: typo.caption.copyWith(color: colors.error),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm + 4,
        ),
        border: borderStyle,
        enabledBorder: borderStyle,
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
