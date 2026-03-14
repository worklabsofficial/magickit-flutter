import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';
import 'organism/magickit_drawer_example.dart';
import 'tabs/magickit_atoms_tab.dart';
import 'tabs/magickit_molecules_tab.dart';
import 'tabs/magickit_organisms_tab.dart';

class MagicKitWidgetBookPage extends StatefulWidget {
  const MagicKitWidgetBookPage({super.key});

  @override
  State<MagicKitWidgetBookPage> createState() => _MagicKitWidgetBookPageState();
}

class _MagicKitWidgetBookPageState extends State<MagicKitWidgetBookPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colors.background,
      appBar: MagicAppBar(
        title: 'MagicKit Widget Book',
        bottom: MagicTabBar(
          controller: _tabController,
          tabs: const [
            MagicTab(label: 'Atoms', icon: Icons.circle_outlined),
            MagicTab(label: 'Molecules', icon: Icons.widgets_outlined),
            MagicTab(label: 'Organisms', icon: Icons.dashboard_outlined),
          ],
        ),
      ),
      drawer: const MagicKitDrawerExample(),
      body: TabBarView(
        controller: _tabController,
        children: [
          const MagicKitAtomsTab(),
          const MagicKitMoleculesTab(),
          MagicKitOrganismsTab(onOpenDrawer: _openDrawer),
        ],
      ),
    );
  }
}
