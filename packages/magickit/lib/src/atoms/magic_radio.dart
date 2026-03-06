import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicRadio
/// category: atom
/// use_case: Radio button untuk single-select dari beberapa pilihan
/// visual_keywords: radio, single select, pilihan tunggal, option
/// {@end}
class MagicRadio<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;

  /// Label teks di sebelah kanan radio.
  final String? label;

  final bool enabled;

  const MagicRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final isSelected = value == groupValue;

    Widget indicator = _RadioIndicator(
      isSelected: isSelected,
      enabled: enabled,
      theme: theme,
      onTap: enabled ? () => onChanged(value) : null,
    );

    if (label == null) return indicator;

    return GestureDetector(
      onTap: enabled ? () => onChanged(value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          SizedBox(width: theme.spacing.xs),
          Flexible(
            child: Text(
              label!,
              style: theme.typography.bodyMedium.copyWith(
                color: enabled
                    ? theme.colors.onBackground
                    : theme.colors.disabledForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool isSelected;
  final bool enabled;
  final MagicTheme theme;
  final VoidCallback? onTap;

  const _RadioIndicator({
    required this.isSelected,
    required this.enabled,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor =
        enabled ? theme.colors.primary : theme.colors.disabledForeground;
    final borderColor = isSelected ? activeColor : theme.colors.outline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: isSelected
            ? Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              )
            : null,
      ),
    );
  }
}
