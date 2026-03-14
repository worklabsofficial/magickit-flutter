import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';
import '../common/magickit_page_header.dart';
import '../common/magickit_section.dart';
import '../molecules/magickit_card_example.dart';
import '../molecules/magickit_chip_example.dart';
import '../molecules/magickit_dialog_example.dart';
import '../molecules/magickit_dropdown_example.dart';
import '../molecules/magickit_form_field_example.dart';
import '../molecules/magickit_list_tile_example.dart';
import '../molecules/magickit_search_bar_example.dart';
import '../molecules/magickit_snackbar_example.dart';
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
        MagicKitSection(
          title: 'MagicCard',
          children: [MagicKitCardExample()],
        ),
        MagicKitSection(
          title: 'MagicChip',
          children: [MagicKitChipExample()],
        ),
        MagicKitSection(
          title: 'MagicListTile',
          children: [MagicKitListTileExample()],
        ),
        MagicKitSection(
          title: 'MagicDropdown',
          children: [MagicKitDropdownExample()],
        ),
        MagicKitSection(
          title: 'MagicFormField',
          children: [MagicKitFormFieldExample()],
        ),
        MagicKitSection(
          title: 'MagicSearchBar',
          children: [MagicKitSearchBarExample()],
        ),
        MagicKitSection(
          title: 'MagicTooltip',
          children: [MagicKitTooltipExample()],
        ),
        MagicKitSection(
          title: 'MagicDialog',
          children: [MagicKitDialogExample()],
        ),
        MagicKitSection(
          title: 'MagicSnackbar',
          children: [MagicKitSnackbarExample()],
        ),
        SizedBox(height: theme.spacing.xxl),
      ],
    );
  }
}
