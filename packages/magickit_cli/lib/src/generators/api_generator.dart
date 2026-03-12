import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import '../utils/string_utils.dart';

// ---------------------------------------------------------------------------
// Public data structures
// ---------------------------------------------------------------------------

class EndpointDef {
  final String name;
  final String baseUrl; // resolved literal URL
  final String baseUrlKey; // camelCase key from base_urls.json / magickit.yaml
  final String path;
  final String method; // GET POST PUT PATCH DELETE
  final Map<String, String> headers;
  final Map<String, dynamic>? request; // query params schema
  final Map<String, dynamic>? body; // request body schema
  final Map<String, dynamic> response;
  final bool auth; // true by default

  const EndpointDef({
    required this.name,
    required this.baseUrl,
    required this.baseUrlKey,
    required this.path,
    required this.method,
    required this.headers,
    required this.request,
    required this.body,
    required this.response,
    required this.auth,
  });
}

class PageDef {
  final String feature;
  final String page;
  final List<EndpointDef> endpoints;

  const PageDef({
    required this.feature,
    required this.page,
    required this.endpoints,
  });
}

// ---------------------------------------------------------------------------
// Main ApiGenerator class
// ---------------------------------------------------------------------------

class ApiGenerator {
  final String appName;
  Map<String, dynamic>? _magickitConfigCache;

  ApiGenerator({required this.appName});

  static const String _markerBegin = '// MAGICKIT:BEGIN';
  static const String _markerEnd = '// MAGICKIT:END';

  static const int _maxRefDepth = 3;
  static const int _maxNestedDepth = 5;

  // Dart reserved words that need $ prefix
  static const _dartReserved = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch',
    'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do',
    'dynamic', 'else', 'enum', 'export', 'extends', 'extension', 'external',
    'factory', 'false', 'final', 'finally', 'for', 'Function', 'get', 'hide',
    'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow',
    'return', 'sealed', 'set', 'show', 'static', 'super', 'switch', 'sync',
    'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'when', 'while',
    'with', 'yield',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Parse a page definition JSON file, resolving all $refs.
  PageDef parsePageDef(String pageJsonPath, String remoteDir) {
    final file = File(pageJsonPath);
    if (!file.existsSync()) {
      throw Exception('Page definition file not found: $pageJsonPath');
    }

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final feature = json['feature'] as String? ?? '';
    final page = json['page'] as String? ?? '';

    if (feature.isEmpty) throw Exception('Missing "feature" in $pageJsonPath');
    if (page.isEmpty) throw Exception('Missing "page" in $pageJsonPath');

    final rawEndpoints = json['endpoints'] as List<dynamic>? ?? [];
    final resolvedEndpoints = <EndpointDef>[];
    final seenNames = <String>{};

    for (final raw in rawEndpoints) {
      final endpointMap = raw as Map<String, dynamic>;

      List<Map<String, dynamic>> expandedRaw;
      if (endpointMap.containsKey(r'$ref')) {
        expandedRaw = _resolveEndpointRef(
          endpointMap[r'$ref'] as String,
          remoteDir,
          [],
          0,
        );
      } else {
        expandedRaw = [endpointMap];
      }

      for (final epRaw in expandedRaw) {
        final ep = _parseEndpoint(epRaw, remoteDir);
        if (seenNames.contains(ep.name)) {
          throw Exception(
              'Duplicate endpoint name "${ep.name}" in page $pageJsonPath');
        }
        seenNames.add(ep.name);
        resolvedEndpoints.add(ep);
      }
    }

    return PageDef(feature: feature, page: page, endpoints: resolvedEndpoints);
  }

  /// Generate all files for a page. Returns list of generated file paths.
  List<String> generateForPage(
    PageDef pageDef,
    String remoteDir, {
    bool force = false,
    bool dryRun = false,
    bool verbose = false,
  }) {
    final generated = <String>[];
    final feature = pageDef.feature;
    final page = pageDef.page;
    final endpoints = pageDef.endpoints;

    final pageSnake = toSnakeCase(page);
    final featureBase = 'lib/features/$feature/$pageSnake';
    final dataBase = '$featureBase/data';
    final domainBase = '$featureBase/domain';
    final presentationBase = '$featureBase/presentation';

    // ------------------------------------------------------------------
    // Generate model files
    // ------------------------------------------------------------------
    for (final ep in endpoints) {
      final epPascal = toPascalCase(ep.name);

      // Request model (query params)
      if (ep.request != null) {
        final fileName =
            '${toSnakeCase(ep.name)}_request_model.dart';
        final filePath = '$dataBase/models/request/$fileName';
        final code =
            _generateModelClass('${epPascal}RequestModel', ep.request!, epPascal);
        _writeFile(filePath, code, force: force, dryRun: dryRun);
        generated.add(filePath);
      }

      // Body model (request body)
      if (ep.body != null) {
        final fileName = '${toSnakeCase(ep.name)}_body_model.dart';
        final filePath = '$dataBase/models/body/$fileName';
        final code =
            _generateModelClass('${epPascal}BodyModel', ep.body!, epPascal);
        _writeFile(filePath, code, force: force, dryRun: dryRun);
        generated.add(filePath);
      }

      // Response model
      {
        final fileName = '${toSnakeCase(ep.name)}_response_model.dart';
        final filePath = '$dataBase/models/response/$fileName';
        final code = _generateModelClass(
            '${epPascal}ResponseModel', ep.response, epPascal);
        _writeFile(filePath, code, force: force, dryRun: dryRun);
        generated.add(filePath);
      }
    }

    // ------------------------------------------------------------------
    // Generate datasource
    // ------------------------------------------------------------------
    {
      final filePath =
          '$dataBase/datasources/${toSnakeCase(page)}_remote_datasource.dart';
      final code = _generateDatasource(pageDef);
      _writeFile(filePath, code, force: force, dryRun: dryRun);
      generated.add(filePath);
    }

    // ------------------------------------------------------------------
    // Generate repository impl
    // ------------------------------------------------------------------
    {
      final filePath =
          '$dataBase/repositories/${toSnakeCase(page)}_repository_impl.dart';
      final code = _generateRepositoryImpl(pageDef);
      _writeFile(filePath, code, force: force, dryRun: dryRun);
      generated.add(filePath);
    }

    // ------------------------------------------------------------------
    // Generate domain repository (abstract)
    // ------------------------------------------------------------------
    {
      final filePath =
          '$domainBase/repositories/${toSnakeCase(page)}_repository.dart';
      final code = _generateDomainRepository(pageDef);
      _writeFile(filePath, code, force: force, dryRun: dryRun);
      generated.add(filePath);
    }

    // ------------------------------------------------------------------
    // Generate usecases (one per endpoint)
    // ------------------------------------------------------------------
    for (final ep in endpoints) {
      final filePath =
          '$domainBase/usecases/${toSnakeCase(ep.name)}_${pageSnake}_usecase.dart';
      final code = _generateUsecase(ep, pageDef);
      _writeFile(filePath, code, force: force, dryRun: dryRun);
      generated.add(filePath);
    }

    // ------------------------------------------------------------------
    // Generate presentation layer (page cubit + blocs per endpoint)
    // ------------------------------------------------------------------
    {
      final statePath =
          '$presentationBase/cubit/${pageSnake}_state.dart';
      final cubitPath =
          '$presentationBase/cubit/${pageSnake}_cubit.dart';

      _writeFile(statePath, _generatePageCubitState(pageDef),
          force: force, dryRun: dryRun);
      _writeFile(cubitPath, _generatePageCubit(pageDef),
          force: force, dryRun: dryRun);

      generated.add(statePath);
      generated.add(cubitPath);
    }

    for (final ep in endpoints) {
      final epSnake = toSnakeCase(ep.name);
      final blocPath =
          '$presentationBase/bloc/${epSnake}_${pageSnake}_bloc.dart';
      final eventPath =
          '$presentationBase/bloc/${epSnake}_${pageSnake}_event.dart';
      final statePath =
          '$presentationBase/bloc/${epSnake}_${pageSnake}_state.dart';

      _writeFile(eventPath, _generateBlocEvent(ep, pageDef),
          force: force, dryRun: dryRun);
      _writeFile(statePath, _generateBlocState(ep, pageDef),
          force: force, dryRun: dryRun);
      _writeFile(blocPath, _generateBloc(ep, pageDef),
          force: force, dryRun: dryRun);

      generated.add(eventPath);
      generated.add(statePath);
      generated.add(blocPath);
    }

    // ------------------------------------------------------------------
    // Generate page scaffold
    // ------------------------------------------------------------------
    {
      final filePath =
          '$presentationBase/pages/${pageSnake}_page.dart';
      final code = _generatePage(pageDef);
      _writeFile(filePath, code, force: force, dryRun: dryRun);
      generated.add(filePath);
    }

    // ------------------------------------------------------------------
    // Ensure widgets/.gitkeep exists
    // ------------------------------------------------------------------
    {
      final filePath = '$presentationBase/widgets/.gitkeep';
      _writeFile(filePath, '', force: force, dryRun: dryRun);
      generated.add(filePath);
    }

    // ------------------------------------------------------------------
    // Generate page injector
    // ------------------------------------------------------------------
    {
      final filePath = '$featureBase/${pageSnake}_injector.dart';
      final code = _generatePageInjector(pageDef);
      _writeFile(filePath, code, force: true, dryRun: dryRun);
      generated.add(filePath);
    }

    return generated;
  }

