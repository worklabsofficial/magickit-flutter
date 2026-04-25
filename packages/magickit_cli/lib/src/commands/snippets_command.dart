import 'dart:io';
import 'package:args/command_runner.dart';
import '../utils/logger.dart';

class SnippetsCommand extends Command<void> {
  @override
  String get name => 'snippets';

  @override
  String get description =>
      'Install VS Code snippets untuk MagicKit components.';

  SnippetsCommand() {
    addSubcommand(SnippetsInstallCommand());
    addSubcommand(SnippetsListCommand());
  }

  @override
  Future<void> run() async {
    usageException(
      'Gunakan subcommand:\n'
      '  magickit snippets install  → Install snippets ke .vscode/\n'
      '  magickit snippets list     → Lihat daftar snippets yang tersedia',
    );
  }
}

class SnippetsInstallCommand extends Command<void> {
  @override
  String get name => 'install';

  @override
  String get description =>
      'Install VS Code snippets ke .vscode/magickit.code-snippets';

  SnippetsInstallCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output path untuk snippets file.',
      defaultsTo: '.vscode/magickit.code-snippets',
    );
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Install ke VS Code global snippets (~/.vscode/snippets/).',
      defaultsTo: false,
    );
  }

  @override
  Future<void> run() async {
    final outputPath = argResults!['output'] as String;
    final isGlobal = argResults!['global'] as bool;

    String targetPath;

    if (isGlobal) {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ??
          '.';
      targetPath =
          '$home/Library/Application Support/Code/User/snippets/magickit.code-snippets';
      if (Platform.isLinux) {
        targetPath = '$home/.config/Code/User/snippets/magickit.code-snippets';
      } else if (Platform.isWindows) {
        targetPath =
            '$home\\AppData\\Roaming\\Code\\User\\snippets\\magickit.code-snippets';
      }
      logger.info('Installing global snippets...');
    } else {
      targetPath = outputPath;
      logger.info('Installing project snippets...');
    }

    final file = File(targetPath);

    // Create parent directory if needed
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    // Write snippets content
    file.writeAsStringSync(_snippetsContent);

    logger.success('VS Code snippets berhasil diinstall!');
    logger.info('');
    logger.info('File: ${file.absolute.path}');
    logger.info('');
    logger.info('Available snippets (${_snippetCount} total):');
    _printSnippetSummary();
    logger.info('');
    logger.info('Restart VS Code jika snippets belum muncul.');
  }
}

class SnippetsListCommand extends Command<void> {
  @override
  String get name => 'list';

  @override
  String get description => 'Lihat daftar VS Code snippets yang tersedia.';

  @override
  Future<void> run() async {
    logger.info('');
    logger.info('📦 MagicKit VS Code Snippets (${_snippetCount} total):');
    logger.info('');
    _printSnippetSummary();
    logger.info('');
    logger.info('Install dengan: magickit snippets install');
    logger.info('Global install: magickit snippets install --global');
  }
}

void _printSnippetSummary() {
  final snippets = _snippets.entries.toList();

  // Group by category
  final atoms = <MapEntry<String, dynamic>>[];
  final molecules = <MapEntry<String, dynamic>>[];
  final organisms = <MapEntry<String, dynamic>>[];
  final tokens = <MapEntry<String, dynamic>>[];
  final scaffolds = <MapEntry<String, dynamic>>[];

  for (final entry in snippets) {
    final name = entry.key;
    if (name.contains('Import') ||
        name.contains('Theme') ||
        name.contains('Colors') ||
        name.contains('Spacing') ||
        name.contains('Typography')) {
      tokens.add(entry);
    } else if (name.contains('FullPage') || name.contains('Form')) {
      scaffolds.add(entry);
    } else if (name.contains('List') ||
        name.contains('Grid') ||
        name.contains('Refresh') ||
        name.contains('AppBar') ||
        name.contains('BottomSheet') ||
        name.contains('NavBar') ||
        name.contains('Drawer') ||
        name.contains('Tab') ||
        name.contains('DataTable') ||
        name.contains('Form')) {
      organisms.add(entry);
    } else if (name.contains('Card') ||
        name.contains('Chip') ||
        name.contains('Dialog') ||
        name.contains('Dropdown') ||
        name.contains('FormField') ||
        name.contains('ListTile') ||
        name.contains('Search') ||
        name.contains('Snackbar') ||
        name.contains('Tooltip') ||
        name.contains('Stepper') ||
        name.contains('Rating') ||
        name.contains('Carousel') ||
        name.contains('Empty')) {
      molecules.add(entry);
    } else {
      atoms.add(entry);
    }
  }

  void printGroup(String label, List<MapEntry<String, dynamic>> items) {
    if (items.isEmpty) return;
    logger.info('  $label:');
    for (final item in items) {
      final prefix = (item.value as Map)['prefix'];
      final desc = (item.value as Map)['description'];
      logger.info('    ${prefix.toString().padRight(8)} → $desc');
    }
    logger.info('');
  }

  printGroup('🎨 Tokens & Theme', tokens);
  printGroup('⚛️  Atoms', atoms);
  printGroup('🔬 Molecules', molecules);
  printGroup('🏗️  Organisms', organisms);
  printGroup('📋 Page Scaffolds', scaffolds);
}

