import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitSwitchExample extends StatefulWidget {
  const MagicKitSwitchExample({super.key});

  @override
  State<MagicKitSwitchExample> createState() => _MagicKitSwitchExampleState();
}

class _MagicKitSwitchExampleState extends State<MagicKitSwitchExample> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.lg,
      children: [
        MagicSwitch(
          value: _enabled,
          onChanged: (value) => setState(() => _enabled = value),
          label: 'Notifications',
        ),
        MagicSwitch(
          value: false,
          onChanged: (_) {},
          label: 'Disabled',
          enabled: false,
        ),
      ],
    );
  }
}
