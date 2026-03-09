import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import '../generators/route_generator.dart';
import '../utils/logger.dart';
import 'version_command.dart';

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
    logger
        .success('lib/core/base/ berhasil dibuat (MagicCubit, MagicStatePage)');

    // 5. Create lib/core/dependency_injection/
    _createDir('lib/core/dependency_injection');
    _createFile(
        'lib/core/dependency_injection/injection.dart', _injectionContent);
    logger.success(
        'lib/core/dependency_injection/injection.dart berhasil dibuat');

    // 6. Create lib/core/assets/
    _createDir('lib/core/assets');
    logger.success('lib/core/assets/ berhasil dibuat');

    // 7. Create lib/core/routes/
    final routeGenerator = RouteGenerator();
    final routeFiles = routeGenerator.generateCoreRouteFiles();
    for (final entry in routeFiles.entries) {
      _createFile(entry.key, entry.value);
    }
    logger.success(
        'lib/core/routes/ berhasil dibuat (route_config, route_names, route_extensions, route_query_keys)');

    // 8. Replace main.dart
    _writeMainDart();

    // 9. Inject dependencies ke pubspec.yaml
    _injectPubspecDeps();

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
    logger
        .info('      ├── assets/              ← output magickit assets & l10n');
    logger.info(
        '      └── routes/              ← route_config, route_names, route_extensions, route_query_keys');
    logger.info('');

    // 10. flutter pub get
    await _runFlutterPubGet();

    // 11. magickit l10n (template files sudah siap)
    await _runMagickitL10n();

    logger.info('');
    logger.info('Edit magickit.yaml sesuai kebutuhan project kamu.');
    logger.info(
        'Tambahkan assets lalu jalankan `magickit assets` untuk generate asset references.');
  }

  void _injectPubspecDeps() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      logger.warn('pubspec.yaml tidak ditemukan, skip dependency injection.');
      return;
    }

    var content = pubspecFile.readAsStringSync();

    // Parse existing dependencies via YAML to avoid false positive string matches
    final existingDeps = <String>{};
    try {
      final yaml = loadYaml(content) as YamlMap?;
      final deps = yaml?['dependencies'];
      if (deps is YamlMap) {
        existingDeps.addAll(deps.keys.map((k) => k.toString()));
      }
    } catch (_) {}

    final toAdd = <String>[];

    final standardDeps = {
      'flutter_bloc': '  flutter_bloc: ^8.0.0',
      'get_it': '  get_it: ^7.0.0',
      'go_router': '  go_router: ^14.0.0',
      'intl': '  intl: any',
      'magickit': '  magickit: ^${VersionCommand.uiKitVersion}',
    };

    for (final entry in standardDeps.entries) {
      if (!existingDeps.contains(entry.key)) {
        toAdd.add(entry.value);
      }
    }

    if (!existingDeps.contains('flutter_localizations')) {
      toAdd.add('  flutter_localizations:\n    sdk: flutter');
    }

    if (toAdd.isEmpty) {
      logger.info('pubspec.yaml: dependencies sudah lengkap');
      return;
    }

    // Insert right after `dependencies:` line
    final marker = 'dependencies:';
    final markerIdx = content.indexOf(marker);
    if (markerIdx != -1) {
      final insertIdx = content.indexOf('\n', markerIdx) + 1;
      content =
          '${content.substring(0, insertIdx)}${toAdd.join('\n')}\n${content.substring(insertIdx)}';
      pubspecFile.writeAsStringSync(content);
      logger.success('pubspec.yaml: dependencies berhasil ditambahkan');
      for (final dep in toAdd) {
        logger.info('  + ${dep.trim().split(':').first}');
      }
    }
  }

  Future<void> _runFlutterPubGet() async {
    logger.info('Menjalankan flutter pub get...');
    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      logger.success('flutter pub get berhasil');
    } else {
      logger.warn('flutter pub get gagal. Jalankan manual: flutter pub get');
      final err = result.stderr.toString().trim();
      if (err.isNotEmpty) logger.info(err);
    }
  }

  Future<void> _runMagickitL10n() async {
    logger.info('Menjalankan magickit l10n...');
    final result = await Process.run(
      'magickit',
      ['l10n'],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      logger.success('magickit l10n berhasil — AppLocalizations siap dipakai');
    } else {
      logger.warn('magickit l10n gagal. Jalankan manual: magickit l10n');
      final err = result.stderr.toString().trim();
      if (err.isNotEmpty) logger.info(err);
    }
  }

  void _writeMainDart() {
    final mainFile = File('lib/main.dart');
    mainFile.parent.createSync(recursive: true);

    String appClassName = 'MyApp';
    String appTitle = 'MagicKit App';

    // Parse existing main.dart to preserve class name and title
    if (mainFile.existsSync()) {
      final existing = mainFile.readAsStringSync();

      // Extract app widget class name from runApp(const ClassName())
      final runAppMatch =
          RegExp(r'runApp\(\s*(?:const\s+)?(\w+)\s*\(').firstMatch(existing);
      if (runAppMatch != null) {
        appClassName = runAppMatch.group(1)!;
      }

      // Extract title string
      final titleMatch = RegExp(r"title:\s*'([^']+)'").firstMatch(existing) ??
          RegExp(r'title:\s*"([^"]+)"').firstMatch(existing);
      if (titleMatch != null) {
        appTitle = titleMatch.group(1)!;
      }
    }

    final content = _buildMainDartContent(appClassName, appTitle);
    mainFile.writeAsStringSync(content);
    logger.success(
        'lib/main.dart berhasil diupdate dengan MagicTheme + routing setup');
  }

  static String _buildMainDartContent(String appClassName, String appTitle) {
    return """import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:magickit/magickit.dart';
import 'core/dependency_injection/injection.dart';
import 'core/routes/route_config.dart';
import 'core/assets/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDependencies();
  runApp(const $appClassName());
}

class $appClassName extends StatelessWidget {
  const $appClassName({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '$appTitle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        extensions: [
          MagicTheme(
            colors: MagicColors.light(),
            typography: MagicTypography(),
            spacing: MagicSpacing(),
            radius: MagicRadius(),
            shadows: MagicShadows(),
          ),
        ],
      ),
      routerConfig: routeConfig,
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
""";
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
      - l10n                         
    group:
      icons: icons/                  
      illustrations: illustrations/  
      images: images/               
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

  # Page generation
  page:
    output: lib/features/
  
  # Routing
  routes:
    output: lib/core/routes/

  # API / Model generation
  api:
    input: api_schemas/
    output: lib/data/models/
    generate_repository: true

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
