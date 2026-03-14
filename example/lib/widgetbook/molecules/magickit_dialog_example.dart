import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitDialogExample extends StatelessWidget {
  const MagicKitDialogExample({super.key});

  void _showDialog(BuildContext context) {
    MagicDialog.show(
      context,
      title: 'Confirm Action',
      content: const Text('Are you sure you want to proceed?'),
      actions: [
        MagicButton(
          label: 'Cancel',
          variant: MagicButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        MagicButton(
          label: 'Yes, continue',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Row(
      children: [
        MagicButton(
          label: 'Open dialog',
          onPressed: () => _showDialog(context),
        ),
        SizedBox(width: theme.spacing.sm),
        MagicButton(
          label: 'Confirm dialog',
          variant: MagicButtonVariant.outlined,
          onPressed: () async {
            await MagicDialog.confirm(
              context,
              title: 'Delete file',
              message: 'This action cannot be undone.',
              confirmLabel: 'Delete',
              confirmVariant: MagicButtonVariant.secondary,
            );
          },
        ),
      ],
    );
  }
}
