// ignore_for_file: unnecessary_brace_in_string_interps
import 'dart:io';
import '../utils/string_utils.dart';

class RouteGenerator {
  final String routesDir;
  final String featuresDir;

  RouteGenerator({
    this.routesDir = 'lib/core/routes',
    this.featuresDir = 'lib/features',
  });

  // ── Init: Core Route Files ───────────────────────────────────────────────────

  Map<String, String> generateCoreRouteFiles() => {
        '$routesDir/route_config.dart': _routeConfigTemplate(),
        '$routesDir/route_names.dart': _routeNamesTemplate(),
        '$routesDir/route_extensions.dart': _routeExtensionsTemplate(),
        '$routesDir/route_query_keys.dart': _routeQueryKeysTemplate(),
      };

  // ── Feature: Route Group Files ───────────────────────────────────────────────

  Map<String, String> generateFeatureRouteFiles(String feature) {
    final pascal = toPascalCase(feature);
    return {
      '$featuresDir/$feature/routes/${feature}_route_names.dart':
          _featureRouteNamesTemplate(pascal),
      '$featuresDir/$feature/routes/${feature}_routes.dart':
          _featureRoutesTemplate(feature, pascal),
      '$featuresDir/$feature/routes/${feature}_route_extensions.dart':
          _featureRouteExtensionsTemplate(feature, pascal),
    };
  }

  /// Update core route files setelah feature baru di-generate.
  void updateCoreForFeature(String feature) {
    _updateRouteConfig(feature);
    _updateCoreRouteNames(feature);
    _updateCoreRouteExtensions(feature);
  }

  // ── Page: Update Route Files ─────────────────────────────────────────────────

  /// Update semua route files setelah page baru di-generate.
  void updateRouteFilesForPage(
    String feature,
    String page,
    List<String> pathParams,
    List<String> queryParams,
  ) {
    _updateFeatureRouteNames(feature, page, pathParams, queryParams);
    _updateFeatureRoutes(feature, page, pathParams, queryParams);
    _updateFeatureRouteExtensions(feature, page, pathParams, queryParams);
    if (queryParams.isNotEmpty) {
      _updateRouteQueryKeys(queryParams);
    }
  }

  // ── Naming Helpers ───────────────────────────────────────────────────────────

  /// Strip feature prefix dari page name jika ada.
  /// product_list di feature product → list
  String _pageSegment(String feature, String page) {
    final prefix = '${feature}_';
    final stripped = page.startsWith(prefix) ? page.substring(prefix.length) : page;
    return stripped.replaceAll('_', '-');
  }

  /// Route name value: {feature}-{segment}
  String _routeNameValue(String feature, String page) {
    return '$feature-${_pageSegment(feature, page)}';
  }

  /// Route path: /{feature}/{segment}[/:param...]
  String _routePath(String feature, String page, List<String> pathParams) {
    final segment = _pageSegment(feature, page);
    final params = pathParams.map((p) => ':$p').join('/');
    return '/$feature/$segment${params.isEmpty ? '' : '/$params'}';
  }

  /// Push method name: push{PascalCase(page)}
  String _pushMethodName(String page) => 'push${toPascalCase(page)}';

  /// Path param key constant name: {pageCamel}Key{ParamPascal}
  String _pathParamKey(String page, String param) {
    return '${toCamelCase(page)}Key${toPascalCase(param)}';
  }

  // ── Core Update Methods ──────────────────────────────────────────────────────

  void _updateRouteConfig(String feature) {
    final file = File('$routesDir/route_config.dart');
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();
    final featureVar = '${feature}Routes';

    if (content.contains('...$featureVar')) return; // idempotent

    // Add import
    final importLine =
        "import '../../features/$feature/routes/${feature}_routes.dart';";
    if (!content.contains('${feature}_routes.dart')) {
      final lastImportEnd = content.lastIndexOf("';") + 2;
      content =
          '${content.substring(0, lastImportEnd)}\n$importLine${content.substring(lastImportEnd)}';
    }

    // Remove TODO comment if present
    content = content.replaceAll(
      '    // TODO: Routes akan otomatis ditambahkan oleh magickit feature\n',
      '',
    );

    // Add to routes list before closing ]
    final routesIdx = content.indexOf('routes: [');
    if (routesIdx != -1) {
      final closeBracket = content.indexOf(']', routesIdx);
      content =
          '${content.substring(0, closeBracket)}    ...$featureVar,\n  ${content.substring(closeBracket)}';
    }

    file.writeAsStringSync(content);
  }

  void _updateCoreRouteNames(String feature) {
    final file = File('$routesDir/route_names.dart');
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();
    final exportLine =
        "export '../../features/$feature/routes/${feature}_route_names.dart';";

    if (content.contains('${feature}_route_names.dart')) return;

    // Remove TODO comment if only that remains
    content = content.replaceAll(
      '// TODO: Export akan otomatis ditambahkan oleh magickit feature\n',
      '',
    );
    content = '${content.trimRight()}\n$exportLine\n';
    file.writeAsStringSync(content);
  }