  /// Generate base_urls.dart from base_urls.json. Returns file path.
  String generateBaseUrls(String remoteDir, {bool force = false, bool dryRun = false}) {
    final baseUrlsFile = File('$remoteDir/shared/base_urls.json');
    if (!baseUrlsFile.existsSync()) {
      throw Exception('base_urls.json not found at ${baseUrlsFile.path}');
    }

    final json = jsonDecode(baseUrlsFile.readAsStringSync()) as Map<String, dynamic>;
    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln('class BaseUrls {');

    for (final entry in json.entries) {
      final constName = toCamelCase(entry.key);
      buf.writeln("  static const String $constName = '${entry.value}';");
    }

    buf.writeln('}');

    const filePath = 'lib/core/network/base_urls.dart';
    _writeFile(filePath, buf.toString(), force: force, dryRun: dryRun);
    return filePath;
  }

  /// Generate base_urls.dart from magickit.yaml (api.base_urls).
  String generateBaseUrlsFromConfig(
    Map<String, dynamic> baseUrls, {
    bool force = false,
    bool dryRun = false,
  }) {
    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln('class BaseUrls {');

    for (final entry in baseUrls.entries) {
      final value = entry.value;
      if (value is! String) continue;
      final constName = toCamelCase(entry.key);
      buf.writeln("  static const String $constName = '$value';");
    }

    buf.writeln('}');

    const filePath = 'lib/core/network/base_urls.dart';
    _writeFile(filePath, buf.toString(), force: force, dryRun: dryRun);
    return filePath;
  }

  // ---------------------------------------------------------------------------
  // $ref resolution
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _resolveEndpointRef(
    String ref,
    String remoteDir,
    List<String> chain,
    int depth,
  ) {
    if (depth >= _maxRefDepth) {
      throw Exception('Max \$ref depth ($_maxRefDepth) exceeded for ref: $ref');
    }
    if (chain.contains(ref)) {
      throw Exception('Circular \$ref detected: ${chain.join(' → ')} → $ref');
    }

    // ref format: "shared/classroom.json#get_list" or "shared/classroom.json#*"
    final parts = ref.split('#');
    if (parts.length != 2) {
      throw Exception('Invalid \$ref format: "$ref" (expected path#endpoint)');
    }

    final filePath = '$remoteDir/${parts[0]}';
    final selector = parts[1];

    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('\$ref file not found: $filePath');
    }

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final endpoints = json['endpoints'] as List<dynamic>?;

    if (endpoints == null) {
      throw Exception(
          '\$ref file "$filePath" does not have an "endpoints" array');
    }

    if (selector == '*') {
      if (endpoints.length > 10) {
        // ignore: avoid_print
        print(
            'WARNING: \$ref "${parts[0]}#*" resolves to ${endpoints.length} endpoints (> 10). Consider specifying individual endpoints.');
      }
      return endpoints.cast<Map<String, dynamic>>();
    }

    final found = endpoints
        .cast<Map<String, dynamic>>()
        .where((ep) => ep['name'] == selector)
        .toList();

    if (found.isEmpty) {
      throw Exception(
          '\$ref endpoint "$selector" not found in $filePath');
    }

