import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitBottomSheetExample extends StatelessWidget {
  const MagicKitBottomSheetExample({super.key});

  void _showBottomSheet(BuildContext context) {
    MagicBottomSheet.show(
      context,
      title: 'Quick Actions',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MagicListTile(
            title: 'Create project',
            leading: const MagicIcon(Icons.add_circle_outline),
            onTap: () => Navigator.of(context).pop(),
            showDivider: true,
          ),
          MagicListTile(
            title: 'Share workspace',
            leading: const MagicIcon(Icons.share_outlined),
            onTap: () => Navigator.of(context).pop(),
            showDivider: true,
          ),
          MagicListTile(
            title: 'Archive',
            leading: const MagicIcon(Icons.archive_outlined),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MagicButton(
      label: 'Show bottom sheet',
      onPressed: () => _showBottomSheet(context),
      icon: Icons.expand_less,
    );
  }
}
