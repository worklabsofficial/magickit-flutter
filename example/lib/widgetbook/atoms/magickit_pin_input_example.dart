import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitPinInputExample extends StatefulWidget {
  const MagicKitPinInputExample({super.key});

  @override
  State<MagicKitPinInputExample> createState() =>
      _MagicKitPinInputExampleState();
}

class _MagicKitPinInputExampleState extends State<MagicKitPinInputExample> {
  String _pinValue = '';
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Outlined (Default)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicPinInput(
          length: 6,
          onChanged: (value) => setState(() => _pinValue = value),
          onCompleted: (value) {},
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Filled', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicPinInput.filled(length: 4),
        SizedBox(height: theme.spacing.md),
        const MagicText('Underlined', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicPinInput.underlined(length: 5),
        SizedBox(height: theme.spacing.md),
        const MagicText('Obscured (PIN)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicPinInput(length: 4, obscureText: true),
        SizedBox(height: theme.spacing.md),
        MagicSwitch(
          value: _hasError,
          onChanged: (value) => setState(() => _hasError = value),
          label: 'Error state',
        ),
        SizedBox(height: theme.spacing.sm),
        MagicPinInput(length: 4, hasError: _hasError),
        SizedBox(height: theme.spacing.sm),
        if (_pinValue.isNotEmpty)
          MagicText('Value: $_pinValue', style: MagicTextStyle.caption),
      ],
    );
  }
}
