import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';
import '../atoms/magickit_avatar_example.dart';
import '../atoms/magickit_badge_example.dart';
import '../atoms/magickit_button_example.dart';
import '../atoms/magickit_checkbox_example.dart';
import '../atoms/magickit_divider_example.dart';
import '../atoms/magickit_icon_example.dart';
import '../atoms/magickit_image_example.dart';
import '../atoms/magickit_input_example.dart';
import '../atoms/magickit_radio_example.dart';
import '../atoms/magickit_shimmer_example.dart';
import '../atoms/magickit_switch_example.dart';
import '../atoms/magickit_text_example.dart';
import '../common/magickit_page_header.dart';
import '../common/magickit_section.dart';

class MagicKitAtomsTab extends StatelessWidget {
  const MagicKitAtomsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return ListView(
      padding: EdgeInsets.all(theme.spacing.md),
      children: [
        const MagicKitPageHeader(
          title: 'Atoms',
          subtitle: 'Elemen dasar untuk menyusun komponen yang lebih kompleks.',
        ),
        MagicKitSection(
          title: 'MagicText',
          children: [MagicKitTextExample()],
        ),
        MagicKitSection(
          title: 'MagicButton',
          children: [MagicKitButtonExample()],
        ),
        MagicKitSection(
          title: 'MagicInput',
          children: [MagicKitInputExample()],
        ),
        MagicKitSection(
          title: 'MagicIcon',
          children: [MagicKitIconExample()],
        ),
        MagicKitSection(
          title: 'MagicAvatar',
          children: [MagicKitAvatarExample()],
        ),
        MagicKitSection(
          title: 'MagicBadge',
          children: [MagicKitBadgeExample()],
        ),
        MagicKitSection(
          title: 'MagicCheckbox',
          children: [MagicKitCheckboxExample()],
        ),
        MagicKitSection(
          title: 'MagicRadio',
          children: [MagicKitRadioExample()],
        ),
        MagicKitSection(
          title: 'MagicSwitch',
          children: [MagicKitSwitchExample()],
        ),
        MagicKitSection(
          title: 'MagicDivider',
          children: [MagicKitDividerExample()],
        ),
        MagicKitSection(
          title: 'MagicImage',
          children: [MagicKitImageExample()],
        ),
        MagicKitSection(
          title: 'MagicShimmer',
          children: [MagicKitShimmerExample()],
        ),
        SizedBox(height: theme.spacing.xxl),
      ],
    );
  }
}
