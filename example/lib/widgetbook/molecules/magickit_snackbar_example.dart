import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitSnackbarExample extends StatelessWidget {
  const MagicKitSnackbarExample({super.key});

  void _showSnackbar(BuildContext context, MagicSnackbarVariant variant) {
    MagicSnackbar.show(
      context,
      message: 'This is a ${variant.name} message',
      variant: variant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.sm,
      runSpacing: theme.spacing.sm,
      children: [
        MagicButton(
          label: 'Info',
          variant: MagicButtonVariant.outlined,
          onPressed: () => _showSnackbar(context, MagicSnackbarVariant.info),
        ),
        MagicButton(
          label: 'Success',
          onPressed: () => _showSnackbar(context, MagicSnackbarVariant.success),
        ),
        MagicButton(
          label: 'Warning',
          variant: MagicButtonVariant.secondary,
          onPressed: () => _showSnackbar(context, MagicSnackbarVariant.warning),
        ),
        MagicButton(
          label: 'Error',
          variant: MagicButtonVariant.ghost,
          onPressed: () => _showSnackbar(context, MagicSnackbarVariant.error),
        ),
      ],
    );
  }
}
