import 'dart:io';

import 'package:magickit_cli/src/generators/route_generator.dart';
import 'package:magickit_cli/src/utils/app_smoke_test.dart';
import 'package:magickit_cli/src/utils/dart_source_edits.dart';
import 'package:magickit_cli/src/utils/version_utils.dart';
import 'package:magickit_cli/src/version.g.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('initial location', () {
    test('raw \\\\s does not match a normal initialLocation line', () {
      const sample = "  initialLocation: '/',";
      expect(RegExp(r"initialLocation:\\s*'[^']*'").hasMatch(sample), isFalse);
      expect(initialLocationPattern.hasMatch(sample), isTrue);
    });

    test('rewrites the location to the splash route constant', () {
      const sample = '''
final routeConfig = GoRouter(
  initialLocation: '/',
  routes: [],
);
''';
      final updated = setInitialLocation(
        sample,
        'StartupRoutePath.splashPath',
      );
      expect(updated, contains('initialLocation: StartupRoutePath.splashPath'));
      expect(updated, isNot(contains("initialLocation: '/'")));
    });
  });

  group('import insertion', () {
    const before = """
import 'package:go_router/go_router.dart';
import 'startup_route_names.dart';

final startupRoutes = <RouteBase>[
];
""";

    test('puts the new import on its own line', () {
      final updated = insertDartImport(
        before,
        "import '../splash/presentation/pages/splash_page.dart';",
      );

      expect(updated, isNot(contains("';final")));
      expect(
        updated,
        contains(
          "import 'startup_route_names.dart';\n"
          "import '../splash/presentation/pages/splash_page.dart';\n"
          '\n'
          'final startupRoutes',
        ),
      );
    });

    test('does not insert the same import twice', () {
      const line = "import '../splash/presentation/pages/splash_page.dart';";
      final once = insertDartImport(before, line);
      expect(insertDartImport(once, line), once);
    });

    test('route generator keeps feature imports on separate lines', () {
      final previous = Directory.current;
      final temp = Directory.systemTemp.createTempSync('magickit_routes_');
      try {
        Directory.current = temp.path;
        final gen = RouteGenerator();
        for (final files in [
          gen.generateCoreRouteFiles(),
          gen.generateFeatureRouteFiles('startup'),
        ]) {
          for (final entry in files.entries) {
            final file = File(entry.key);
            file.parent.createSync(recursive: true);
            file.writeAsStringSync(entry.value);
          }
        }
        gen.updateCoreForFeature('startup');
        gen.updateRouteFilesForPage('startup', 'splash', const [], const []);

        final routes = File('lib/features/startup/routes/startup_routes.dart')
            .readAsStringSync();
        expect(routes, isNot(contains("';final")));
        expect(RegExp(r"';[ \t]*final").hasMatch(routes), isFalse);
        expect(
          routes,
          contains("import '../splash/presentation/pages/splash_page.dart';\n"),
        );

        var config = File('lib/core/routes/route_config.dart').readAsStringSync();
        expect(config, isNot(contains("';final")));
        config = insertDartImport(
          config,
          "import '../../features/startup/routes/startup_route_names.dart';",
        );
        config = setInitialLocation(config, 'StartupRoutePath.splashPath');
        expect(
          config,
          contains('initialLocation: StartupRoutePath.splashPath'),
        );
        expect(
          config,
          contains(
            "import '../../features/startup/routes/startup_route_names.dart';\n",
          ),
        );
        expect(config, isNot(contains("';final")));
      } finally {
        Directory.current = previous;
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      }
    });
  });

  group('widget smoke test', () {
    test('init and kickstart tests await configureDependencies', () {
      final previous = Directory.current;
      final temp = Directory.systemTemp.createTempSync('magickit_smoke_');
      try {
        Directory.current = temp.path;
        writeAppSmokeTest(appName: 'demo', appClassName: 'MyApp');
        final initTest = File('test/widget_test.dart').readAsStringSync();
        expect(initTest, contains('await configureDependencies()'));
        expect(initTest, contains('package:demo/core/dependency_injection/injector.dart'));
        expect(initTest, contains('package:demo/main.dart'));
        expect(initTest, contains('const MyApp()'));
        expect(initTest, isNot(contains("find.text('0')")));

        writeAppSmokeTest(
          appName: 'demo',
          appClassName: 'MyApp',
          expectKickstartFlow: true,
        );
        final kickstartTest = File('test/widget_test.dart').readAsStringSync();
        expect(kickstartTest, contains('await configureDependencies()'));
        expect(kickstartTest, contains("find.text('MagicKit')"));
        expect(kickstartTest, contains("find.text('Welcome')"));
        expect(kickstartTest, contains('Duration(seconds: 2)'));
      } finally {
        Directory.current = previous;
        if (temp.existsSync()) temp.deleteSync(recursive: true);
      }
    });
  });

  group('ui kit version', () {
    test('compiled uiKitVersion matches packages/magickit/pubspec.yaml', () {
      final pubspec = _uiKitPubspec();
      final doc = loadYaml(pubspec.readAsStringSync());
      expect(doc, isA<YamlMap>());
      expect(uiKitVersion, (doc as YamlMap)['version']);
      expect(VersionUtils.compiledUiKitVersion(), uiKitVersion);
      expect(VersionUtils.readUiKitVersion(), uiKitVersion);
      expect(
        VersionUtils.readUiKitVersion(allowFilesystem: false),
        uiKitVersion,
      );
      expect(uiKitVersion, isNot('unknown'));
    });

    test('compiled packageVersion matches the CLI pubspec', () {
      final pubspec = _cliPubspec();
      final doc = loadYaml(pubspec.readAsStringSync()) as YamlMap;
      expect(packageVersion, doc['version']);
    });
  });
}

File _uiKitPubspec() {
  for (final path in [
    '../magickit/pubspec.yaml',
    'packages/magickit/pubspec.yaml',
  ]) {
    final file = File(path);
    if (file.existsSync()) return file;
  }
  fail('packages/magickit/pubspec.yaml not found from ${Directory.current.path}');
}

File _cliPubspec() {
  for (final path in ['pubspec.yaml', 'packages/magickit_cli/pubspec.yaml']) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final doc = loadYaml(file.readAsStringSync());
    if (doc is YamlMap && doc['name'] == 'magickit_cli') return file;
  }
  fail('magickit_cli pubspec.yaml not found from ${Directory.current.path}');
}