  void _updateCoreRouteExtensions(String feature) {
    final file = File('$routesDir/route_extensions.dart');
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();
    final exportLine =
        "export '../../features/$feature/routes/${feature}_route_extensions.dart';";

    if (content.contains('${feature}_route_extensions.dart')) return;

    content = content.replaceAll(
      '// TODO: Export akan otomatis ditambahkan oleh magickit feature\n',
      '',
    );
    content = '${content.trimRight()}\n$exportLine\n';
    file.writeAsStringSync(content);
  }

  // ── Feature Route Update Methods ─────────────────────────────────────────────

  void _updateFeatureRouteNames(
    String feature,
    String page,
    List<String> pathParams,
    List<String> queryParams,
  ) {
    final file =
        File('$featuresDir/$feature/routes/${feature}_route_names.dart');
    if (!file.existsSync()) return;

    final pageCamel = toCamelCase(page);
    if (file.readAsStringSync().contains("$pageCamel =")) return; // idempotent

    var content = file.readAsStringSync();
    final routeName = _routeNameValue(feature, page);
    final routePath = _routePath(feature, page, pathParams);
    final pathStr = '${pageCamel}Path';

    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln('  static const String $pageCamel = \'$routeName\';');
    buffer.writeln('  static const String $pathStr = \'$routePath\';');
    for (final param in pathParams) {
      final keyName = _pathParamKey(page, param);
      buffer.writeln("  static const String $keyName = '$param';");
    }

    // Insert before closing } of class
    final classEnd = content.lastIndexOf('}');
    content =
        '${content.substring(0, classEnd)}${buffer.toString()}${content.substring(classEnd)}';
    file.writeAsStringSync(content);
  }

  void _updateFeatureRoutes(
    String feature,
    String page,
    List<String> pathParams,
    List<String> queryParams,
  ) {
    final file = File('$featuresDir/$feature/routes/${feature}_routes.dart');
    if (!file.existsSync()) return;

    final pascal = toPascalCase(feature);
    final pagePascal = toPascalCase(page);
    final pageCamel = toCamelCase(page);
    final pageSnake = toSnakeCase(pagePascal);
    final pageFile = '${pagePascal}Page';

    var content = file.readAsStringSync();
    if (content.contains(pageFile)) return; // idempotent

    // Add import for page file
    final pageImport =
        "import '../$pageSnake/presentation/pages/${pageSnake}_page.dart';";
    if (!content.contains('${pageSnake}_page.dart')) {
      // Add after last import
      final lastImportEnd = content.lastIndexOf("';") + 2;
      if (lastImportEnd > 1) {
        content =
            '${content.substring(0, lastImportEnd)}\n$pageImport${content.substring(lastImportEnd)}';
      }
    }

    // Add route_query_keys import if needed
    if (queryParams.isNotEmpty &&
        !content.contains('route_query_keys.dart')) {
      final routeNamesImportEnd =
          content.indexOf("route_names.dart';") + "route_names.dart';".length;
      content =
          '${content.substring(0, routeNamesImportEnd)}\nimport \'../../../core/routes/route_query_keys.dart\';${content.substring(routeNamesImportEnd)}';
    }

    // Build route entry
    final routeBuffer = StringBuffer();
    routeBuffer.writeln('  GoRoute(');
    routeBuffer.writeln(
        '    name: ${pascal}RouteName.$pageCamel,');
    routeBuffer.writeln(
        '    path: ${pascal}RouteName.${pageCamel}Path,');

    final hasParams = pathParams.isNotEmpty || queryParams.isNotEmpty;
    if (!hasParams) {
      routeBuffer.writeln(
          '    builder: (context, state) => const $pageFile(),');
    } else {
      routeBuffer.writeln('    builder: (context, state) {');
      for (final p in pathParams) {
        final keyName = _pathParamKey(page, p);
        routeBuffer.writeln(
            "      final $p = state.pathParameters[${pascal}RouteName.$keyName] ?? '';");
      }
      for (final q in queryParams) {
        routeBuffer.writeln(
            "      final $q = state.uri.queryParameters[RouteQueryKey.$q] ?? '';");
      }
      final allParams = [...pathParams, ...queryParams]
          .map((p) => '$p: $p')
          .join(', ');
      routeBuffer.writeln('      return $pageFile($allParams);');
      routeBuffer.writeln('    },');
    }
    routeBuffer.writeln('  ),');

    // Insert before closing ] of routes list
    final listEnd = content.lastIndexOf('];');
    content =
        '${content.substring(0, listEnd)}${routeBuffer.toString()}${content.substring(listEnd)}';
    file.writeAsStringSync(content);
  }

