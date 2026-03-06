import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicCheckbox
/// category: atom
/// use_case: Checkbox untuk multi-select, persetujuan, toggle item
/// visual_keywords: checkbox, checklist, pilihan, centang, multi-select
/// {@end}
class MagicCheckbox extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;

  /// Label teks di sebelah kanan checkbox.
  final String? label;

  /// Aktifkan tristate (null, true, false).
  final bool tristate;

  final bool enabled;

  const MagicCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.tristate = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    final checkbox = Checkbox(
      value: value,
      onChanged: enabled ? onChanged : null,
      tristate: tristate,
      activeColor: theme.colors.primary,
      checkColor: theme.colors.onPrimary,
      side: BorderSide(color: theme.colors.outline, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radius.xs),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (label == null) return checkbox;

    return GestureDetector(
      onTap: enabled
          ? () => onChanged(tristate ? _nextTristate(value) : !(value ?? false))
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          checkbox,
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

  bool? _nextTristate(bool? current) => switch (current) {
        null => false,
        false => true,
        true => null,
      };
}
