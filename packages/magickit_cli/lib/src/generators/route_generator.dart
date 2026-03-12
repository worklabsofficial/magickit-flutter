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

  // ── Import Helpers ─────────────────────────────────────────────────────────

  String _ensureImport(String content, String importLine) {
    final escaped = RegExp.escape(importLine.trim());
    final exactLine = RegExp('^\\s*$escaped\\s*', multiLine: true);
    content = content.replaceAll(exactLine, '').replaceAll('\n\n\n', '\n\n');

    final lastImportEnd = _lastImportEnd(content);
    if (lastImportEnd == -1) {
      return '$importLine\n$content';
    }
    return '${content.substring(0, lastImportEnd)}\n$importLine${content.substring(lastImportEnd)}';
  }

  String _ensureImportAfterSuffix(
    String content,
    String suffix,
    String importLine,
  ) {
    final escaped = RegExp.escape(importLine.trim());
    final exactLine = RegExp('^\\s*$escaped\\s*', multiLine: true);
    content = content.replaceAll(exactLine, '').replaceAll('\n\n\n', '\n\n');

    final end = _importLineEndBySuffix(content, suffix);
    if (end == -1) {
      return _ensureImport(content, importLine);
    }
    return '${content.substring(0, end)}\n$importLine${content.substring(end)}';
  }

  int _lastImportEnd(String content) {
    final reg =
        RegExp("^import\\s+['\"][^'\"]+['\"];\\s*", multiLine: true);
    final matches = reg.allMatches(content).toList();
    if (matches.isEmpty) return -1;
    return matches.last.end;
  }

  int _importLineEndBySuffix(String content, String suffix) {
    final reg =
        RegExp("^import\\s+['\"]([^'\"]+)['\"];\\s*", multiLine: true);
    for (final match in reg.allMatches(content)) {
      final path = match.group(1) ?? '';
      if (path.endsWith(suffix)) return match.end;
    }
    return -1;
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
    content = _ensureImport(content, importLine);

    // Remove TODO comment if present (supports legacy text)
    content = content
        .replaceAll(
          '    // TODO: Routes akan otomatis ditambahkan oleh magickit feature\n',
          '',
        )
        .replaceAll(
          '    // TODO: Routes akan otomatis ditambahkan oleh magickit page\n',
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

    // Remove TODO comment if only that remains (supports legacy text)
    content = content
        .replaceAll(
          '// TODO: Export akan otomatis ditambahkan oleh magickit feature\n',
          '',
        )
        .replaceAll(
          '// TODO: Export akan otomatis ditambahkan oleh magickit page\n',
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

    content = content
        .replaceAll(
          '// TODO: Export akan otomatis ditambahkan oleh magickit feature\n',
          '',
        )
        .replaceAll(
          '// TODO: Export akan otomatis ditambahkan oleh magickit page\n',
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
    var content = file.readAsStringSync();
    content = _migrateRouteNamesIfNeeded(feature, content);
    if (content.contains("$pageCamel =") ||
        content.contains("${pageCamel}Path =")) {
      file.writeAsStringSync(content);
      return; // idempotent
    }

    final routeName = _routeNameValue(feature, page);
    final routePath = _routePath(feature, page, pathParams);
    final pathStr = '${pageCamel}Path';

    final nameBuffer = StringBuffer()
      ..writeln()
      ..writeln('  static const String $pageCamel = \'$routeName\';');

    final pathBuffer = StringBuffer()
      ..writeln()
      ..writeln('  static const String $pathStr = \'$routePath\';');

    final keyBuffer = StringBuffer()..writeln();
    for (final param in pathParams) {
      final keyName = _pathParamKey(page, param);
      keyBuffer.writeln("  static const String $keyName = '$param';");
    }

    content = _insertIntoClass(
      content,
      '${toPascalCase(feature)}RouteName',
      nameBuffer.toString(),
    );
    content = _insertIntoClass(
      content,
      '${toPascalCase(feature)}RoutePath',
      pathBuffer.toString(),
    );
    if (pathParams.isNotEmpty) {
      content = _insertIntoClass(
        content,
        '${toPascalCase(feature)}RouteKey',
        keyBuffer.toString(),
      );
    }

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

    final original = file.readAsStringSync();
    var content = _normalizeImports(original);
    content = _migrateRouteUsageClasses(pascal, content);
    if (content.contains(pageFile)) {
      if (content != original) {
        file.writeAsStringSync(content);
      }
      return; // idempotent
    }

    // Add import for page file
    final pageImport =
        "import '../$pageSnake/presentation/pages/${pageSnake}_page.dart';";
    content = _ensureImport(content, pageImport);

    // Add route_query_keys import if needed
    if (queryParams.isNotEmpty) {
      content = _ensureImportAfterSuffix(
        content,
        'route_names.dart',
        "import '../../../core/routes/route_query_keys.dart';",
      );
    }

    // Build route entry
    final routeBuffer = StringBuffer();
    routeBuffer.writeln('  GoRoute(');
    routeBuffer.writeln(
        '    name: ${pascal}RouteName.$pageCamel,');
    routeBuffer.writeln(
        '    path: ${pascal}RoutePath.${pageCamel}Path,');

    final hasParams = pathParams.isNotEmpty || queryParams.isNotEmpty;
    if (!hasParams) {
      routeBuffer.writeln(
          '    builder: (context, state) => const $pageFile(),');
    } else {
      routeBuffer.writeln('    builder: (context, state) {');
      for (final p in pathParams) {
        final keyName = _pathParamKey(page, p);
        routeBuffer.writeln(
            "      final $p = state.pathParameters[${pascal}RouteKey.$keyName] ?? '';");
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

  String _normalizeImports(String content) {
    final reg = RegExp("^\\s*import\\s+[^;]+;\\s*\$",
        multiLine: true);
    final matches = reg.allMatches(content).toList();
    if (matches.isEmpty) return content;

    final imports = <String>[];
    for (final match in matches) {
      final line = match.group(0)!.trim();
      if (!imports.contains(line)) imports.add(line);
    }

    content = content.replaceAll(reg, '').replaceAll('\n\n\n', '\n\n');

    var insertAt = 0;
    if (content.startsWith('// GENERATED BY MAGICKIT CLI')) {
      final firstLineEnd = content.indexOf('\n');
      insertAt = firstLineEnd == -1 ? content.length : firstLineEnd + 1;
      if (insertAt < content.length && content[insertAt] == '\n') {
        insertAt += 1;
      }
    }

    final importBlock = '${imports.join('\n')}\n';
    return '${content.substring(0, insertAt)}$importBlock${content.substring(insertAt)}';
  }

  String _insertIntoClass(
    String content,
    String className,
    String snippet,
  ) {
    final classStart = content.indexOf('class $className');
    if (classStart == -1) return content;
    final classEnd = content.indexOf('}', classStart);
    if (classEnd == -1) return content;
    return '${content.substring(0, classEnd)}$snippet${content.substring(classEnd)}';
  }

  String _migrateRouteNamesIfNeeded(String feature, String content) {
    final pascal = toPascalCase(feature);
    if (content.contains('class ${pascal}RoutePath') &&
        content.contains('class ${pascal}RouteKey')) {
      return content;
    }

    final className = '${pascal}RouteName';
    final classStart = content.indexOf('class $className');
    if (classStart == -1) return content;
    final bodyStart = content.indexOf('{', classStart);
    final bodyEnd = content.indexOf('}', bodyStart);
    if (bodyStart == -1 || bodyEnd == -1) return content;

    final body = content.substring(bodyStart + 1, bodyEnd);
    final reg =
        RegExp(r"static const String\s+(\w+)\s*=\s*'[^']*';");

    final nameLines = <String>[];
    final pathLines = <String>[];
    final keyLines = <String>[];

    for (final match in reg.allMatches(body)) {
      final line = match.group(0)!.trim();
      final varName = match.group(1) ?? '';
      if (varName.endsWith('Path')) {
        pathLines.add('  $line');
      } else if (varName.contains('Key')) {
        keyLines.add('  $line');
      } else {
        nameLines.add('  $line');
      }
    }

    return _buildRouteNamesFile(pascal, nameLines, pathLines, keyLines);
  }

  String _migrateRouteUsageClasses(String pascal, String content) {
    final pathReg =
        RegExp('${pascal}RouteName\\.([A-Za-z0-9_]+Path)');
    final keyReg =
        RegExp('${pascal}RouteName\\.([A-Za-z0-9_]*Key[A-Za-z0-9_]*)');

    content = content.replaceAllMapped(
      pathReg,
      (m) => '${pascal}RoutePath.${m.group(1)}',
    );
    content = content.replaceAllMapped(
      keyReg,
      (m) => '${pascal}RouteKey.${m.group(1)}',
    );
    return content;
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

    final original = file.readAsStringSync();
    var content = _migrateRouteUsageClasses(pascal, original);
    if (content.contains(pushMethod)) {
      if (content != original) {
        file.writeAsStringSync(content);
      }
      return; // idempotent
    }

    // Add route_query_keys import if needed
    if (queryParams.isNotEmpty) {
      content = _ensureImportAfterSuffix(
        content,
        'route_names.dart',
        "import '../../../core/routes/route_query_keys.dart';",
      );
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
              '          ${pascal}RouteKey.$keyName: $p,');
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
    // TODO: Routes akan otomatis ditambahkan oleh magickit page
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: \${state.uri}')),
  ),
);
''';

  String _routeNamesTemplate() => '''
// GENERATED BY MAGICKIT CLI

// TODO: Export akan otomatis ditambahkan oleh magickit page
''';

  String _routeExtensionsTemplate() => '''
// GENERATED BY MAGICKIT CLI

// TODO: Export akan otomatis ditambahkan oleh magickit page
''';

  String _routeQueryKeysTemplate() => '''
// GENERATED BY MAGICKIT CLI

class RouteQueryKey {
  RouteQueryKey._();

  // TODO: Keys akan otomatis ditambahkan oleh magickit page --query-params
}
''';

  String _featureRouteNamesTemplate(String pascal) =>
      _buildRouteNamesFile(pascal, const [], const [], const []);

  String _buildRouteNamesFile(
    String pascal,
    List<String> nameLines,
    List<String> pathLines,
    List<String> keyLines,
  ) {
    final buf = StringBuffer()
      ..writeln('// GENERATED BY MAGICKIT CLI')
      ..writeln()
      ..writeln('class ${pascal}RouteName {')
      ..writeln('  ${pascal}RouteName._();');
    for (final line in nameLines) {
      buf.writeln(line);
    }
    buf
      ..writeln('}')
      ..writeln()
      ..writeln('class ${pascal}RoutePath {')
      ..writeln('  ${pascal}RoutePath._();');
    for (final line in pathLines) {
      buf.writeln(line);
    }
    buf
      ..writeln('}')
      ..writeln()
      ..writeln('class ${pascal}RouteKey {')
      ..writeln('  ${pascal}RouteKey._();');
    for (final line in keyLines) {
      buf.writeln(line);
    }
    buf.writeln('}');
    return buf.toString();
  }

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
