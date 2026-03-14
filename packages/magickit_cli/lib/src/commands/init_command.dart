import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:yaml/yaml.dart';
import '../generators/page_generator.dart';
import '../generators/route_generator.dart';
import '../utils/di_utils.dart';
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

    final appName = _readAppName();

    // 4. Create lib/core/base/ with MagicCubit + base classes
    _createDir('lib/core/base');
    _createFile('lib/core/base/magic_cubit.dart', _magicCubitContent);
    _createFile('lib/core/base/magic_state_page.dart', _magicStatePageContent);
    _createFile('lib/core/base/magic_either.dart', _magicEitherContent);
    _createFile('lib/core/base/magic_failure.dart', _magicFailureContent);
    _createFile('lib/core/base/magic_server_exception.dart',
        _magicServerExceptionContent);
    logger.success(
        'lib/core/base/ berhasil dibuat (MagicCubit, MagicStatePage, MagicEither, MagicFailure, MagicServerException)');

    // 5. Create lib/core/dependency_injection/
    _createDir('lib/core/dependency_injection');
    _createFile('lib/core/dependency_injection/injector.dart',
        _buildInjectorContent(appName));
    logger
        .success('lib/core/dependency_injection/injector.dart berhasil dibuat');

    // 5b. Create lib/core/network/
    _createDir('lib/core/network');
    _createFile('lib/core/network/token_manager.dart', _tokenManagerContent);
    _createFile('lib/core/network/base_urls.dart', _baseUrlsStubContent);
    logger
        .success('lib/core/network/ berhasil dibuat (TokenManager, BaseUrls)');

    // 5c. Create lib/core/storage/
    _createDir('lib/core/storage');
    _createFile('lib/core/storage/secure_storage_helper.dart',
        _secureStorageHelperContent);
    logger.success('lib/core/storage/ berhasil dibuat (SecureStorageHelper)');

    // 6. Create remote/ folder with example
    _createDir('remote/shared');
    _createDir('remote/auth');
    _createFile('remote/shared/auth.json', _remoteAuthServiceJson);
    _createFile('remote/auth/login_page.json', _remoteLoginPageJson);
    logger.success('remote/ berhasil dibuat (contoh: auth/login_page.json)');

    // 7. Create lib/core/assets/
    _createDir('lib/core/assets');
    logger.success('lib/core/assets/ berhasil dibuat');

    // 8. Create lib/core/routes/
    final routeGenerator = RouteGenerator();
    final routeFiles = routeGenerator.generateCoreRouteFiles();
    for (final entry in routeFiles.entries) {
      _createFile(entry.key, entry.value);
    }
    logger.success(
        'lib/core/routes/ berhasil dibuat (route_config, route_names, route_extensions, route_query_keys)');

    // 8b. Create default startup/splash page
    await _createDefaultStartupSplash(appName);

    // 9. Replace main.dart
    _writeMainDart();

    // 10. Inject dependencies ke pubspec.yaml
    _injectPubspecDeps();
    _injectPubspecAssets();

    logger.info('');
    logger.info('Struktur project:');
    logger.info('  remote/                        ← API schema definitions');
    logger.info('  ├── shared/');
    logger
        .info('  │   └── auth.json               ← contoh service definition');
    logger.info('  └── auth/');
    logger.info('      └── login_page.json         ← contoh page definition');
    logger.info('  assets/');
    logger.info('  ├── icons/ illustrations/ images/');
    logger.info('  └── l10n/  en.json  id.json');
    logger.info('  lib/core/');
    logger.info(
        '  ├── base/       ← MagicCubit, MagicStatePage, MagicEither, MagicFailure, MagicServerException');
    logger.info('  ├── network/    ← TokenManager, BaseUrls');
    logger.info('  ├── storage/    ← SecureStorageHelper');
    logger.info('  ├── dependency_injection/ (injector.dart)');
    logger.info('  └── routes/');
    logger.info('');
    logger.info('Next steps:');
    logger.info('  1. Edit magickit.yaml → api.base_urls');
    logger.info('  2. Edit remote/shared/auth.json → sesuaikan endpoint');
    logger.info('  3. Jalankan: magickit api auth login_page.json');

    // 11. flutter pub get
    await _runFlutterPubGet();

    // 12. magickit l10n (template files sudah siap)
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
      'flutter_secure_storage': '  flutter_secure_storage: ^9.2.2',
      'get_it': '  get_it: ^7.0.0',
      'go_router': '  go_router: ^14.0.0',
      'intl': '  intl: any',
      'http': '  http: ^1.2.0',
      'equatable': '  equatable: ^2.0.5',
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

  void _injectPubspecAssets() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      logger.warn('pubspec.yaml tidak ditemukan, skip assets injection.');
      return;
    }

    var content = pubspecFile.readAsStringSync();

    var hasAssetsEntry = false;
    var hasUsesMaterialDesign = false;
    final requiredAssets = [
      'assets/icons/',
      'assets/illustrations/',
      'assets/images/',
    ];
    try {
      final yaml = loadYaml(content) as YamlMap?;
      final flutter = yaml?['flutter'];
      if (flutter is YamlMap) {
        final umd = flutter['uses-material-design'];
        hasUsesMaterialDesign = umd == true;
        final assets = flutter['assets'];
        if (assets is YamlList) {
          final existing = assets.map((a) => a.toString().trim()).toSet();
          hasAssetsEntry = requiredAssets.every(existing.contains);
        }
      }
    } catch (_) {}

    if (hasAssetsEntry && hasUsesMaterialDesign) {
      logger.info('pubspec.yaml: assets sudah terdaftar');
      return;
    }

    final lines = content.split('\n');
    final flutterIdx = lines.indexWhere(
      (l) => l.trim() == 'flutter:' && _indentOf(l) == 0,
    );

    if (flutterIdx == -1) {
      lines.addAll([
        '',
        'flutter:',
        '  uses-material-design: true',
        '  assets:',
        for (final asset in requiredAssets) '    - $asset',
      ]);
      pubspecFile.writeAsStringSync(lines.join('\n'));
      logger.success('pubspec.yaml: assets berhasil ditambahkan');
      for (final asset in requiredAssets) {
        logger.info('  + $asset');
      }
      return;
    }

    final flutterIndent = _indentOf(lines[flutterIdx]);
    var assetsIdx = -1;
    var blockEnd = lines.length;
    var usesMaterialIdx = -1;

    for (var i = flutterIdx + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final indent = _indentOf(line);
      if (indent <= flutterIndent) {
        blockEnd = i;
        break;
      }
      if (line.trim().startsWith('uses-material-design:')) {
        usesMaterialIdx = i;
      }
      if (line.trim() == 'assets:') {
        assetsIdx = i;
        break;
      }
    }

    final insertedUsesMaterial = usesMaterialIdx == -1;
    if (insertedUsesMaterial) {
      final insertAt = flutterIdx + 1;
      final indent = ' ' * (flutterIndent + 2);
      lines.insert(insertAt, '${indent}uses-material-design: true');
    }

    if (assetsIdx != -1 && insertedUsesMaterial) {
      if (flutterIdx + 1 <= assetsIdx) {
        assetsIdx += 1;
      }
    }

    if (assetsIdx == -1) {
      final effectiveUsesMaterialIdx =
          usesMaterialIdx == -1 && insertedUsesMaterial
              ? flutterIdx + 1
              : usesMaterialIdx;
      final insertAt = effectiveUsesMaterialIdx != -1
          ? effectiveUsesMaterialIdx + 1
          : flutterIdx + 1;
      final indent = ' ' * (flutterIndent + 2);
      lines.insertAll(insertAt, [
        '${indent}assets:',
        for (final asset in requiredAssets) '${indent}  - $asset',
      ]);
      pubspecFile.writeAsStringSync(lines.join('\n'));
      logger.success('pubspec.yaml: assets berhasil ditambahkan');
      for (final asset in requiredAssets) {
        logger.info('  + $asset');
      }
      return;
    }

    final assetsIndent = _indentOf(lines[assetsIdx]);
    var assetsEnd = blockEnd;
    for (var i = assetsIdx + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().isEmpty) continue;
      final indent = _indentOf(line);
      if (indent <= assetsIndent) {
        assetsEnd = i;
        break;
      }
    }

    final existing = lines
        .sublist(assetsIdx + 1, assetsEnd)
        .map((l) => l.trim())
        .where((l) => l.startsWith('-'))
        .map((l) => l.substring(1).trim())
        .toSet();

    final indent = ' ' * (assetsIndent + 2);
    var inserted = false;
    var insertAt = assetsIdx + 1;
    for (final asset in requiredAssets) {
      if (!existing.contains(asset)) {
        lines.insert(insertAt, '${indent}- $asset');
        insertAt += 1;
        inserted = true;
      }
    }

    if (inserted || insertedUsesMaterial) {
      pubspecFile.writeAsStringSync(lines.join('\n'));
      logger.success('pubspec.yaml: assets berhasil ditambahkan');
      for (final asset in requiredAssets) {
        if (!existing.contains(asset)) {
          logger.info('  + $asset');
        }
      }
    } else {
      logger.info('pubspec.yaml: assets sudah terdaftar');
    }
  }

  int _indentOf(String line) {
    var count = 0;
    for (final ch in line.split('')) {
      if (ch == ' ') {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  Future<void> _createDefaultStartupSplash(String appName) async {
    const feature = 'startup';
    const page = 'splash';
    final outputDir = 'lib/features/$feature';

    logger.info('');
    logger.magicInfo('Creating default startup/splash page');

    final routeGenerator = RouteGenerator();
    final featureRoutes = routeGenerator.generateFeatureRouteFiles(feature);
    for (final entry in featureRoutes.entries) {
      final file = File(entry.key);
      if (file.existsSync()) continue;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    routeGenerator.updateCoreForFeature(feature);

    final pageGenerator = PageGenerator();
    await pageGenerator.generate(
      name: page,
      outputDir: outputDir,
    );

    routeGenerator.updateRouteFilesForPage(feature, page, [], []);

    final injectorFile = File('lib/core/dependency_injection/injector.dart');
    if (injectorFile.existsSync()) {
      final content = injectorFile.readAsStringSync();
      if (content.contains('// MAGICKIT:INJECTOR') &&
          content.contains('// MAGICKIT:IMPORT')) {
        final featureUpdated =
            DiUtils.updateFeatureInjector(feature: feature, page: page);
        final globalUpdated =
            DiUtils.updateGlobalInjector(appName: appName, feature: feature);
        if (featureUpdated || globalUpdated) {
          logger.info('DI updated for feature: $feature');
        }
      }
    }

    logger.success('startup/splash page generated');
  }

  String _readAppName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      return 'app';
    }
    try {
      final yaml = loadYaml(pubspec.readAsStringSync());
      final name = yaml is YamlMap ? yaml['name']?.toString() : null;
      if (name != null && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {}
    return 'app';
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
import 'core/dependency_injection/injector.dart';
import 'core/routes/route_config.dart';
import 'core/assets/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
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

  static String _buildInjectorContent(String appName) => '''
// GENERATED BY MAGICKIT CLI

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:$appName/core/network/token_manager.dart';
// MAGICKIT:IMPORT

final getIt = GetIt.instance;

void configureDependencies() {
  // ── Core ─────────────────────────────────────────────
  getIt.registerLazySingleton(() => http.Client());
  getIt.registerLazySingleton<TokenManager>(
    () => TokenManagerImpl(),
  );

  // MAGICKIT:INJECTOR
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

  # API
  api:
    base_urls:
      main_api: https://api.example.com/v1
      auth_api: https://auth.example.com/v1

  # Slicing
  slicing:
    ai_provider: gemini
    model: gemini-1.5-flash
    ai_api_key: ""
    figma_api_key: ""
    output: lib/generated/sliced_ui.dart
    prompt_output: lib/generated/slicing_prompt.txt
    use_local_components: true
    use_package_components: true
    registry_output: lib/src/registry/
''';

  static const _magicFailureContent = '''
abstract class MagicFailure {
  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;

  const MagicFailure({
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });
}

class MagicServerFailure extends MagicFailure {
  final int statusCode;

  const MagicServerFailure({
    required this.statusCode,
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });

  bool get isRetryable => statusCode >= 500 || statusCode == 408;
}

class MagicGeneralFailure extends MagicFailure {
  const MagicGeneralFailure({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}
''';

  static const _magicServerExceptionContent = '''
class MagicServerException implements Exception {
  final int statusCode;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const MagicServerException({
    required this.statusCode,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  bool get isRetryable => statusCode >= 500 || statusCode == 408;

  @override
  String toString() => 'MagicServerException(\$statusCode): \$message';
}
''';

  static const _magicEitherContent = """
import 'package:flutter/foundation.dart';

/// Interface for [MagicEither] data value in [MagicLeft] or [MagicRight]
abstract class MagicEither<L, R> {
  /// Function to call function if in [MagicLeft] and if in [MagicRight]
  B fold<B>(
    B Function(L left) ifLeft,
    B Function(R right) ifRight,
  );
}

/// Class value [MagicEither] if in [MagicLeft]
class MagicLeft<L, R> extends MagicEither<L, R> {
  MagicLeft(this._l);

  final L _l;
  L get value => _l;

  @override
  B fold<B>(
    B Function(L l) ifLeft,
    B Function(R r) ifRight,
  ) =>
      ifLeft(_l);

  @override
  bool operator ==(other) {
    if (other is MagicLeft) {
      final otherList = other._l;
      if (otherList is List) {
        return listEquals(otherList, _l is List ? _l as List : [_l]);
      }
    }
    return other is MagicLeft && other._l == _l;
  }

  @override
  int get hashCode => _l.hashCode;
}

/// Class value [MagicEither] if in [MagicRight]
class MagicRight<L, R> extends MagicEither<L, R> {
  MagicRight(this._r);

  final R _r;
  R get value => _r;

  @override
  B fold<B>(
    B Function(L l) ifLeft,
    B Function(R r) ifRight,
  ) =>
      ifRight(_r);

  @override
  bool operator ==(other) {
    if (other is MagicRight) {
      final otherList = other._r;
      if (otherList is List) {
        return listEquals(otherList, _r is List ? _r as List : [_r]);
      }
    }
    return other is MagicRight && other._r == _r;
  }

  @override
  int get hashCode => _r.hashCode;
}
""";

  static const _tokenManagerContent = '''
import '../storage/secure_storage_helper.dart';

abstract class TokenManager {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

/// Default implementation using FlutterSecureStorage.
class TokenManagerImpl implements TokenManager {
  final SecureStorageHelper _storage;

  TokenManagerImpl({SecureStorageHelper? storage})
      : _storage = storage ?? SecureStorageHelper();

  @override
  Future<String?> getToken() => _storage.get(SecureStorageKeys.authToken);

  @override
  Future<void> saveToken(String token) =>
      _storage.save(SecureStorageKeys.authToken, token);

  @override
  Future<void> clearToken() => _storage.delete(SecureStorageKeys.authToken);
}
''';

  static const _secureStorageHelperContent = '''
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Simple helper to wrap FlutterSecureStorage read/write/delete.
class SecureStorageHelper {
  SecureStorageHelper({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> save(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> get(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }
}

class SecureStorageKeys {
  static const authToken = 'auth_token';
}
''';

  static const _baseUrlsStubContent = '''
// Generated by magickit api — update via magickit.yaml (api.base_urls)
// Run: magickit api
class BaseUrls {
  // Add your base URLs in magickit.yaml then run: magickit api
}
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

  // ─── remote/ example files ──────────────────────────────────────────────────

  static const _remoteAuthServiceJson = '''{
  "service": "auth",
  "endpoints": [
    {
      "name": "login",
      "base_url": { "\$ref": "magickit.yaml#api.base_urls.auth_api" },
      "path": "/auth/login",
      "method": "POST",
      "auth": false,
      "body": {
        "email": "string",
        "password": "string"
      },
      "response": {
        "token": "string",
        "user": {
          "id": "int",
          "name": "string",
          "email": "string"
        }
      }
    },
    {
      "name": "logout",
      "base_url": { "\$ref": "magickit.yaml#api.base_urls.auth_api" },
      "path": "/auth/logout",
      "method": "POST",
      "response": {
        "message": "string"
      }
    }
  ]
}
''';

  static const _remoteLoginPageJson = '''{
  "feature": "auth",
  "page": "login",
  "endpoints": [
    { "\$ref": "shared/auth.json#login" }
  ]
}
''';
}