  void _updateFeatureRouteExtensions(
    String feature,
    String page,
    List<String> pathParams,
    List<String> queryParams,
  ) {
    final file =
        File('$featuresDir/$feature/routes/${feature}_route_extensions.dart');
    if (!file.existsSync()) return;

    final pascal = toPascalCase(feature);
    final pageCamel = toCamelCase(page);
    final pushMethod = _pushMethodName(page);

    var content = file.readAsStringSync();
    if (content.contains(pushMethod)) return; // idempotent

    // Add route_query_keys import if needed
    if (queryParams.isNotEmpty &&
        !content.contains('route_query_keys.dart')) {
      final routeNamesImportEnd =
          content.indexOf("route_names.dart';") + "route_names.dart';".length;
      content =
          '${content.substring(0, routeNamesImportEnd)}\nimport \'../../../core/routes/route_query_keys.dart\';${content.substring(routeNamesImportEnd)}';
    }

    // Build push method
    final methodBuffer = StringBuffer();
    methodBuffer.writeln();

    final allParams = [
      ...pathParams.map((p) => 'required String $p'),
      ...queryParams.map((p) => 'String? $p'),
    ];

    final hasParams = allParams.isNotEmpty;
    if (!hasParams) {
      methodBuffer.writeln(
          '  void $pushMethod() => pushNamed(${pascal}RouteName.$pageCamel);');
    } else {
      methodBuffer
          .writeln('  void $pushMethod({${allParams.join(', ')}}) => pushNamed(');
      methodBuffer.writeln('        ${pascal}RouteName.$pageCamel,');
      if (pathParams.isNotEmpty) {
        methodBuffer.writeln('        pathParameters: {');
        for (final p in pathParams) {
          final keyName = _pathParamKey(page, p);
          methodBuffer.writeln(
              '          ${pascal}RouteName.$keyName: $p,');
        }
        methodBuffer.writeln('        },');
      }
      if (queryParams.isNotEmpty) {
        methodBuffer.writeln('        queryParameters: {');
        for (final q in queryParams) {
          methodBuffer.writeln(
              '          if ($q != null) RouteQueryKey.$q: $q,');
        }
        methodBuffer.writeln('        },');
      }
      methodBuffer.writeln('      );');
    }

    // Insert before closing } of extension
    final extEnd = content.lastIndexOf('}');
    content =
        '${content.substring(0, extEnd)}${methodBuffer.toString()}${content.substring(extEnd)}';
    file.writeAsStringSync(content);
  }

  void _updateRouteQueryKeys(List<String> queryParams) {
    final file = File('$routesDir/route_query_keys.dart');
    if (!file.existsSync()) return;

    var content = file.readAsStringSync();
    var modified = false;

    // Remove TODO comment if first time
    if (content.contains('// TODO: Keys akan')) {
      content = content.replaceAll(
        '  // TODO: Keys akan otomatis ditambahkan oleh magickit page --query-params\n',
        '',
      );
    }

    for (final param in queryParams) {
      if (content.contains("String $param =")) continue;
      final keyLine = "  static const String $param = '$param';";
      // Insert before closing }
      final classEnd = content.lastIndexOf('}');
      content =
          '${content.substring(0, classEnd)}$keyLine\n${content.substring(classEnd)}';
      modified = true;
    }

    if (modified) file.writeAsStringSync(content);
  }

  // ── Templates ────────────────────────────────────────────────────────────────

  String _routeConfigTemplate() => '''
// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final routeConfig = GoRouter(
  initialLocation: '/',
  routes: [
    // TODO: Routes akan otomatis ditambahkan oleh magickit feature
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: \${state.uri}')),
  ),
);
''';

  String _routeNamesTemplate() => '''
// GENERATED BY MAGICKIT CLI

// TODO: Export akan otomatis ditambahkan oleh magickit feature
''';

  String _routeExtensionsTemplate() => '''
// GENERATED BY MAGICKIT CLI

// TODO: Export akan otomatis ditambahkan oleh magickit feature
''';

  String _routeQueryKeysTemplate() => '''
// GENERATED BY MAGICKIT CLI

class RouteQueryKey {
  RouteQueryKey._();

  // TODO: Keys akan otomatis ditambahkan oleh magickit page --query-params
}
''';

  String _featureRouteNamesTemplate(String pascal) => '''
// GENERATED BY MAGICKIT CLI

class ${pascal}RouteName {
  ${pascal}RouteName._();
}
''';

  String _featureRoutesTemplate(String feature, String pascal) => '''
// GENERATED BY MAGICKIT CLI

import 'package:go_router/go_router.dart';
import '${feature}_route_names.dart';

final ${feature}Routes = <RouteBase>[
];
''';

  String _featureRouteExtensionsTemplate(String feature, String pascal) => '''
// GENERATED BY MAGICKIT CLI

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '${feature}_route_names.dart';

extension ${pascal}RouteExtensions on BuildContext {
}
''';
}