    return found;
  }

  Map<String, dynamic>? _readMagickitConfig() {
    if (_magickitConfigCache != null) return _magickitConfigCache;
    final file = File('magickit.yaml');
    if (!file.existsSync()) return null;
    final yaml = loadYaml(file.readAsStringSync());
    if (yaml is YamlMap && yaml['magickit'] is YamlMap) {
      final config = _yamlToDynamic(yaml['magickit']);
      if (config is Map) {
        _magickitConfigCache =
            config.map((k, v) => MapEntry(k.toString(), v));
      }
      return _magickitConfigCache;
    }
    return null;
  }

  dynamic _yamlToDynamic(dynamic node) {
    if (node is YamlMap) {
      return node.map(
        (key, value) => MapEntry(key.toString(), _yamlToDynamic(value)),
      );
    }
    if (node is YamlList) {
      return node.map(_yamlToDynamic).toList();
    }
    return node;
  }

  dynamic _readMagickitValue(String path) {
    final config = _readMagickitConfig();
    if (config == null) return null;
    final segments = path.split('.').where((s) => s.isNotEmpty).toList();
    dynamic current = config;
    for (final seg in segments) {
      if (current is Map) {
        if (!current.containsKey(seg)) return null;
        current = current[seg];
        continue;
      }
      return null;
    }
    return current;
  }

  String _resolveBaseUrlRef(
    dynamic baseUrlValue,
    String remoteDir,
  ) {
    if (baseUrlValue is String) return baseUrlValue;
    if (baseUrlValue is Map<String, dynamic> &&
        baseUrlValue.containsKey(r'$ref')) {
      final ref = baseUrlValue[r'$ref'] as String;
      final parts = ref.split('#');
      if (parts.length != 2) {
        throw Exception('Invalid base_url \$ref: "$ref"');
      }
      final refFile = parts[0];
      final key = parts[1];
      if (refFile == 'magickit.yaml') {
        final value = _readMagickitValue(key);
        if (value is String) return value;
        throw Exception(
            'base_url \$ref key "$key" not found in magickit.yaml');
      }
      final filePath = '$remoteDir/$refFile';
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('base_url \$ref file not found: $filePath');
      }
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      if (!json.containsKey(key)) {
        throw Exception(
            'base_url \$ref key "$key" not found in $filePath');
      }
      return json[key] as String;
    }
    throw Exception('Invalid base_url value: $baseUrlValue');
  }

  String _resolveBaseUrlKey(dynamic baseUrlValue, String remoteDir) {
    if (baseUrlValue is Map<String, dynamic> &&
        baseUrlValue.containsKey(r'$ref')) {
      final ref = baseUrlValue[r'$ref'] as String;
      final parts = ref.split('#');
      if (parts.length == 2) {
        if (parts[0] == 'magickit.yaml') {
          final path = parts[1].split('.');
          return toCamelCase(path.isEmpty ? parts[1] : path.last);
        }
        return toCamelCase(parts[1]);
      }
    }
    return 'baseUrl';
  }

  // ---------------------------------------------------------------------------
  // Endpoint parsing & validation
  // ---------------------------------------------------------------------------

  EndpointDef _parseEndpoint(Map<String, dynamic> raw, String remoteDir) {
    final name = raw['name'] as String?;
    if (name == null || name.isEmpty) {
      throw Exception('Endpoint missing "name" field: $raw');
    }

    final rawMethod = (raw['method'] as String? ?? 'GET').toUpperCase();
    const validMethods = {'GET', 'POST', 'PUT', 'PATCH', 'DELETE'};
    if (!validMethods.contains(rawMethod)) {
      throw Exception('Invalid method "$rawMethod" for endpoint "$name"');
    }

    final body = raw['body'] as Map<String, dynamic>?;
    if ((rawMethod == 'GET' || rawMethod == 'DELETE') && body != null) {
      throw Exception(
          'Endpoint "$name": $rawMethod method cannot have a "body" field');
    }

    final rawPath = raw['path'] as String? ?? '/';
    final baseUrlValue = raw['base_url'];
    final baseUrl = _resolveBaseUrlRef(baseUrlValue, remoteDir);
    final baseUrlKey = _resolveBaseUrlKey(baseUrlValue, remoteDir);

    final rawHeaders = raw['headers'] as Map<String, dynamic>? ?? {};
    final headers = rawHeaders.map((k, v) => MapEntry(k, v.toString()));

    final request = raw['request'] as Map<String, dynamic>?;
    final response = raw['response'] as Map<String, dynamic>? ?? {};
    final auth = raw['auth'] as bool? ?? true;

    return EndpointDef(
      name: name,
      baseUrl: baseUrl,
      baseUrlKey: baseUrlKey,
      path: rawPath,
      method: rawMethod,
      headers: headers,
      request: request,
      body: body,
      response: response,
      auth: auth,
    );
  }

  // ---------------------------------------------------------------------------
  // Path parameter extraction
  // ---------------------------------------------------------------------------

  List<String> _extractPathParams(String path) {
    final regex = RegExp(r':(\w+)');
    return regex.allMatches(path).map((m) => m.group(1)!).toList();
  }

  String _buildPathWithParams(String path, List<String> pathParams) {
    var result = path;
    for (final param in pathParams) {
      result = result.replaceAll(':$param', '\$$param');
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Type inference
  // ---------------------------------------------------------------------------

  // Returns (dartType, isNullable, fromJsonExpr, toJsonExpr, nestedClasses)
  _TypeInfo _inferType(
    String key,
    dynamic value,
    String nestedPrefix,
    int depth,
  ) {
    if (depth >= _maxNestedDepth) {
      throw Exception(
          'Nested depth > $_maxNestedDepth for key "$key". Reduce nesting.');
    }

    final camelKey = _safeName(toCamelCase(key));

    // String-typed schema values
    if (value is String) {
      switch (value) {
        case 'string':
          return _TypeInfo(
            'String', false,
            "json['$key'] as String? ?? ''", camelKey,
          );
        case 'string?':
          return _TypeInfo(
            'String', true,
            "json['$key'] as String?", camelKey,
          );
        case 'int':
          return _TypeInfo(
            'int', false,
            "json['$key'] as int? ?? 0", camelKey,
          );
        case 'int?':
          return _TypeInfo(
            'int', true,
            "json['$key'] as int?", camelKey,
          );
        case 'double':
          return _TypeInfo(
            'double', false,
            "(json['$key'] as num?)?.toDouble() ?? 0.0", camelKey,
          );
        case 'double?':
          return _TypeInfo(
            'double', true,
            "(json['$key'] as num?)?.toDouble()", camelKey,
          );
        case 'bool':
          return _TypeInfo(
            'bool', false,
            "json['$key'] as bool? ?? false", camelKey,
          );
        case 'bool?':
          return _TypeInfo(
            'bool', true,
            "json['$key'] as bool?", camelKey,
          );
        case 'num':
          return _TypeInfo(
            'num', false,
            "json['$key'] as num? ?? 0", camelKey,
          );
        case 'DateTime':
          return _TypeInfo(
            'DateTime', false,
            "DateTime.parse(json['$key'] as String)",
            '$camelKey.toIso8601String()',
          );
        case 'DateTime?':
          return _TypeInfo(
            'DateTime', true,
            "json['$key'] != null ? DateTime.parse(json['$key'] as String) : null",
            '$camelKey?.toIso8601String()',
          );
        default:
          // treat any other string as a literal String value placeholder
          return _TypeInfo(
            'String', false,
            "json['$key'] as String? ?? ''", camelKey,
          );
      }
    }

    // Literal primitive values
    if (value == null) {
      return _TypeInfo('dynamic', true, "json['$key']", camelKey);
    }
    if (value is bool) {
      return _TypeInfo(
        'bool', false,
        "json['$key'] as bool? ?? false", camelKey,
      );
    }
    if (value is int) {
      return _TypeInfo(
        'int', false,
        "json['$key'] as int? ?? 0", camelKey,
      );
    }
    if (value is double) {
      return _TypeInfo(
        'double', false,
        "(json['$key'] as num?)?.toDouble() ?? 0.0", camelKey,
      );
    }

    // Object (non-empty → nested model, empty → Map<String, dynamic>)
    if (value is Map<String, dynamic>) {
      if (value.isEmpty) {
        return _TypeInfo(
          'Map<String, dynamic>', false,
          "(json['$key'] as Map<String, dynamic>?) ?? {}", camelKey,
        );
      }
      final nestedName = '$nestedPrefix${toPascalCase(key)}Model';
      return _TypeInfo(
        nestedName, false,
        "$nestedName.fromJson(json['$key'] as Map<String, dynamic>)",
        '$camelKey.toJson()',
        nestedModelSchema: value,
        nestedModelName: nestedName,
        nestedPrefix: '$nestedPrefix${toPascalCase(key)}',
      );
    }

    // List
    if (value is List) {
      if (value.isEmpty) {
        return _TypeInfo(
          'List<dynamic>', false,
          "(json['$key'] as List<dynamic>?) ?? []", camelKey,
        );
      }
      final first = value.first;
      if (first is String) {
        final elemType = _schemaStringToDartType(first);
        return _TypeInfo(
          'List<$elemType>', false,
          "(json['$key'] as List<dynamic>?)?.map((e) => e as $elemType).toList() ?? []",
          camelKey,
        );
      }
      if (first is int) {
        return _TypeInfo(
          'List<int>', false,
          "(json['$key'] as List<dynamic>?)?.map((e) => e as int).toList() ?? []",
          camelKey,
        );
      }
      if (first is bool) {
        return _TypeInfo(
          'List<bool>', false,
          "(json['$key'] as List<dynamic>?)?.map((e) => e as bool).toList() ?? []",
          camelKey,
        );
      }
      if (first is double) {
        return _TypeInfo(
          'List<double>', false,
          "(json['$key'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList() ?? []",
          camelKey,
        );
      }
      if (first is Map<String, dynamic>) {
        final nestedName = '$nestedPrefix${toPascalCase(key)}Model';
        return _TypeInfo(
          'List<$nestedName>', false,
          "(json['$key'] as List<dynamic>?)?.map((e) => $nestedName.fromJson(e as Map<String, dynamic>)).toList() ?? []",
          '$camelKey.map((e) => e.toJson()).toList()',
          nestedModelSchema: first,
          nestedModelName: nestedName,
          nestedPrefix: '$nestedPrefix${toPascalCase(key)}',
          isList: true,
        );
      }
    }

    return _TypeInfo('dynamic', true, "json['$key']", camelKey);
  }

  String _schemaStringToDartType(String s) {
    switch (s) {
      case 'string':
      case 'string?':
        return 'String';
      case 'int':
      case 'int?':
        return 'int';
      case 'double':
      case 'double?':
        return 'double';
      case 'bool':
      case 'bool?':
        return 'bool';
      default:
        return 'String';
    }
  }

  String _safeName(String name) {
    if (_dartReserved.contains(name)) return '\$$name';
    return name;
  }

  // ---------------------------------------------------------------------------
  // Model code generation
  // ---------------------------------------------------------------------------

  /// Generate a Dart model file (may include nested classes).
  String _generateModelClass(
    String className,
    Map<String, dynamic> schema,
    String nestedPrefix,
  ) {
    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln();

    final nestedClasses = <String>[];
    _collectNestedClasses(schema, nestedPrefix, nestedClasses, 0);

    for (final nc in nestedClasses) {
      buf
        ..writeln(nc)
        ..writeln();
    }

    buf.write(_buildModelClass(className, schema, nestedPrefix, 0));

    return buf.toString();
  }

  void _collectNestedClasses(
    Map<String, dynamic> schema,
    String nestedPrefix,
    List<String> result,
    int depth,
  ) {
    for (final entry in schema.entries) {
      final info = _inferType(entry.key, entry.value, nestedPrefix, depth);
      if (info.nestedModelSchema != null && info.nestedModelName != null) {
        // Recursively collect deeper nested first
        _collectNestedClasses(
          info.nestedModelSchema!,
          info.nestedPrefix ?? nestedPrefix,
          result,
          depth + 1,
        );
        result.add(
          _buildModelClass(
            info.nestedModelName!,
            info.nestedModelSchema!,
            info.nestedPrefix ?? nestedPrefix,
            depth + 1,
          ),
        );
      }
    }
  }

  String _buildModelClass(
    String className,
    Map<String, dynamic> schema,
    String nestedPrefix,
    int depth,
  ) {
    final fields = <_FieldSpec>[];
    for (final entry in schema.entries) {
      final info = _inferType(entry.key, entry.value, nestedPrefix, depth);
      final dartType = info.isNullable ? '${info.dartType}?' : info.dartType;
      fields.add(_FieldSpec(
        name: _safeName(toCamelCase(entry.key)),
        jsonKey: entry.key,
        dartType: dartType,
        isNullable: info.isNullable,
        fromJsonExpr: info.fromJsonExpr,
        toJsonExpr: info.toJsonExpr,
      ));
    }

    final buf = StringBuffer()..writeln('class $className {');

    for (final f in fields) {
      buf.writeln('  final ${f.dartType} ${f.name};');
    }
    buf.writeln();

    buf.writeln('  const $className({');
    for (final f in fields) {
      buf.writeln('    ${f.isNullable ? '' : 'required '}this.${f.name},');
    }
    buf.writeln('  });');
    buf.writeln();

    buf.writeln(
        '  factory $className.fromJson(Map<String, dynamic> json) => $className(');
    for (final f in fields) {
      buf.writeln('    ${f.name}: ${f.fromJsonExpr},');
    }
    buf.writeln('  );');
    buf.writeln();

    buf.writeln('  Map<String, dynamic> toJson() => {');
    for (final f in fields) {
      buf.writeln("    '${f.jsonKey}': ${f.toJsonExpr},");
    }
    buf.writeln('  };');

    buf.writeln('}');
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Datasource code generation
  // ---------------------------------------------------------------------------

  String _generateDatasource(PageDef pageDef) {
    final page = pageDef.page;
    final pagePascal = toPascalCase(page);
    final endpoints = pageDef.endpoints;
    final feature = pageDef.feature;
    final pageSnake = toSnakeCase(page);

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln("import 'dart:convert';")
      ..writeln("import 'package:http/http.dart' as http;")
      ..writeln(
          "import 'package:$appName/core/base/server_exception.dart';")
      ..writeln(
          "import 'package:$appName/core/network/token_manager.dart';")
      ..writeln(
          "import 'package:$appName/core/network/base_urls.dart';");

    // imports for response models
    for (final ep in endpoints) {
      final snake = toSnakeCase(ep.name);
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/data/models/response/${snake}_response_model.dart';");
    }
    // imports for body models
    for (final ep in endpoints) {
      if (ep.body != null) {
        final snake = toSnakeCase(ep.name);
        buf.writeln(
            "import 'package:$appName/features/$feature/$pageSnake/data/models/body/${snake}_body_model.dart';");
      }
    }
    buf.writeln();

    // Abstract class
    buf.writeln('abstract class ${pagePascal}RemoteDatasource {');
    for (final ep in endpoints) {
      buf.writeln('  ${_methodSignature(ep, abstract: true)}');
    }
    buf.writeln('}');
    buf.writeln();

    // Impl class
    buf
      ..writeln(
          'class ${pagePascal}RemoteDatasourceImpl implements ${pagePascal}RemoteDatasource {')
      ..writeln('  final http.Client client;')
      ..writeln('  final TokenManager tokenManager;')
      ..writeln()
      ..writeln(
          '  ${pagePascal}RemoteDatasourceImpl({required this.client, required this.tokenManager});')
      ..writeln();

    for (final ep in endpoints) {
      buf.writeln('  @override');
      buf.writeln('  ${_methodSignature(ep, abstract: false)} async {');
      buf.write(_generateMethodBody(ep));
      buf.writeln('  }');
      buf.writeln();
    }

    buf.writeln('}');

    return buf.toString();
  }

  String _methodSignature(EndpointDef ep, {required bool abstract}) {
    final epPascal = toPascalCase(ep.name);
    final returnType = 'Future<${epPascal}ResponseModel>';
    final params = _buildMethodParams(ep);
    final body = abstract ? ';' : '';
    return '$returnType ${toCamelCase(ep.name)}($params)$body';
  }

  String _buildMethodParams(EndpointDef ep) {
    final parts = <String>[];

    // Path params first (required)
    final pathParams = _extractPathParams(ep.path);
    for (final p in pathParams) {
      parts.add('required String $p');
    }

    // Body param
    if (ep.body != null) {
      final bodyModel = '${toPascalCase(ep.name)}BodyModel';
      parts.add('required $bodyModel body');
    }

    // Request (query) params — all nullable
    if (ep.request != null) {
      for (final entry in ep.request!.entries) {
        final camelName = _safeName(toCamelCase(entry.key));
        final dartType = _queryParamDartType(entry.value);
        parts.add('$dartType? $camelName');
      }
    }

    if (parts.isEmpty) return '';
    return '{${parts.join(', ')}}';
  }

  String _queryParamDartType(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'int':
        case 'int?':
          return 'int';
        case 'double':
        case 'double?':
          return 'double';
        case 'bool':
        case 'bool?':
          return 'bool';
        default:
          return 'String';
      }
    }
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    return 'String';
  }

  String _generateMethodBody(EndpointDef ep) {
    final buf = StringBuffer();
    final epPascal = toPascalCase(ep.name);
    final pathParams = _extractPathParams(ep.path);
    final pathWithParams = _buildPathWithParams(ep.path, pathParams);
    final baseUrlConst = 'BaseUrls.${ep.baseUrlKey}';

    // Build URI
    if (ep.request != null && ep.request!.isNotEmpty) {
      buf.writeln(
          '    final queryParams = <String, String>{};');
      for (final entry in ep.request!.entries) {
        final camelName = _safeName(toCamelCase(entry.key));
        final toStr = _toStringExpr(camelName, entry.value);
        buf.writeln(
            "    if ($camelName != null) queryParams['${entry.key}'] = $toStr;");
      }
      buf.writeln(
          "    final uri = Uri.parse('\$$baseUrlConst$pathWithParams')");
      buf.writeln(
          '        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);');
    } else {
      buf.writeln(
          "    final uri = Uri.parse('\$$baseUrlConst$pathWithParams');");
    }

    // Build headers
    buf.writeln(
        "    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};");
    for (final entry in ep.headers.entries) {
      buf.writeln("    headers['${entry.key}'] = '${entry.value}';");
    }
    if (ep.auth) {
      buf.writeln(
          '    final token = await tokenManager.getToken();');
      buf.writeln(
          "    if (token != null) headers['Authorization'] = 'Bearer \$token';");
    }

    // HTTP call
    final method = ep.method.toLowerCase();
    if (ep.body != null) {
      buf.writeln(
          '    final response = await client.$method(uri, headers: headers, body: jsonEncode(body.toJson()));');
    } else {
      buf.writeln(
          '    final response = await client.$method(uri, headers: headers);');
    }

    // Handle response
    buf
      ..writeln(
          '    if (response.statusCode >= 200 && response.statusCode < 300) {')
      ..writeln(
          '      return ${epPascal}ResponseModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);')
      ..writeln('    } else {')
      ..writeln(
          '      throw ServerException(statusCode: response.statusCode, message: response.body);')
      ..writeln('    }');

    return buf.toString();
  }

  String _toStringExpr(String varName, dynamic schemaValue) {
    if (schemaValue is String &&
        (schemaValue == 'int' || schemaValue == 'int?')) {
      return '$varName.toString()';
    }
    if (schemaValue is String &&
        (schemaValue == 'double' || schemaValue == 'double?')) {
      return '$varName.toString()';
    }
    if (schemaValue is String &&
        (schemaValue == 'bool' || schemaValue == 'bool?')) {
      return '$varName.toString()';
    }
    if (schemaValue is int) return '$varName.toString()';
    if (schemaValue is double) return '$varName.toString()';
    if (schemaValue is bool) return '$varName.toString()';
    return varName; // String already
  }

  // ---------------------------------------------------------------------------
  // Domain repository (abstract)
  // ---------------------------------------------------------------------------

  String _generateDomainRepository(PageDef pageDef) {
    final page = pageDef.page;
    final pagePascal = toPascalCase(page);
    final endpoints = pageDef.endpoints;
    final feature = pageDef.feature;
    final pageSnake = toSnakeCase(page);

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln("import 'package:$appName/core/base/either.dart';")
      ..writeln("import 'package:$appName/core/base/failure.dart';");

    for (final ep in endpoints) {
      final snake = toSnakeCase(ep.name);
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/data/models/response/${snake}_response_model.dart';");
      if (ep.body != null) {
        buf.writeln(
            "import 'package:$appName/features/$feature/$pageSnake/data/models/body/${snake}_body_model.dart';");
      }
    }
    buf.writeln();

    buf.writeln('abstract class ${pagePascal}Repository {');
    for (final ep in endpoints) {
      buf.writeln(
          '  ${_repoMethodSignature(ep, abstract: true)}');
    }
    buf.writeln('}');

    return buf.toString();
  }

  String _repoMethodSignature(EndpointDef ep, {required bool abstract}) {
    final epPascal = toPascalCase(ep.name);
    final returnType =
        'Future<Either<Failure, ${epPascal}ResponseModel>>';
    final params = _buildMethodParams(ep);
    final ending = abstract ? ';' : '';
    return '$returnType ${toCamelCase(ep.name)}($params)$ending';
  }

  // ---------------------------------------------------------------------------
  // Repository impl
  // ---------------------------------------------------------------------------

  String _generateRepositoryImpl(PageDef pageDef) {
    final page = pageDef.page;
    final pagePascal = toPascalCase(page);
    final endpoints = pageDef.endpoints;
    final feature = pageDef.feature;
    final pageSnake = toSnakeCase(page);

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln("import 'package:$appName/core/base/either.dart';")
      ..writeln("import 'package:$appName/core/base/failure.dart';")
      ..writeln(
          "import 'package:$appName/core/base/server_exception.dart';")
      ..writeln(
          "import 'package:$appName/features/$feature/$pageSnake/domain/repositories/${toSnakeCase(page)}_repository.dart';")
      ..writeln(
          "import 'package:$appName/features/$feature/$pageSnake/data/datasources/${toSnakeCase(page)}_remote_datasource.dart';");

    for (final ep in endpoints) {
      final snake = toSnakeCase(ep.name);
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/data/models/response/${snake}_response_model.dart';");
      if (ep.body != null) {
        buf.writeln(
            "import 'package:$appName/features/$feature/$pageSnake/data/models/body/${snake}_body_model.dart';");
      }
    }
    buf.writeln();

    buf
      ..writeln(
          'class ${pagePascal}RepositoryImpl implements ${pagePascal}Repository {')
      ..writeln(
          '  final ${pagePascal}RemoteDatasource remoteDatasource;')
      ..writeln()
      ..writeln(
          '  ${pagePascal}RepositoryImpl({required this.remoteDatasource});')
      ..writeln();

    for (final ep in endpoints) {
      final epPascal = toPascalCase(ep.name);
      final epCamel = toCamelCase(ep.name);
      final params = _buildMethodParams(ep);
      final callArgs = _buildCallArgs(ep);

      buf
        ..writeln('  @override')
        ..writeln(
            '  Future<Either<Failure, ${epPascal}ResponseModel>> $epCamel($params) async {')
        ..writeln('    try {')
        ..writeln(
            '      final result = await remoteDatasource.$epCamel($callArgs);')
        ..writeln('      return Right(result);')
        ..writeln('    } on ServerException catch (e) {')
        ..writeln(
            '      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));')
        ..writeln('    } catch (e) {')
        ..writeln(
            '      return Left(GeneralFailure(message: e.toString()));')
        ..writeln('    }')
        ..writeln('  }')
        ..writeln();
    }

    buf.writeln('}');
    return buf.toString();
  }

  String _buildCallArgs(EndpointDef ep) {
    final parts = <String>[];
    final pathParams = _extractPathParams(ep.path);
    for (final p in pathParams) {
      parts.add('$p: $p');
    }
    if (ep.body != null) {
      parts.add('body: body');
    }
    if (ep.request != null) {
      for (final entry in ep.request!.entries) {
        final camelName = _safeName(toCamelCase(entry.key));
        parts.add('$camelName: $camelName');
      }
    }
    if (parts.isEmpty) return '';
    return parts.join(', ');
  }

  // ---------------------------------------------------------------------------
  // Presentation helpers
  // ---------------------------------------------------------------------------

  List<_ParamSpec> _buildParamSpecs(EndpointDef ep) {
    final specs = <_ParamSpec>[];

    // Path params first (required)
    final pathParams = _extractPathParams(ep.path);
    for (final p in pathParams) {
      specs.add(_ParamSpec(
        name: p,
        type: 'String',
        isRequired: true,
        isNullable: false,
      ));
    }

    // Body param (required)
    if (ep.body != null) {
      final bodyModel = '${toPascalCase(ep.name)}BodyModel';
      specs.add(_ParamSpec(
        name: 'body',
        type: bodyModel,
        isRequired: true,
        isNullable: false,
      ));
    }

    // Request (query) params — optional
    if (ep.request != null) {
      for (final entry in ep.request!.entries) {
        final camelName = _safeName(toCamelCase(entry.key));
        final dartType = _queryParamDartType(entry.value);
        specs.add(_ParamSpec(
          name: camelName,
          type: dartType,
          isRequired: false,
          isNullable: true,
        ));
      }
    }

    return specs;
  }

  String _buildEventArgs(EndpointDef ep) {
    final parts = <String>[];
    for (final spec in _buildParamSpecs(ep)) {
      parts.add('${spec.name}: ${spec.name}');
    }
    return parts.join(', ');
  }

  String _buildCallArgsFromEvent(EndpointDef ep) {
    final parts = <String>[];
    for (final spec in _buildParamSpecs(ep)) {
      parts.add('${spec.name}: event.${spec.name}');
    }
    return parts.join(', ');
  }

  String _blocBaseName(EndpointDef ep, PageDef pageDef) {
    final epPascal = toPascalCase(ep.name);
    final pagePascal = toPascalCase(pageDef.page);
    return epPascal == pagePascal ? pagePascal : '${epPascal}${pagePascal}';
  }

  String _eventName(EndpointDef ep, PageDef pageDef) {
    return '${_blocBaseName(ep, pageDef)}Requested';
  }

  String _usecaseName(EndpointDef ep, PageDef pageDef) {
    return '${_blocBaseName(ep, pageDef)}Usecase';
  }

  String _pageInjectorName(PageDef pageDef) {
    return '${toCamelCase(pageDef.page)}Injector';
  }

  String _listenerMethodName(EndpointDef ep, PageDef pageDef) {
    return 'listener${_blocBaseName(ep, pageDef)}Bloc';
  }

  String _fetchMethodName(EndpointDef ep) {
    return 'fetch${toPascalCase(ep.name)}';
  }

  String _blocFieldName(EndpointDef ep, PageDef pageDef) {
    final base = _blocBaseName(ep, pageDef);
    return '${toCamelCase(toSnakeCase(base))}Bloc';
  }

  // ---------------------------------------------------------------------------
  // Usecase
  // ---------------------------------------------------------------------------

  String _generateUsecase(EndpointDef ep, PageDef pageDef) {
    final page = pageDef.page;
    final pagePascal = toPascalCase(page);
    final epPascal = toPascalCase(ep.name);
    final epCamel = toCamelCase(ep.name);
    final usecaseName = _usecaseName(ep, pageDef);
    final feature = pageDef.feature;
    final pageSnake = toSnakeCase(page);

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln("import 'package:$appName/core/base/either.dart';")
      ..writeln("import 'package:$appName/core/base/failure.dart';")
      ..writeln(
          "import 'package:$appName/features/$feature/$pageSnake/domain/repositories/${toSnakeCase(page)}_repository.dart';")
      ..writeln(
          "import 'package:$appName/features/$feature/$pageSnake/data/models/response/${toSnakeCase(ep.name)}_response_model.dart';");

    if (ep.body != null) {
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/data/models/body/${toSnakeCase(ep.name)}_body_model.dart';");
    }
    buf.writeln();

    final params = _buildMethodParams(ep);
    final callArgs = _buildCallArgs(ep);

    buf
      ..writeln('class $usecaseName {')
      ..writeln('  final ${pagePascal}Repository repository;')
      ..writeln()
      ..writeln('  $usecaseName({required this.repository});')
      ..writeln()
      ..writeln(
          '  Future<Either<Failure, ${epPascal}ResponseModel>> call($params) {')
      ..writeln('    return repository.$epCamel($callArgs);')
      ..writeln('  }')
      ..writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Presentation layer (MagicCubit + Bloc per endpoint + Page)
  // ---------------------------------------------------------------------------

  String _generatePageCubitState(PageDef pageDef) {
    final pagePascal = toPascalCase(pageDef.page);
    return '''
// GENERATED CODE — DO NOT EDIT BY HAND
// Run `magickit api` to regenerate.

import 'package:equatable/equatable.dart';
import 'package:$appName/core/base/failure.dart';

class ${pagePascal}StateCubit extends Equatable {
  final bool isLoading;
  final Failure? failure;

  const ${pagePascal}StateCubit({
    this.isLoading = false,
    this.failure,
  });

  bool get isError => failure != null;

  ${pagePascal}StateCubit copyWith({
    bool? isLoading,
    Failure? failure,
  }) {
    return ${pagePascal}StateCubit(
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [isLoading, failure];
}
''';
  }

  String _generatePageCubit(PageDef pageDef) {
    final pagePascal = toPascalCase(pageDef.page);
    final pageSnake = toSnakeCase(pageDef.page);
    final feature = pageDef.feature;
    final endpoints = pageDef.endpoints;

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln("import 'package:flutter/widgets.dart';")
      ..writeln("import 'package:flutter_bloc/flutter_bloc.dart';")
      ..writeln(
          "import 'package:$appName/core/base/magic_cubit.dart';")
      ..writeln(
          "import 'package:$appName/features/$feature/$pageSnake/presentation/cubit/${pageSnake}_state.dart';");

    for (final ep in endpoints) {
      final epSnake = toSnakeCase(ep.name);
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/presentation/bloc/${epSnake}_${pageSnake}_bloc.dart';");
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/presentation/bloc/${epSnake}_${pageSnake}_event.dart';");
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/presentation/bloc/${epSnake}_${pageSnake}_state.dart';");
      if (ep.body != null) {
        buf.writeln(
            "import 'package:$appName/features/$feature/$pageSnake/data/models/body/${toSnakeCase(ep.name)}_body_model.dart';");
      }
    }

    buf
      ..writeln()
      ..writeln('class ${pagePascal}Cubit extends MagicCubit<${pagePascal}StateCubit> {');

    for (final ep in endpoints) {
      final blocName = _blocBaseName(ep, pageDef);
      final blocField = _blocFieldName(ep, pageDef);
      buf.writeln('  final ${blocName}Bloc $blocField;');
    }

    buf.writeln();

    final ctorParams = endpoints
        .map((ep) {
          final blocField = _blocFieldName(ep, pageDef);
          return 'required this.$blocField';
        })
        .join(', ');

    final ctorSignature = endpoints.isEmpty
        ? '${pagePascal}Cubit()'
        : '${pagePascal}Cubit({$ctorParams})';

    buf
      ..writeln('  $ctorSignature')
      ..writeln('      : super(const ${pagePascal}StateCubit());')
      ..writeln()
      ..writeln('  $_markerBegin')
      ..writeln('  @override')
      ..writeln('  List<BlocProvider> get blocProviders => [');

    for (final ep in endpoints) {
      final blocName = _blocBaseName(ep, pageDef);
      final blocField = _blocFieldName(ep, pageDef);
      buf.writeln(
          '        BlocProvider<${blocName}Bloc>.value(value: $blocField),');
    }

    buf
      ..writeln('      ];')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  List<BlocListener> Function(BuildContext context)? get blocListeners =>')
      ..writeln('      (context) => [');

    for (final ep in endpoints) {
      final blocName = _blocBaseName(ep, pageDef);
      final stateName = '${blocName}State';
      final listenerName = _listenerMethodName(ep, pageDef);
      buf
        ..writeln('        BlocListener<${blocName}Bloc, $stateName>(')
        ..writeln('          listener: $listenerName,')
        ..writeln('        ),');
    }

    buf
      ..writeln('      ];')
      ..writeln('  $_markerEnd')
      ..writeln();

    for (final ep in endpoints) {
      final methodName = _fetchMethodName(ep);
      final params = _buildMethodParams(ep);
      final signature = params.isEmpty ? '()' : '($params)';
      final eventArgs = _buildEventArgs(ep);
      final eventName = _eventName(ep, pageDef);

      buf
      ..writeln('  Future<void> $methodName$signature async {')
        ..writeln(
            '    ${_blocFieldName(ep, pageDef)}.add($eventName($eventArgs));')
        ..writeln('  }')
        ..writeln();
    }

    for (final ep in endpoints) {
      final blocName = _blocBaseName(ep, pageDef);
      final stateName = '${blocName}State';
      final listenerName = _listenerMethodName(ep, pageDef);

      buf
        ..writeln('  void $listenerName(BuildContext context, $stateName blocState) {')
        ..writeln('    blocState.when(')
        ..writeln('      onLoading: (_) => emit(this.state.copyWith(isLoading: true, failure: null)),')
        ..writeln('      onFailed: (state) => emit(this.state.copyWith(isLoading: false, failure: state.failure)),')
        ..writeln('      onSuccess: (state) {')
        ..writeln('        emit(this.state.copyWith(isLoading: false, failure: null));')
        ..writeln('        // TODO: handle success state')
        ..writeln('      },')
        ..writeln('    );')
        ..writeln('  }')
        ..writeln();
    }

    buf
      ..writeln()
      ..writeln('  // TODO: Custom logic below this line')
      ..writeln('}');

    return buf.toString();
  }

  String _generateBlocEvent(EndpointDef ep, PageDef pageDef) {
    final blocName = _blocBaseName(ep, pageDef);
    final eventName = _eventName(ep, pageDef);
    final params = _buildParamSpecs(ep);
    final feature = pageDef.feature;
    final pageSnake = toSnakeCase(pageDef.page);

    final fields = params
        .map((p) => '  final ${p.type}${p.isNullable ? '?' : ''} ${p.name};')
        .join('\n');

    final ctorParams = params.isEmpty
        ? ''
        : params
            .map((p) => p.isRequired
                ? 'required this.${p.name}'
                : 'this.${p.name}')
            .join(', ');

    final ctor = params.isEmpty ? '  const $eventName();' : '  const $eventName({$ctorParams});';

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln();

    if (ep.body != null) {
      buf.writeln(
          "import 'package:$appName/features/$feature/$pageSnake/data/models/body/${toSnakeCase(ep.name)}_body_model.dart';");
      buf.writeln();
    }

    buf.write('''
abstract class ${blocName}Event {
  const ${blocName}Event();
}

class $eventName extends ${blocName}Event {
${fields.isNotEmpty ? '$fields\n' : ''}$ctor
}
''');

    return buf.toString();
  }

  String _generateBlocState(EndpointDef ep, PageDef pageDef) {
    final blocName = _blocBaseName(ep, pageDef);
    final responseModel = '${toPascalCase(ep.name)}ResponseModel';
    final feature = pageDef.feature;
    final pageSnake = toSnakeCase(pageDef.page);

    return '''
// GENERATED CODE — DO NOT EDIT BY HAND
// Run `magickit api` to regenerate.

import 'package:$appName/core/base/failure.dart';
import 'package:$appName/features/$feature/$pageSnake/data/models/response/${toSnakeCase(ep.name)}_response_model.dart';

abstract class ${blocName}State {
  const ${blocName}State();

  T? when<T>({
    T Function(${blocName}Initial state)? onInitial,
    T Function(${blocName}Loading state)? onLoading,
    T Function(${blocName}Success state)? onSuccess,
    T Function(${blocName}Failed state)? onFailed,
  }) {
    final self = this;
    if (self is ${blocName}Initial) return onInitial?.call(self);
    if (self is ${blocName}Loading) return onLoading?.call(self);
    if (self is ${blocName}Success) return onSuccess?.call(self);
    if (self is ${blocName}Failed) return onFailed?.call(self);
    return null;
  }
}

class ${blocName}Initial extends ${blocName}State {
  const ${blocName}Initial();
}

class ${blocName}Loading extends ${blocName}State {
  const ${blocName}Loading();
}

class ${blocName}Success extends ${blocName}State {
  final $responseModel data;
  const ${blocName}Success(this.data);
}

class ${blocName}Failed extends ${blocName}State {
  final Failure failure;
  const ${blocName}Failed(this.failure);
}
''';
  }

  String _generateBloc(EndpointDef ep, PageDef pageDef) {
    final blocName = _blocBaseName(ep, pageDef);
    final eventName = _eventName(ep, pageDef);
    final usecaseName = _usecaseName(ep, pageDef);
    final pageSnake = toSnakeCase(pageDef.page);
    final feature = pageDef.feature;

    final callArgs = _buildCallArgsFromEvent(ep);

    return '''
// GENERATED CODE — DO NOT EDIT BY HAND
// Run `magickit api` to regenerate.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:$appName/features/$feature/$pageSnake/domain/usecases/${toSnakeCase(ep.name)}_${pageSnake}_usecase.dart';
import '${toSnakeCase(ep.name)}_${pageSnake}_event.dart';
import '${toSnakeCase(ep.name)}_${pageSnake}_state.dart';

class ${blocName}Bloc extends Bloc<${blocName}Event, ${blocName}State> {
  final $usecaseName _usecase;

  ${blocName}Bloc({required $usecaseName usecase})
      : _usecase = usecase,
        super(const ${blocName}Initial()) {
    on<$eventName>(_onRequested);
  }

  Future<void> _onRequested(
    $eventName event,
    Emitter<${blocName}State> emit,
  ) async {
    emit(const ${blocName}Loading());

    final result = await _usecase.call($callArgs);
    result.fold(
      (failure) => emit(${blocName}Failed(failure)),
      (data) => emit(${blocName}Success(data)),
    );
  }
}
''';
  }

  String _generatePageInjector(PageDef pageDef) {
    final page = pageDef.page;
    final pageSnake = toSnakeCase(page);
    final pagePascal = toPascalCase(page);
    final pageInjectorName = _pageInjectorName(pageDef);

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln("import 'package:get_it/get_it.dart';")
      ..writeln("import 'package:http/http.dart' as http;")
      ..writeln(
          "import 'package:$appName/core/network/token_manager.dart';")
      ..writeln()
      ..writeln("import 'data/datasources/${pageSnake}_remote_datasource.dart';")
      ..writeln("import 'data/repositories/${pageSnake}_repository_impl.dart';")
      ..writeln("import 'domain/repositories/${pageSnake}_repository.dart';");

    for (final ep in pageDef.endpoints) {
      final epSnake = toSnakeCase(ep.name);
      buf.writeln(
          "import 'domain/usecases/${epSnake}_${pageSnake}_usecase.dart';");
      buf.writeln(
          "import 'presentation/bloc/${epSnake}_${pageSnake}_bloc.dart';");
    }

    buf
      ..writeln("import 'presentation/cubit/${pageSnake}_cubit.dart';")
      ..writeln()
      ..writeln('final getIt = GetIt.instance;')
      ..writeln()
      ..writeln('void $pageInjectorName() {')
      ..writeln('  // ── Datasources ──────────────────────────────────────')
      ..writeln('  getIt.registerLazySingleton<${pagePascal}RemoteDatasource>(')
      ..writeln('    () => ${pagePascal}RemoteDatasourceImpl(')
      ..writeln('      client: getIt<http.Client>(),')
      ..writeln('      tokenManager: getIt(),')
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln()
      ..writeln('  // ── Repositories ─────────────────────────────────────')
      ..writeln('  getIt.registerLazySingleton<${pagePascal}Repository>(')
      ..writeln('    () => ${pagePascal}RepositoryImpl(')
      ..writeln(
          '      remoteDatasource: getIt<${pagePascal}RemoteDatasource>(),')
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln();

    buf.writeln('  // ── Usecases ─────────────────────────────────────────');
    for (final ep in pageDef.endpoints) {
      final usecaseName = _usecaseName(ep, pageDef);
      buf
        ..writeln('  getIt.registerLazySingleton(')
        ..writeln('    () => $usecaseName(')
        ..writeln('      repository: getIt<${pagePascal}Repository>(),')
        ..writeln('    ),')
        ..writeln('  );')
        ..writeln();
    }

    buf.writeln('  // ── Blocs ────────────────────────────────────────────');
    for (final ep in pageDef.endpoints) {
      final blocName = _blocBaseName(ep, pageDef);
      final usecaseName = _usecaseName(ep, pageDef);
      buf
        ..writeln('  getIt.registerFactory(')
        ..writeln('    () => ${blocName}Bloc(')
        ..writeln('      usecase: getIt<$usecaseName>(),')
        ..writeln('    ),')
        ..writeln('  );')
        ..writeln();
    }

    buf.writeln('  // ── Cubit ────────────────────────────────────────────');
    if (pageDef.endpoints.isEmpty) {
      buf
        ..writeln('  getIt.registerFactory(() => ${pagePascal}Cubit());')
        ..writeln('}');
      return buf.toString();
    }

    final blocArgs = pageDef.endpoints
        .map((ep) {
          final field = _blocFieldName(ep, pageDef);
          final blocName = _blocBaseName(ep, pageDef);
          return '    $field: getIt<${blocName}Bloc>(),';
        })
        .join('\n');

    buf
      ..writeln('  getIt.registerFactory(')
      ..writeln('    () => ${pagePascal}Cubit(')
      ..writeln(blocArgs)
      ..writeln('    ),')
      ..writeln('  );')
      ..writeln('}');

    return buf.toString();
  }

  String _generatePage(PageDef pageDef) {
    final feature = pageDef.feature;
    final page = pageDef.page;
    final pagePascal = toPascalCase(page);
    final pageSnake = toSnakeCase(page);
    final endpoints = pageDef.endpoints;

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln()
      ..writeln("import 'package:flutter/material.dart';")
      ..writeln(
          "import 'package:$appName/core/base/magic_state_page.dart';")
      ..writeln(
          "import 'package:$appName/core/dependency_injection/injector.dart';")
      ..writeln(
          "import 'package:$appName/features/$feature/$pageSnake/presentation/cubit/${pageSnake}_cubit.dart';")
      ..writeln(
          "import 'package:$appName/features/$feature/$pageSnake/presentation/cubit/${pageSnake}_state.dart';")
      ..writeln();

    buf
      ..writeln('class ${pagePascal}Page extends StatefulWidget {')
      ..writeln('  const ${pagePascal}Page({super.key});')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  State<${pagePascal}Page> createState() => _${pagePascal}PageState();')
      ..writeln('}')
      ..writeln()
      ..writeln('class _${pagePascal}PageState extends State<${pagePascal}Page>')
      ..writeln(
          '    with MagicStatePage<${pagePascal}Page, ${pagePascal}Cubit, ${pagePascal}StateCubit> {')
      ..writeln('  @override')
      ..writeln('  ${pagePascal}Cubit createCubit() => getIt<${pagePascal}Cubit>();')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  void initState() {')
      ..writeln('    super.initState();')
      ..writeln('    // TODO: Call initial data fetch here');

    if (endpoints.isNotEmpty) {
      final methodName = toCamelCase(endpoints.first.name);
      buf.writeln(
          '    // context.read<${pagePascal}Cubit>().$methodName();');
    }

    buf
      ..writeln('  }')
      ..writeln()
      ..writeln('  @override')
      ..writeln('  Widget buildPage(BuildContext context, ${pagePascal}StateCubit state) {')
      ..writeln('    return Scaffold(')
      ..writeln('      appBar: AppBar(')
      ..writeln("        title: const Text('$pagePascal'),")
      ..writeln('      ),')
      ..writeln('      body: state.isLoading')
      ..writeln('          ? const Center(child: CircularProgressIndicator())')
      ..writeln('          : const Center(')
      ..writeln(
          "              child: Text('// TODO: Implement ${pageSnake.replaceAll('_', ' ')} UI'),")
      ..writeln('            ),')
      ..writeln('    );')
      ..writeln('  }')
      ..writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Feature injector generation
  // ---------------------------------------------------------------------------

  String generateFeatureInjector(
    String feature,
    List<PageDef> pages,
  ) {
    final featureCamel = toCamelCase(feature);
    final pageImports = <String>{};
    for (final pageDef in pages) {
      final pageSnake = toSnakeCase(pageDef.page);
      pageImports.add("import '$pageSnake/${pageSnake}_injector.dart';");
    }

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln();

    for (final i in pageImports.toList()..sort()) {
      buf.writeln(i);
    }

    buf
      ..writeln()
      ..writeln('void ${featureCamel}Injector() {');

    for (final pageDef in pages) {
      final callName = _pageInjectorName(pageDef);
      buf.writeln('  $callName();');
    }

    buf.writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // File writing helpers
  // ---------------------------------------------------------------------------

  void _writeFile(
    String path,
    String content, {
    required bool force,
    required bool dryRun,
  }) {
    if (dryRun) {
      // ignore: avoid_print
      print('[dry-run] Would write: $path');
      return;
    }
    final file = File(path);
    if (file.existsSync()) {
      final existing = file.readAsStringSync();
      final merged = _isPageCubitFile(path)
          ? _mergePageCubit(existing, content)
          : _mergeWithMarkers(existing, content);
      file.writeAsStringSync(merged);
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  }

  String _mergeWithMarkers(String existing, String generated) {
    final existingStart = existing.indexOf(_markerBegin);
    final existingEnd = existing.indexOf(_markerEnd);
    final newStart = generated.indexOf(_markerBegin);
    final newEnd = generated.indexOf(_markerEnd);

    if (existingStart == -1 ||
        existingEnd == -1 ||
        newStart == -1 ||
        newEnd == -1) {
      return generated;
    }

    final existingHead = existing.substring(0, existingStart);
    final existingTail =
        existing.substring(existingEnd + _markerEnd.length);
    final newBlock =
        generated.substring(newStart, newEnd + _markerEnd.length);

    return '$existingHead$newBlock$existingTail';
  }

  bool _isPageCubitFile(String path) {
    return path.contains('/presentation/cubit/') && path.endsWith('_cubit.dart');
  }

  String _mergePageCubit(String existing, String generated) {
    var merged = generated;

    // Preserve fetch/listener methods if developer customized them.
    final methodNames = _extractMethodNames(generated);
    for (final name in methodNames) {
      if (!name.startsWith('fetch') && !name.startsWith('listener')) {
        continue;
      }
      final existingMethod = _extractMethod(existing, name);
      if (existingMethod == null) continue;
      final generatedMethod = _extractMethod(merged, name);
      if (generatedMethod == null) continue;
      merged = merged.replaceFirst(generatedMethod, existingMethod);
    }

    // Preserve any custom logic below the marker line.
    const customMarker = '// TODO: Custom logic below this line';
    final existingMarker = existing.indexOf(customMarker);
    final generatedMarker = merged.indexOf(customMarker);
    if (existingMarker != -1 && generatedMarker != -1) {
      final existingTail = existing.substring(existingMarker);
      merged = '${merged.substring(0, generatedMarker)}$existingTail';
    }

    // Preserve any extra imports added by developers.
    merged = _mergeImports(existing, merged);

    return merged;
  }

  List<String> _extractMethodNames(String source) {
    final names = <String>{};
    final reg = RegExp(r'\b(?:Future<\s*void\s*>|void)\s+([A-Za-z_]\w*)\s*\(');
    for (final match in reg.allMatches(source)) {
      names.add(match.group(1)!);
    }
    return names.toList();
  }

  String? _extractMethod(String source, String methodName) {
    final reg = RegExp(
        r'\b(?:Future<\s*void\s*>|void)\s+' +
            RegExp.escape(methodName) +
            r'\s*\(');
    final match = reg.firstMatch(source);
    if (match == null) return null;

    final braceIndex = source.indexOf('{', match.end);
    if (braceIndex == -1) return null;

    var depth = 0;
    for (var i = braceIndex; i < source.length; i++) {
      final ch = source[i];
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) {
          return source.substring(match.start, i + 1);
        }
      }
    }
    return null;
  }

  String _mergeImports(String existing, String merged) {
    final importReg = RegExp("^import\\s+['\"][^'\"]+['\"];",
        multiLine: true);

    final existingImports = <String>{};
    for (final match in importReg.allMatches(existing)) {
      existingImports.add(match.group(0)!);
    }

    final mergedImports = <String>{};
    for (final match in importReg.allMatches(merged)) {
      mergedImports.add(match.group(0)!);
    }

    final missing = existingImports.difference(mergedImports).toList();
    if (missing.isEmpty) return merged;

    Match? lastImportMatch;
    for (final m in importReg.allMatches(merged)) {
      lastImportMatch = m;
    }
    if (lastImportMatch == null) {
      // No imports in merged; prepend existing imports after header comment.
      final lines = merged.split('\n');
      final insertAt = lines.length > 1 ? 1 : 0;
      lines.insertAll(insertAt, [...missing, '']);
      return lines.join('\n');
    }

    final insertPos = lastImportMatch.end;
    final insertBlock = '\n${missing.join('\n')}\n';
    return merged.replaceRange(insertPos, insertPos, insertBlock);
  }
}

// ---------------------------------------------------------------------------
// Internal helper structs
// ---------------------------------------------------------------------------

class _TypeInfo {
  final String dartType;
  final bool isNullable;
  final String fromJsonExpr;
  final String toJsonExpr;
  final Map<String, dynamic>? nestedModelSchema;
  final String? nestedModelName;
  final String? nestedPrefix;
  final bool isList;

  const _TypeInfo(
    this.dartType,
    this.isNullable,
    this.fromJsonExpr,
    this.toJsonExpr, {
    this.nestedModelSchema,
    this.nestedModelName,
    this.nestedPrefix,
    this.isList = false,
  });
}

class _FieldSpec {
  final String name;
  final String jsonKey;
  final String dartType;
  final bool isNullable;
  final String fromJsonExpr;
  final String toJsonExpr;

  const _FieldSpec({
    required this.name,
    required this.jsonKey,
    required this.dartType,
    required this.isNullable,
    required this.fromJsonExpr,
    required this.toJsonExpr,
  });
}

class _ParamSpec {
  final String name;
  final String type;
  final bool isRequired;
  final bool isNullable;

  const _ParamSpec({
    required this.name,
    required this.type,
    required this.isRequired,
    required this.isNullable,
  });
}
