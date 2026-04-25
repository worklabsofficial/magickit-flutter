import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';
import '../common/magickit_page_header.dart';
import '../common/magickit_section.dart';
import '../molecules/magickit_card_example.dart';
import '../molecules/magickit_carousel_example.dart';
import '../molecules/magickit_chip_example.dart';
import '../molecules/magickit_dialog_example.dart';
import '../molecules/magickit_dropdown_example.dart';
import '../molecules/magickit_empty_state_example.dart';
import '../molecules/magickit_form_field_example.dart';
import '../molecules/magickit_list_tile_example.dart';
import '../molecules/magickit_rating_example.dart';
import '../molecules/magickit_search_bar_example.dart';
import '../molecules/magickit_snackbar_example.dart';
import '../molecules/magickit_stepper_example.dart';
import '../molecules/magickit_tooltip_example.dart';

class MagicKitMoleculesTab extends StatelessWidget {
  const MagicKitMoleculesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return ListView(
      padding: EdgeInsets.all(theme.spacing.md),
      children: [
        const MagicKitPageHeader(
          title: 'Molecules',
          subtitle: 'Kombinasi atoms yang membentuk pola komponen siap pakai.',
        ),
        const MagicKitSection(
          title: 'MagicCard',
          children: [MagicKitCardExample()],
        ),
        const MagicKitSection(
          title: 'MagicCarousel',
          children: [MagicKitCarouselExample()],
        ),
        const MagicKitSection(
          title: 'MagicChip',
          children: [MagicKitChipExample()],
        ),
        const MagicKitSection(
          title: 'MagicListTile',
          children: [MagicKitListTileExample()],
        ),
        const MagicKitSection(
          title: 'MagicDropdown',
          children: [MagicKitDropdownExample()],
        ),
        const MagicKitSection(
          title: 'MagicFormField',
          children: [MagicKitFormFieldExample()],
        ),
        const MagicKitSection(
          title: 'MagicSearchBar',
          children: [MagicKitSearchBarExample()],
        ),
        const MagicKitSection(
          title: 'MagicTooltip',
          children: [MagicKitTooltipExample()],
        ),
        const MagicKitSection(
          title: 'MagicDialog',
          children: [MagicKitDialogExample()],
        ),
        const MagicKitSection(
          title: 'MagicEmptyState',
          children: [MagicKitEmptyStateExample()],
        ),
        const MagicKitSection(
          title: 'MagicRating',
          children: [MagicKitRatingExample()],
        ),
        const MagicKitSection(
          title: 'MagicSnackbar',
          children: [MagicKitSnackbarExample()],
        ),
        const MagicKitSection(
          title: 'MagicStepper',
          children: [MagicKitStepperExample()],
        ),
        SizedBox(height: theme.spacing.xxl),
      ],
    );
  }
}
