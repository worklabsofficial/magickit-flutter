import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';
import '../common/magickit_page_header.dart';
import '../common/magickit_section.dart';
import '../organism/magickit_app_bar_example.dart';
import '../organism/magickit_bottom_sheet_example.dart';
import '../organism/magickit_data_table_example.dart';
import '../organism/magickit_drawer_example.dart';
import '../organism/magickit_form_example.dart';
import '../organism/magickit_nav_bar_example.dart';
import '../organism/magickit_tab_bar_example.dart';

class MagicKitOrganismsTab extends StatelessWidget {
  final VoidCallback onOpenDrawer;

  const MagicKitOrganismsTab({
    super.key,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return ListView(
      padding: EdgeInsets.all(theme.spacing.md),
      children: [
        const MagicKitPageHeader(
          title: 'Organisms',
          subtitle: 'Komponen skala besar yang menggabungkan banyak molecules.',
        ),
        MagicKitSection(
          title: 'MagicAppBar',
          children: [MagicKitAppBarExample()],
        ),
        MagicKitSection(
          title: 'MagicTabBar',
          children: [MagicKitTabBarExample()],
        ),
        MagicKitSection(
          title: 'MagicNavBar',
          children: [MagicKitNavBarExample()],
        ),
        MagicKitSection(
          title: 'MagicDrawer',
          children: [MagicKitDrawerTriggerExample(onOpenDrawer: onOpenDrawer)],
        ),
        MagicKitSection(
          title: 'MagicBottomSheet',
          children: [MagicKitBottomSheetExample()],
        ),
        MagicKitSection(
          title: 'MagicForm',
          children: [MagicKitFormExample()],
        ),
        MagicKitSection(
          title: 'MagicDataTable',
          children: [MagicKitDataTableExample()],
        ),
        SizedBox(height: theme.spacing.xxl),
      ],
    );
  }
}
