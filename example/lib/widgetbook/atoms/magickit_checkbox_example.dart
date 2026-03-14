import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitCheckboxExample extends StatefulWidget {
  const MagicKitCheckboxExample({super.key});

  @override
  State<MagicKitCheckboxExample> createState() => _MagicKitCheckboxExampleState();
}

class _MagicKitCheckboxExampleState extends State<MagicKitCheckboxExample> {
  bool? _checked = true;
  bool? _tristateValue;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.lg,
      runSpacing: theme.spacing.sm,
      children: [
        MagicCheckbox(
          value: _checked,
          onChanged: (value) => setState(() => _checked = value),
          label: 'Remember me',
        ),
        MagicCheckbox(
          value: _tristateValue,
          tristate: true,
          onChanged: (value) => setState(() => _tristateValue = value),
          label: 'Tri-state',
        ),
        MagicCheckbox(
          value: true,
          onChanged: (_) {},
          label: 'Disabled',
          enabled: false,
        ),
      ],
    );
  }
}