int get _snippetCount => _snippets.length;

final _snippets = <String, dynamic>{
  "MagicImport": {
    "prefix": "mimp",
    "body": ["import 'package:magickit/magickit.dart';"],
    "description": "Import magickit package"
  },
  "MagicTheme": {
    "prefix": "mthm",
    "body": ["final theme = MagicTheme.of(context);"],
    "description": "Access MagicTheme from context"
  },
  "MagicThemeColors": {
    "prefix": "mclr",
    "body": [
      "MagicTheme.of(context).colors.\${1|primary,secondary,surface,background,error,outline|}"
    ],
    "description": "Access MagicTheme colors"
  },
  "MagicThemeSpacing": {
    "prefix": "mspc",
    "body": ["MagicTheme.of(context).spacing.\${1|xs,sm,md,lg,xl,xxl|}"],
    "description": "Access MagicTheme spacing"
  },
  "MagicThemeTypography": {
    "prefix": "mtpg",
    "body": [
      "MagicTheme.of(context).typography.\${1|heading1,heading2,heading3,heading4,heading5,heading6,bodyLarge,bodyMedium,bodySmall,caption,label|}"
    ],
    "description": "Access MagicTheme typography"
  },
  "MagicButton": {
    "prefix": "mbtn",
    "body": [
      "MagicButton(",
      "  label: '\${1:Label}',",
      "  onPressed: \${2:() {},}",
      "  variant: MagicButtonVariant.\${3|primary,secondary,outlined,ghost|},",
      "  size: MagicButtonSize.\${4|medium,small,large|},",
      "),"
    ],
    "description": "MagicButton widget"
  },
  "MagicText": {
    "prefix": "mtxt",
    "body": [
      "MagicText(",
      "  '\${1:Text content}',",
      "  style: MagicTextStyle.\${2|h1,h2,h3,h4,h5,h6,bodyLarge,bodyMedium,bodySmall,caption,label|},",
      "),"
    ],
    "description": "MagicText widget"
  },
  "MagicInput": {
    "prefix": "minp",
    "body": [
      "MagicInput(",
      "  hint: '\${1:Enter text...}',",
      "  controller: \${2:_controller},",
      "  label: '\${3:Label}',",
      "  onChanged: \${4:(value) {},}",
      "),"
    ],
    "description": "MagicInput text field"
  },
  "MagicCard": {
    "prefix": "mcrd",
    "body": [
      "MagicCard(",
      "  elevation: MagicCardElevation.\${1|sm,md,lg,none|},",
      "  child: \${2:const Placeholder()},",
      "),"
    ],
    "description": "MagicCard container"
  },
  "MagicAvatar": {
    "prefix": "mavr",
    "body": [
      "MagicAvatar(",
      "  imageUrl: '\${1:url}',",
      "  size: MagicAvatarSize.\${2|md,sm,lg,xl|},",
      "  fallbackInitial: '\${3:AB}',",
      "),"
    ],
    "description": "MagicAvatar widget"
  },
  "MagicBadge": {
    "prefix": "mbdg",
    "body": [
      "MagicBadge(",
      "  label: '\${1:Badge}',",
      "  variant: MagicBadgeVariant.\${2|soft,outline,solid|},",
      "),"
    ],
    "description": "MagicBadge label"
  },
  "MagicChip": {
    "prefix": "mchp",
    "body": [
      "MagicChip(",
      "  label: '\${1:Chip}',",
      "  selected: \${2|true,false|},",
      "  onTap: \${3:() {},}",
      "),"
    ],
    "description": "MagicChip filter/tag"
  },
  "MagicCheckbox": {
    "prefix": "mchk",
    "body": [
      "MagicCheckbox(",
      "  value: \${1|true,false,null|},",
      "  onChanged: \${2:(value) {},}",
      "  label: '\${3:Checkbox label}',",
      "),"
    ],
    "description": "MagicCheckbox widget"
  },
  "MagicSwitch": {
    "prefix": "mswt",
    "body": [
      "MagicSwitch(",
      "  value: \${1|true,false|},",
      "  onChanged: \${2:(value) {},}",
      "  label: '\${3:Switch label}',",
      "),"
    ],
    "description": "MagicSwitch toggle"
  },
  "MagicRadio": {
    "prefix": "mrdo",
    "body": [
      "MagicRadio<\${1:String}>(",
      "  value: '\${2:option1}',",
      "  groupValue: \${3:_groupValue},",
      "  onChanged: \${4:(value) {},}",
      "  label: '\${5:Option 1}',",
      "),"
    ],
    "description": "MagicRadio single select"
  },
  "MagicProgress": {
    "prefix": "mpro",
    "body": [
      "MagicProgress(",
      "  value: \${1:0.5},",
      "  type: MagicProgressType.\${2|linear,circular|},",
      "  showLabel: \${3|true,false|},",
      "),"
    ],
    "description": "MagicProgress loading indicator"
  },
  "MagicSlider": {
    "prefix": "msld",
    "body": [
      "MagicSlider(",
      "  value: \${1:0.5},",
      "  min: \${2:0},",
      "  max: \${3:100},",
      "  onChanged: \${4:(value) {},}",
      "  label: '\${5:Label}',",
      "),"
    ],
    "description": "MagicSlider range input"
  },
  "MagicRangeSlider": {
    "prefix": "mrsl",
    "body": [
      "MagicRangeSlider(",
      "  values: \${1:const RangeValues(20, 80)},",
      "  min: \${2:0},",
      "  max: \${3:100},",
      "  onChanged: \${4:(values) {},}",
      "  label: '\${5:Price Range}',",
      "),"
    ],
    "description": "MagicRangeSlider dual thumb"
  },
  "MagicPinInput": {
    "prefix": "mpin",
    "body": [
      "MagicPinInput(",
      "  length: \${1:6},",
      "  onCompleted: \${2:(pin) {},}",
      "  obscureText: \${3|true,false|},",
      "),"
    ],
    "description": "MagicPinInput OTP/PIN"
  },
  "MagicDivider": {
    "prefix": "mdiv",
    "body": [
      "MagicDivider(",
      "  thickness: \${1:1},",
      "  indent: \${2:0},",
      "  endIndent: \${3:0},",
      "),"
    ],
    "description": "MagicDivider separator"
  },
  "MagicShimmer": {
    "prefix": "mshm",
    "body": [
      "MagicShimmer(",
      "  width: \${1:100},",
      "  height: \${2:16},",
      "  borderRadius: BorderRadius.circular(\${3:8}),",
      "),"
    ],
    "description": "MagicShimmer loading placeholder"
  },
  "MagicFormField": {
    "prefix": "mff",
    "body": [
      "MagicFormField(",
      "  label: '\${1:Field Label}',",
      "  isRequired: \${2|true,false|},",
      "  child: MagicInput(",
      "    hint: '\${3:Enter value...}',",
      "  ),",
      "),"
    ],
    "description": "MagicFormField wrapper"
  },
  "MagicTooltip": {
    "prefix": "mtip",
    "body": [
      "MagicTooltip(",
      "  message: '\${1:Tooltip text}',",
      "  child: \${2:const Icon(Icons.info)},",
      "),"
    ],
    "description": "MagicTooltip info"
  },
  "MagicDialog": {
    "prefix": "mdlg",
    "body": [
      "MagicDialog(",
      "  title: '\${1:Dialog Title}',",
      "  content: Text('\${2:Content}'),",
      "  actions: [",
      "    MagicButton(",
      "      label: 'Cancel',",
      "      onPressed: () => Navigator.pop(context),",
      "      variant: MagicButtonVariant.ghost,",
      "    ),",
      "    MagicButton(",
      "      label: 'OK',",
      "      onPressed: \${3:() {},}",
      "    ),",
      "  ],",
      ")"
    ],
    "description": "MagicDialog popup"
  },
  "MagicSearchBar": {
    "prefix": "msrc",
    "body": [
      "MagicSearchBar(",
      "  controller: \${1:_searchController},",
      "  hint: '\${2:Cari...}',",
      "  onSearch: \${3:(query) {},}",
      "  onChanged: \${4:(value) {},}",
      "),"
    ],
    "description": "MagicSearchBar input"
  },
  "MagicDropdown": {
    "prefix": "mddn",
    "body": [
      "MagicDropdown<\${1:String}>(",
      "  items: [",
      "    \${2:/* DropdownMenuItem list */}",
      "  ],",
      "  value: \${3:_selectedValue},",
      "  onChanged: \${4:(value) {},}",
      "  hint: Text('\${5:Pilih...}'),",
      "),"
    ],
    "description": "MagicDropdown selector"
  },
  "MagicListTile": {
    "prefix": "mlst",
    "body": [
      "MagicListTile(",
      "  title: '\${1:Title}',",
      "  subtitle: '\${2:Subtitle}',",
      "  leading: \${3:const Icon(Icons.star)},",
      "  onTap: \${4:() {},}",
      "),"
    ],
    "description": "MagicListTile item"
  },
  "MagicSnackbar": {
    "prefix": "msnk",
    "body": [
      "MagicSnackbar.show(",
      "  context,",
      "  message: '\${1:Message}',",
      "  variant: MagicSnackbarVariant.\${2|info,success,warning,error|},",
      "),"
    ],
    "description": "MagicSnackbar notification"
  },
  "MagicStepper": {
    "prefix": "mstp",
    "body": [
      "MagicStepper(",
      "  currentStep: \${1:0},",
      "  onStepTapped: \${2:(index) {},}",
      "  steps: [",
      "    MagicStepData(title: '\${3:Step 1}'),",
      "    MagicStepData(title: '\${4:Step 2}'),",
      "    MagicStepData(title: '\${5:Step 3}'),",
      "  ],",
      "),"
    ],
    "description": "MagicStepper wizard flow"
  },
  "MagicRating": {
    "prefix": "mrtg",
    "body": [
      "MagicRating(",
      "  value: \${1:3.5},",
      "  onChanged: \${2:(value) {},}",
      "  showLabel: \${3|true,false|},",
      "),"
    ],
    "description": "MagicRating star rating"
  },
  "MagicRatingDisplay": {
    "prefix": "mrtd",
    "body": [
      "MagicRating.display(",
      "  value: \${1:4.5},",
      "  showValue: \${2|true,false|},",
      "  itemCount: \${3:128},",
      "),"
    ],
    "description": "MagicRating display (read-only)"
  },
  "MagicCarousel": {
    "prefix": "mcrl",
    "body": [
      "MagicCarousel(",
      "  items: [",
      "    \${1:/* Carousel items */}",
      "  ],",
      "  height: \${2:200},",
      "  autoPlayInterval: \${3:const Duration(seconds: 5)},",
      "  infiniteScroll: \${4|true,false|},",
      "),"
    ],
    "description": "MagicCarousel slider"
  },
  "MagicEmptyState": {
    "prefix": "memp",
    "body": [
      "MagicEmptyState(",
      "  icon: Icons.\${1|inbox_rounded,search_off_rounded,error_outline_rounded,wifi_off_rounded|},",
      "  title: '\${2:No Data}',",
      "  description: '\${3:Data will appear here.}',",
      "  actionLabel: '\${4:Refresh}',",
      "  onAction: \${5:() {},}",
      "),"
    ],
    "description": "MagicEmptyState placeholder"
  },
  "MagicEmptyStateNoData": {
    "prefix": "mempd",
    "body": [
      "MagicEmptyState.noData(",
      "  customTitle: '\${1:Belum ada data}',",
      "  customDescription: '\${2:Data akan muncul di sini.}',",
      "  actionLabel: '\${3:Refresh}',",
      "  onAction: \${4:() {},}",
      "),"
    ],
    "description": "MagicEmptyState for empty lists"
  },
  "MagicForm": {
    "prefix": "mfrm",
    "body": [
      "MagicForm(",
      "  children: [",
      "    \${1:/* Form fields */}",
      "  ],",
      "  onSubmit: \${2:() {},}",
      "  submitLabel: '\${3:Submit}',",
      "),"
    ],
    "description": "MagicForm wrapper with validation"
  },
  "MagicAppBar": {
    "prefix": "mapp",
    "body": [
      "MagicAppBar(",
      "  title: '\${1:Title}',",
      "  actions: [",
      "    IconButton(",
      "      icon: const Icon(Icons.\${2|settings,search,more_vert|}),",
      "      onPressed: \${3:() {},}",
      "    ),",
      "  ],",
      "),"
    ],
    "description": "MagicAppBar header"
  },
  "MagicBottomSheet": {
    "prefix": "mbtm",
    "body": [
      "showModalBottomSheet(",
      "  context: context,",
      "  builder: (context) => MagicBottomSheet(",
      "    title: '\${1:Title}',",
      "    child: \${2:const Placeholder()},",
      "  ),",
      "),"
    ],
    "description": "MagicBottomSheet modal"
  },
  "MagicNavBar": {
    "prefix": "mnvb",
    "body": [
      "MagicNavBar(",
      "  items: [",
      "    /* NavigationBar items */",
      "  ],",
      "  currentIndex: \${1:_currentIndex},",
      "  onTap: \${2:(index) {},}",
      "),"
    ],
    "description": "MagicNavBar bottom navigation"
  },
  "MagicDrawer": {
    "prefix": "mdrw",
    "body": [
      "MagicDrawer(",
      "  header: DrawerHeader(",
      "    child: Text('\${1:App Name}'),",
      "  ),",
      "  items: [",
      "    /* Drawer menu items */",
      "  ],",
      "),"
    ],
    "description": "MagicDrawer side navigation"
  },
  "MagicTabBar": {
    "prefix": "mtab",
    "body": [
      "MagicTabBar(",
      "  tabs: [",
      "    MagicTab(text: '\${1:Tab 1}'),",
      "    MagicTab(text: '\${2:Tab 2}'),",
      "  ],",
      "  controller: \${3:_tabController},",
      "),"
    ],
    "description": "MagicTabBar navigation"
  },
  "MagicDataTable": {
    "prefix": "mdtb",
    "body": [
      "MagicDataTable(",
      "  columns: [",
      "    MagicDataColumn(label: '\${1:Column 1}'),",
      "    MagicDataColumn(label: '\${2:Column 2}'),",
      "  ],",
      "  rows: [",
      "    /* MagicDataRow list */",
      "  ],",
      "),"
    ],
    "description": "MagicDataTable data display"
  },
  "MagicListView": {
    "prefix": "mlvw",
    "body": [
      "MagicListView<\${1:dynamic}>(",
      "  items: \${2:_items},",
      "  itemBuilder: (context, item, index) {",
      "    return \${3:MagicListTile(title: item.toString())};",
      "  },",
      "  onRefresh: \${4:() async {},}",
      "  onLoadMore: \${5:() {},}",
      "  isLoadingMore: \${6|true,false|},",
      "  hasMore: \${7|true,false|},",
      "),"
    ],
    "description": "MagicListView with infinite scroll"
  },
  "MagicGridView": {
    "prefix": "mgrv",
    "body": [
      "MagicGridView<\${1:dynamic}>(",
      "  items: \${2:_items},",
      "  itemBuilder: (context, item, index) {",
      "    return \${3:/* Item widget */};",
      "  },",
      "  columns: \${4:2},",
      "  onRefresh: \${5:() async {},}",
      "  onLoadMore: \${6:() {},}",
      "  isLoadingMore: \${7|true,false|},",
      "  hasMore: \${8|true,false|},",
      "),"
    ],
    "description": "MagicGridView with infinite scroll"
  },
  "MagicRefreshLayout": {
    "prefix": "mref",
    "body": [
      "MagicRefreshLayout(",
      "  onRefresh: \${1:() async {},}",
      "  child: \${2:const Placeholder()},",
      "),"
    ],
    "description": "MagicRefreshLayout pull-to-refresh"
  },
  "MagicFullPage": {
    "prefix": "mpage",
    "body": [
      "import 'package:flutter/material.dart';",
      "import 'package:magickit/magickit.dart';",
      "",
      "class \${1:PageName}Page extends StatelessWidget {",
      "  const \${1:PageName}Page({super.key});",
      "",
      "  @override",
      "  Widget build(BuildContext context) {",
      "    final theme = MagicTheme.of(context);",
      "",
      "    return Scaffold(",
      "      appBar: MagicAppBar(",
      "        title: '\${2:Page Title}',",
      "      ),",
      "      body: MagicListView<\${3:dynamic}>(",
      "        items: const [],",
      "        itemBuilder: (context, item, index) {",
      "          return MagicListTile(",
      "            title: item.toString(),",
      "          );",
      "        },",
      "        emptyWidget: const MagicEmptyState.noData(),",
      "        onRefresh: () async {},",
      "      ),",
      "    );",
      "  }",
      "}"
    ],
    "description": "Full page scaffold with MagicKit components"
  },
  "MagicFullPageForm": {
    "prefix": "mform",
    "body": [
      "import 'package:flutter/material.dart';",
      "import 'package:magickit/magickit.dart';",
      "",
      "class \${1:FormName}FormPage extends StatefulWidget {",
      "  const \${1:FormName}FormPage({super.key});",
      "",
      "  @override",
      "  State<\${1:FormName}FormPage> createState() => _\${1:FormName}FormPageState();",
      "}",
      "",
      "class _\${1:FormName}FormPageState extends State<\${1:FormName}FormPage> {",
      "  final _formKey = GlobalKey<FormState>();",
      "  final _\${2:text}Controller = TextEditingController();",
      "",
      "  @override",
      "  void dispose() {",
      "    _\${2:text}Controller.dispose();",
      "    super.dispose();",
      "  }",
      "",
      "  void _handleSubmit() {",
      "    if (_formKey.currentState?.validate() ?? false) {",
      "      \${3:// Submit logic}",
      "    }",
      "  }",
      "",
      "  @override",
      "  Widget build(BuildContext context) {",
      "    return Scaffold(",
      "      appBar: MagicAppBar(",
      "        title: '\${4:Form Title}',",
      "      ),",
      "      body: MagicForm(",
      "        formKey: _formKey,",
      "        children: [",
      "          MagicFormField(",
      "            label: '\${5:Field Label}',",
      "            isRequired: true,",
      "            child: MagicInput(",
      "              hint: 'Enter \${5:Field Label}...',",
      "              controller: _\${2:text}Controller,",
      "              validator: (value) {",
      "                if (value == null || value.isEmpty) {",
      "                  return '\${5:Field Label} is required';",
      "                }",
      "                return null;",
      "              },",
      "            ),",
      "          ),",
      "        ],",
      "        onSubmit: _handleSubmit,",
      "      ),",
      "    );",
      "  }",
      "}"
    ],
    "description": "Full form page scaffold"
  }
};

String get _snippetsContent => _convertMapToJson(_snippets);

String _convertMapToJson(Map<String, dynamic> map) {
  // Convert to proper JSON format for VS Code snippets
  final buffer = StringBuffer('{\n');
  final entries = map.entries.toList();

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final isLast = i == entries.length - 1;

    buffer.writeln('  "${entry.key}": {');

    final snippet = entry.value as Map<String, dynamic>;

    // prefix
    buffer.writeln('    "prefix": "${snippet['prefix']}",');

    // body
    buffer.writeln('    "body": [');
    final body = snippet['body'] as List;
    for (var j = 0; j < body.length; j++) {
      final line = body[j].toString().replaceAll('"', '\\"');
      final isLastLine = j == body.length - 1;
      buffer.writeln('      "$line"${isLastLine ? "" : ","}');
    }
    buffer.writeln('    ],');

    // description
    buffer.writeln('    "description": "${snippet['description']}"');
    buffer.writeln('  }${isLast ? "" : ","}');
  }

  buffer.writeln('}');
  return buffer.toString();
}
