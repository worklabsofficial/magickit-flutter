import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitFormFieldExample extends StatelessWidget {
  const MagicKitFormFieldExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      children: [
        MagicFormField(
          label: 'Full name',
          isRequired: true,
          helperText: 'Use your real name',
          child: MagicInput(
            hint: 'Type here',
            onChanged: (_) {},
          ),
        ),
        SizedBox(height: theme.spacing.md),
        MagicFormField(
          label: 'Username',
          errorText: 'Username already taken',
          child: MagicInput(
            hint: 'e.g. magickit',
            onChanged: (_) {},
          ),
        ),
      ],
    );
  }
}
