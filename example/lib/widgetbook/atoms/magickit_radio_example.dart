import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitRadioExample extends StatefulWidget {
  const MagicKitRadioExample({super.key});

  @override
  State<MagicKitRadioExample> createState() => _MagicKitRadioExampleState();
}

class _MagicKitRadioExampleState extends State<MagicKitRadioExample> {
  String _value = 'A';

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.lg,
      children: [
        MagicRadio<String>(
          value: 'A',
          groupValue: _value,
          onChanged: (value) => setState(() => _value = value ?? 'A'),
          label: 'Option A',
        ),
        MagicRadio<String>(
          value: 'B',
          groupValue: _value,
          onChanged: (value) => setState(() => _value = value ?? 'B'),
          label: 'Option B',
        ),
        MagicRadio<String>(
          value: 'C',
          groupValue: 'C',
          onChanged: (_) {},
          label: 'Disabled',
          enabled: false,
        ),
      ],
    );
  }
}
