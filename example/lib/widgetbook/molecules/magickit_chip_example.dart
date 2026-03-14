import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitChipExample extends StatefulWidget {
  const MagicKitChipExample({super.key});

  @override
  State<MagicKitChipExample> createState() => _MagicKitChipExampleState();
}

class _MagicKitChipExampleState extends State<MagicKitChipExample> {
  bool _selected = true;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.sm,
      runSpacing: theme.spacing.sm,
      children: [
        MagicChip(
          label: _selected ? 'Selected' : 'Select me',
          selected: _selected,
          onTap: () => setState(() => _selected = !_selected),
        ),
        const MagicChip(label: 'Default'),
        MagicChip(
          label: 'With Avatar',
          avatar: const MagicAvatar(fallbackInitial: 'A', size: MagicAvatarSize.sm),
          onTap: () {},
        ),
        MagicChip(
          label: 'Deletable',
          onDeleted: () {},
          selected: true,
        ),
      ],
    );
  }
}
