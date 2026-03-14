import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitButtonExample extends StatefulWidget {
  const MagicKitButtonExample({super.key});

  @override
  State<MagicKitButtonExample> createState() => _MagicKitButtonExampleState();
}

class _MagicKitButtonExampleState extends State<MagicKitButtonExample> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: theme.spacing.sm,
          runSpacing: theme.spacing.sm,
          children: [
            MagicButton(label: 'Primary', onPressed: () {}),
            MagicButton(
              label: 'Secondary',
              onPressed: () {},
              variant: MagicButtonVariant.secondary,
            ),
            MagicButton(
              label: 'Outlined',
              onPressed: () {},
              variant: MagicButtonVariant.outlined,
            ),
            MagicButton(
              label: 'Ghost',
              onPressed: () {},
              variant: MagicButtonVariant.ghost,
            ),
            const MagicButton(label: 'Disabled', onPressed: null),
            MagicButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: _isLoading,
            ),
            MagicButton(
              label: 'With Icon',
              onPressed: () {},
              icon: Icons.add,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.sm),
        Row(
          children: [
            MagicButton(
              label: 'Small',
              onPressed: () {},
              size: MagicButtonSize.small,
            ),
            SizedBox(width: theme.spacing.sm),
            MagicButton(label: 'Medium', onPressed: () {}),
            SizedBox(width: theme.spacing.sm),
            MagicButton(
              label: 'Large',
              onPressed: () {},
              size: MagicButtonSize.large,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.sm),
        MagicButton(
          label: _isLoading ? 'Stop Loading' : 'Toggle Loading',
          onPressed: () => setState(() => _isLoading = !_isLoading),
          variant: MagicButtonVariant.outlined,
        ),
      ],
    );
  }
}
