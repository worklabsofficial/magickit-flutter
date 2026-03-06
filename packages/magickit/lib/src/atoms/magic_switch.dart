import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicSwitch
/// category: atom
/// use_case: Toggle switch untuk mengaktifkan/menonaktifkan fitur atau pengaturan
/// visual_keywords: switch, toggle, on off, aktifkan, nonaktifkan
/// {@end}
class MagicSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Label teks di sebelah kanan switch.
  final String? label;

  final bool enabled;

  const MagicSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    final sw = Switch(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: theme.colors.primary,
      activeTrackColor: theme.colors.primary.withValues(alpha: 0.4),
      inactiveThumbColor: theme.colors.surface,
      inactiveTrackColor: theme.colors.outline,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (label == null) return sw;

    return GestureDetector(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          sw,
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
