import 'dart:io';
import 'package:args/command_runner.dart';
import '../generators/route_generator.dart';
import '../utils/logger.dart';

class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Generate magickit.yaml dan struktur folder project.';

  @override
  Future<void> run() async {
    final configFile = File('magickit.yaml');

    if (configFile.existsSync()) {
      logger.warn(
          'magickit.yaml sudah ada. Hapus file tersebut untuk generate ulang.');
      return;
    }

    logger.info('Initializing MagicKit project...');
    logger.info('');

    // 1. Create magickit.yaml
    configFile.writeAsStringSync(_defaultConfig);
    logger.success('magickit.yaml berhasil dibuat');

    // 2. Create asset folders
    _createDir('assets/icons');
    _createDir('assets/illustrations');
    _createDir('assets/images');
    _createDir('assets/l10n');
    logger.success(
        'Folder assets/ berhasil dibuat (icons, illustrations, images, l10n)');

    // 3. Create l10n template files
    _createFile('assets/l10n/en.json', _enJson);
    _createFile('assets/l10n/id.json', _idJson);
    logger.success('Template l10n berhasil dibuat (en.json, id.json)');

    // 4. Create lib/core/base/ with MagicCubit
    _createDir('lib/core/base');
    _createFile('lib/core/base/magic_cubit.dart', _magicCubitContent);
    _createFile('lib/core/base/magic_state_page.dart', _magicStatePageContent);
    logger.success('lib/core/base/ berhasil dibuat (MagicCubit, MagicStatePage)');

    // 5. Create lib/core/dependency_injection/
    _createDir('lib/core/dependency_injection');
    _createFile(
        'lib/core/dependency_injection/injection.dart', _injectionContent);
    logger.success('lib/core/dependency_injection/injection.dart berhasil dibuat');

    // 6. Create lib/core/assets/
    _createDir('lib/core/assets');
    logger.success('lib/core/assets/ berhasil dibuat');

    // 7. Create lib/core/routes/
    final routeGenerator = RouteGenerator();
    final routeFiles = routeGenerator.generateCoreRouteFiles();
    for (final entry in routeFiles.entries) {
      _createFile(entry.key, entry.value);
    }
    logger.success('lib/core/routes/ berhasil dibuat (route_config, route_names, route_extensions, route_query_keys)');

    // 8. Inject ke main.dart
    _injectMainDart();

    logger.info('');
    logger.info('Struktur project:');
    logger.info('  assets/');
    logger.info('  ├── icons/');
    logger.info('  ├── illustrations/');
    logger.info('  ├── images/');
    logger.info('  └── l10n/');
    logger.info('      ├── en.json');
    logger.info('      └── id.json');
    logger.info('  lib/');
    logger.info('  └── core/');
    logger.info('      ├── base/                 ← MagicCubit, MagicStatePage');
    logger.info('      ├── dependency_injection/ ← injection.dart');
    logger.info('      ├── assets/              ← output magickit assets & l10n');
    logger.info('      └── routes/              ← route_config, route_names, route_extensions, route_query_keys');
    logger.info('');
    logger.info('Tambahkan dependencies ke pubspec.yaml:');
    logger.info('  flutter_bloc: ^8.0.0');
    logger.info('  get_it: ^7.0.0');
    logger.info('  go_router: ^14.0.0');
    logger.info('');
    logger.info('Edit magickit.yaml sesuai kebutuhan project kamu.');
    logger.info(
        'Lalu jalankan `magickit assets` dan `magickit l10n` untuk generate code.');
  }

  void _injectMainDart() {
    final mainFile = File('lib/main.dart');
    if (!mainFile.existsSync()) return;

    var content = mainFile.readAsStringSync();
    var modified = false;

    const diImport = "import 'core/dependency_injection/injection.dart';";
    const routeImport = "import 'core/routes/route_config.dart';";

    if (!content.contains('dependency_injection/injection.dart')) {
      content = content.replaceFirst(
        "import 'package:flutter/material.dart';",
        "import 'package:flutter/material.dart';\n$diImport\n$routeImport",
      );
      modified = true;
    } else if (!content.contains('core/routes/route_config.dart')) {
      final lastImportEnd = content.lastIndexOf("';") + 2;
      if (lastImportEnd > 1) {
        content =
            '${content.substring(0, lastImportEnd)}\n$routeImport${content.substring(lastImportEnd)}';
        modified = true;
      }
    }

    if (!content.contains('initDependencies()')) {
      content = content.replaceFirst(
        'runApp(',
        'initDependencies();\n  runApp(',
      );
      modified = true;
    }

    // Replace MaterialApp( with MaterialApp.router( if not already done
    if (content.contains('MaterialApp(') &&
        !content.contains('MaterialApp.router(')) {
      content = content.replaceFirst(
        'MaterialApp(',
        'MaterialApp.router(\n      routerConfig: routeConfig,',
      );
      modified = true;
    }

    if (modified) {
      mainFile.writeAsStringSync(content);
      logger.success('main.dart berhasil diupdate (initDependencies + MaterialApp.router)');
    }
  }

  void _createDir(String path) {
    Directory(path).createSync(recursive: true);
  }

  void _createFile(String path, String content) {
    final file = File(path);
    if (!file.existsSync()) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }
  }

  static const _magicCubitContent = r"""
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class MagicCubit<S> extends Cubit<S> {
  MagicCubit(super.initialState);

  /// Called saat page initState
  void onInit() {}

  /// Called setelah first frame rendered
  void onReady() {}

  /// Called saat page dispose (sebelum close)
  void onDispose() {}

  /// Override untuk expose Bloc yang perlu di-register ke widget tree
  List<BlocProvider> get blocProviders => [];

  /// Override untuk define Bloc listeners
  List<BlocListener> Function(BuildContext context)? get blocListeners => null;

  /// Safe emit — tidak crash kalau sudah closed
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }

  @override
  Future<void> close() {
    onDispose();
    return super.close();
  }
}
""";

  static const _magicStatePageContent = r"""
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'magic_cubit.dart';

mixin MagicStatePage<P extends StatefulWidget, C extends MagicCubit<S>, S>
    on State<P> {
  late final C cubit;

  /// Override untuk provide cubit dari DI
  C createCubit();

  /// Override untuk build UI — terima state langsung
  Widget buildPage(BuildContext context, S state);

  @override
  void initState() {
    super.initState();
    cubit = createCubit();
    cubit.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.onReady();
    });
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = BlocBuilder<C, S>(
      bloc: cubit,
      builder: (context, state) => buildPage(context, state),
    );

    final listenersFn = cubit.blocListeners;
    if (listenersFn != null) {
      final listeners = listenersFn(context);
      if (listeners.isNotEmpty) {
        child = MultiBlocListener(listeners: listeners, child: child);
      }
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<C>.value(value: cubit),
        ...cubit.blocProviders,
      ],
      child: child,
    );
  }
}
""";

  static const _injectionContent = '''
// GENERATED BY MAGICKIT CLI

import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void initDependencies() {
  _registerCore();
}

void _registerCore() {
  // TODO: Register core dependencies (http client, shared preferences, dll)
}
''';

  static const _defaultConfig = r'''
magickit:
  # Assets generation
  assets:
    input: assets/
    output: lib/core/assets/assets.gen.dart
    exclude:
      - l10n                         # skip, ditangani magickit l10n
    group:
      icons: icons/                  # MagicAssets.icons.xxx
      illustrations: illustrations/  # MagicAssets.illustrations.xxx
      images: images/                # MagicAssets.images.xxx
    strip_prefix:
      - ic_
      - img_

  # Localization
  l10n:
    input: assets/l10n/
    output: lib/core/assets/l10n/
    default_locale: id
    supported_locales:
      - id
      - en

  # Page generation (MagicCubit architecture)
  page:
    output: lib/features/
    # Default: cubit only — magickit page auth login
    # Complex: + bloc  — magickit page product order --with-bloc

  # Routing
  routes:
    output: lib/core/routes/

  # API / Model generation
  api:
    input: api_schemas/
    output: lib/data/models/
    generate_repository: true

  # Theme
  theme:
    primary: "#2d4af5"
    secondary: "#1a1a2e"
    background: "#f5f4f0"
    font_family: "DM Sans"
    mono_font_family: "DM Mono"

  # Slicing
  slicing:
    ai_provider: anthropic
    output: lib/features/
    use_local_components: true
''';

  static const _enJson = '''{
  "app_name": "My App",
  "common": {
    "ok": "OK",
    "cancel": "Cancel",
    "save": "Save",
    "delete": "Delete",
    "loading": "Loading..."
  }
}
''';

  static const _idJson = '''{
  "app_name": "My App",
  "common": {
    "ok": "OK",
    "cancel": "Batal",
    "save": "Simpan",
    "delete": "Hapus",
    "loading": "Memuat..."
  }
}
''';
}
