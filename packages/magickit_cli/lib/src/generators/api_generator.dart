import '../utils/string_utils.dart';

class ApiGenerator {
  /// Generate Dart model class dari JSON sample data.
  ///
  /// [modelName] — nama model (e.g. "user" → UserModel)
  /// [jsonSample] — contoh JSON untuk inferensi tipe
  String generateModel(
    String modelName,
    Map<String, dynamic> jsonSample, {
    bool generateRepository = false,
  }) {
    final pascal = toPascalCase(modelName);
    final snake = toSnakeCase(pascal);

    final fields = _inferFields(jsonSample);
    final nestedClasses = _collectNestedClasses(jsonSample, pascal);

    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit api` to regenerate.')
      ..writeln();

    // Write nested classes first
    for (final nested in nestedClasses) {
      buffer
        ..writeln(nested)
        ..writeln();
    }

    // Main model class
    buffer.writeln('class ${pascal}Model {');

    // Fields
    for (final field in fields) {
      buffer.writeln('  final ${field.dartType} ${field.name};');
    }
    buffer.writeln();

    // Constructor
    buffer.writeln('  const ${pascal}Model({');
    for (final field in fields) {
      final required = field.isNullable ? '' : 'required ';
      buffer.writeln('    ${required}this.${field.name},');
    }
    buffer.writeln('  });');
    buffer.writeln();

    // fromJson
    buffer.writeln('  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return ${pascal}Model(');
    for (final field in fields) {
      buffer.writeln('      ${field.name}: ${field.fromJsonExpr},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // toJson
    buffer.writeln('  Map<String, dynamic> toJson() => {');
    for (final field in fields) {
      buffer.writeln("    '${field.jsonKey}': ${field.toJsonExpr},");
    }
    buffer.writeln('  };');
    buffer.writeln();

    // copyWith
    buffer.writeln('  ${pascal}Model copyWith({');
    for (final field in fields) {
      final nullable = field.isNullable ? field.dartType : '${field.dartType}?';
      buffer.writeln('    $nullable ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return ${pascal}Model(');
    for (final field in fields) {
      buffer.writeln('      ${field.name}: ${field.name} ?? this.${field.name},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');

    if (generateRepository) {
      buffer
        ..writeln()
        ..writeln(_repositoryTemplate(pascal, snake));
    }

    return buffer.toString();
  }

  List<_FieldInfo> _inferFields(Map<String, dynamic> json) {
    return json.entries.map((e) {
      final name = toCamelCase(e.key);
      final (type, isNullable, fromJson, toJson) = _inferType(
        e.key,
        e.value,
        toPascalCase(e.key),
      );
      return _FieldInfo(
        name: name,
        jsonKey: e.key,
        dartType: isNullable ? '$type?' : type,
        isNullable: isNullable,
        fromJsonExpr: fromJson,
        toJsonExpr: toJson,
      );
    }).toList();
  }

  (String type, bool isNullable, String fromJson, String toJson) _inferType(
    String key,
    dynamic value,
    String nestedPrefix,
  ) {
    final camelKey = toCamelCase(key);

    if (value == null) {
      return ('dynamic', true, "json['$key']", camelKey);
    }
    if (value is bool) {
      return (
        'bool',
        false,
        "json['$key'] as bool? ?? false",
        camelKey,
      );
    }
    if (value is int) {
      return (
        'int',
        false,
        "json['$key'] as int? ?? 0",
        camelKey,
      );
    }
    if (value is double) {
      return (
        'double',
        false,
        "(json['$key'] as num?)?.toDouble() ?? 0.0",
        camelKey,
      );
    }
    if (value is String) {
      return (
        'String',
        false,
        "json['$key'] as String? ?? ''",
        camelKey,
      );
    }
    if (value is Map<String, dynamic>) {
      return (
        '${nestedPrefix}Model',
        false,
        "${nestedPrefix}Model.fromJson(json['$key'] as Map<String, dynamic>)",
        '$camelKey.toJson()',
      );
    }
    if (value is List) {
      if (value.isEmpty) {
        return (
          'List<dynamic>',
          false,
          "(json['$key'] as List<dynamic>?) ?? []",
          camelKey,
        );
      }
      final first = value.first;
      if (first is String) {
        return (
          'List<String>',
          false,
          "(json['$key'] as List<dynamic>?)?.map((e) => e as String).toList() ?? []",
          camelKey,
        );
      }
      if (first is int) {
        return (
          'List<int>',
          false,
          "(json['$key'] as List<dynamic>?)?.map((e) => e as int).toList() ?? []",
          camelKey,
        );
      }
      if (first is Map<String, dynamic>) {
        return (
          'List<${nestedPrefix}Model>',
          false,
          "(json['$key'] as List<dynamic>?)?.map((e) => ${nestedPrefix}Model.fromJson(e as Map<String, dynamic>)).toList() ?? []",
          '$camelKey.map((e) => e.toJson()).toList()',
        );
      }
    }

    return ('dynamic', true, "json['$key']", camelKey);
  }

  List<String> _collectNestedClasses(
    Map<String, dynamic> json,
    String parentPrefix,
  ) {
    final results = <String>[];
    for (final entry in json.entries) {
      final pascal = toPascalCase(entry.key);
      if (entry.value is Map<String, dynamic>) {
        final nested = entry.value as Map<String, dynamic>;
        // Recursively collect deeper nested
        results.addAll(_collectNestedClasses(nested, pascal));
        results.add(_nestedClass('${pascal}Model', nested));
      } else if (entry.value is List &&
          (entry.value as List).isNotEmpty &&
          (entry.value as List).first is Map<String, dynamic>) {
        final nested = (entry.value as List).first as Map<String, dynamic>;
        results.addAll(_collectNestedClasses(nested, pascal));
        results.add(_nestedClass('${pascal}Model', nested));
      }
    }
    return results;
  }

  String _nestedClass(String className, Map<String, dynamic> json) {
    final fields = _inferFields(json);
    final buffer = StringBuffer()..writeln('class $className {');
    for (final f in fields) {
      buffer.writeln('  final ${f.dartType} ${f.name};');
    }
    buffer.writeln();
    buffer.writeln('  const $className({');
    for (final f in fields) {
      buffer.writeln('    ${f.isNullable ? '' : 'required '}this.${f.name},');
    }
    buffer.writeln('  });');
    buffer.writeln();
    buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $className(');
    for (final f in fields) {
      buffer.writeln('      ${f.name}: ${f.fromJsonExpr},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  Map<String, dynamic> toJson() => {');
    for (final f in fields) {
      buffer.writeln("    '${f.jsonKey}': ${f.toJsonExpr},");
    }
    buffer.writeln('  };');
    buffer.writeln('}');
    return buffer.toString();
  }

  String _repositoryTemplate(String pascal, String snake) => '''
abstract class ${pascal}Repository {
  Future<${pascal}Model> get(String id);
  Future<List<${pascal}Model>> getAll();
}

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  // TODO: inject datasource

  @override
  Future<${pascal}Model> get(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<List<${pascal}Model>> getAll() async {
    throw UnimplementedError();
  }
}
''';
}

class _FieldInfo {
  final String name;
  final String jsonKey;
  final String dartType;
  final bool isNullable;
  final String fromJsonExpr;
  final String toJsonExpr;

  const _FieldInfo({
    required this.name,
    required this.jsonKey,
    required this.dartType,
    required this.isNullable,
    required this.fromJsonExpr,
    required this.toJsonExpr,
  });
}
