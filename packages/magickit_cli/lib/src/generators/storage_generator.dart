import 'dart:convert';
import 'dart:io';

import '../utils/string_utils.dart';

// ---------------------------------------------------------------------------
// Public data structures
// ---------------------------------------------------------------------------

class FieldDef {
  final String name;
  final String dartType;
  final bool isId;
  final bool isUnique;
  final bool isNullable;
  final String? defaultValue;

  const FieldDef({
    required this.name,
    required this.dartType,
    this.isId = false,
    this.isUnique = false,
    this.isNullable = false,
    this.defaultValue,
  });
}

class RelationDef {
  final String name;
  final String type; // "ToOne" | "ToMany"
  final String target;

  const RelationDef({
    required this.name,
    required this.type,
    required this.target,
  });
}

class EntityDef {
  final String entity; // PascalCase class name
  final String table; // snake_case table/box name
  final List<FieldDef> fields;
  final List<String> indexes;
  final List<RelationDef> relations;

  const EntityDef({
    required this.entity,
    required this.table,
    required this.fields,
    this.indexes = const [],
    this.relations = const [],
  });
}

// ---------------------------------------------------------------------------
// Main StorageGenerator class
// ---------------------------------------------------------------------------

class StorageGenerator {
  final String appName;

  StorageGenerator({required this.appName});

  static const _dartReserved = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'Function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };

  // ---------------------------------------------------------------------------
  // Parse entity schema from JSON file
  // ---------------------------------------------------------------------------

  EntityDef parseEntitySchema(String jsonPath) {
    final file = File(jsonPath);
    if (!file.existsSync()) {
      throw Exception('Entity schema file not found: $jsonPath');
    }

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final entityRaw = json['entity'] as String? ?? '';
    if (entityRaw.isEmpty) throw Exception('Missing "entity" in $jsonPath');

    final entity = toPascalCase(entityRaw);
    final table = json['table'] as String? ?? toSnakeCase(entityRaw);
    final rawFields = json['fields'] as List<dynamic>? ?? [];
    final rawIndexes = (json['indexes'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final rawRelations = json['relations'] as List<dynamic>? ?? [];

    final fields = <FieldDef>[];
    bool hasId = false;

    for (final raw in rawFields) {
      final fieldMap = raw as Map<String, dynamic>;
      final name = fieldMap['name'] as String?;
      if (name == null || name.isEmpty) {
        throw Exception('Field missing "name" in $jsonPath');
      }

      final typeRaw = fieldMap['type'] as String? ?? 'string';
      final dartType = _schemaTypeToDartType(typeRaw);
      final isId = fieldMap['id'] as bool? ?? false;
      final isUnique = fieldMap['unique'] as bool? ?? false;
      final isNullable = fieldMap['nullable'] as bool? ?? false;
      final defaultValue = fieldMap['default']?.toString();

      if (isId) hasId = true;

      fields.add(FieldDef(
        name: _safeName(name),
        dartType: dartType,
        isId: isId,
        isUnique: isUnique,
        isNullable: isNullable,
        defaultValue: defaultValue,
      ));
    }

    if (!hasId) {
      fields.insert(
          0,
          const FieldDef(
            name: 'id',
            dartType: 'int',
            isId: true,
          ));
    }

    final relations = <RelationDef>[];
    for (final raw in rawRelations) {
      final relMap = raw as Map<String, dynamic>;
      final relName = relMap['name'] as String?;
      final relType = relMap['type'] as String? ?? 'ToOne';
      final relTarget = relMap['target'] as String?;
      if (relName == null || relTarget == null) {
        throw Exception('Relation missing "name" or "target" in $jsonPath');
      }
      relations.add(RelationDef(
        name: _safeName(relName),
        type: relType,
        target: toPascalCase(relTarget),
      ));
    }

    return EntityDef(
      entity: entity,
      table: table,
      fields: fields,
      indexes: rawIndexes,
      relations: relations,
    );
  }

  // ---------------------------------------------------------------------------
  // Generate ObjectBox Store singleton
  // ---------------------------------------------------------------------------

  String generateObjectBoxStore(List<EntityDef> entities) {
    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln(
          '// Run `magickit storage generate` then `dart run build_runner build`.')
      ..writeln()
      ..writeln("import 'package:$appName/objectbox.g.dart';")
      ..writeln();

    for (final entity in entities) {
      final snake = toSnakeCase(entity.entity);
      buf.writeln("import 'models/${snake}_model.dart';");
    }

    buf
      ..writeln()
      ..writeln('/// ObjectBox Store singleton.')
      ..writeln('class ObjectBoxStore {')
      ..writeln('  ObjectBoxStore._internal(this.store);')
      ..writeln()
      ..writeln('  final Store store;')
      ..writeln()
      ..writeln('  static ObjectBoxStore? _instance;')
      ..writeln()
      ..writeln('  /// Create or get the existing store instance.')
      ..writeln(
          '  static Future<ObjectBoxStore> create({String? directory}) async {')
      ..writeln('    if (_instance != null) return _instance!;')
      ..writeln()
      ..writeln('    final store = await openStore(directory: directory);')
      ..writeln('    _instance = ObjectBoxStore._internal(store);')
      ..writeln('    _instance!._initBoxes();')
      ..writeln('    return _instance!;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// Get the existing store instance.')
      ..writeln('  static ObjectBoxStore get instance {')
      ..writeln('    final instance = _instance;')
      ..writeln('    if (instance == null) {')
      ..writeln("      throw StateError(")
      ..writeln(
          "        'ObjectBoxStore not initialized. Call ObjectBoxStore.create() first.',")
      ..writeln('      );')
      ..writeln('    }')
      ..writeln('    return instance;')
      ..writeln('  }')
      ..writeln();

    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf.writeln('  late final Box<${entity.entity}> $boxName;');
    }

    buf
      ..writeln()
      ..writeln('  void _initBoxes() {');
    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf.writeln('    $boxName = store.box<${entity.entity}>();');
    }
    buf
      ..writeln('  }')
      ..writeln()
      ..writeln('  void close() => store.close();')
      ..writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Generate @Entity model class
  // ---------------------------------------------------------------------------

  String generateEntityModel(EntityDef entity) {
    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln(
          '// Run `magickit storage generate` then `dart run build_runner build`.')
      ..writeln()
      ..writeln("import 'package:objectbox/objectbox.dart';")
      ..writeln();

    // Import relations
    for (final rel in entity.relations) {
      final snake = toSnakeCase(rel.target);
      buf.writeln("import '${snake}_model.dart';");
    }

    buf
      ..writeln()
      ..writeln('@Entity()')
      ..writeln('class ${entity.entity} {');

    // Fields
    for (final field in entity.fields) {
      if (field.isId) {
        buf
          ..writeln('  @Id()')
          ..writeln('  int ${field.name};');
      } else {
        final annotations = <String>[];
        if (field.isUnique) annotations.add('@Unique()');
        for (final idx in entity.indexes) {
          if (idx == field.name) {
            annotations.add('@Index()');
          }
        }

        for (final a in annotations) {
          buf.writeln('  $a');
        }

        final type = field.isNullable ? '${field.dartType}?' : field.dartType;
        final defaultVal = field.isNullable
            ? ''
            : (field.dartType == 'String'
                ? " = ''"
                : field.dartType == 'int'
                    ? ' = 0'
                    : field.dartType == 'double'
                        ? ' = 0.0'
                        : field.dartType == 'bool'
                            ? ' = false'
                            : '');
        buf.writeln('  $type ${field.name}$defaultVal;');
      }
    }

    // Relations
    for (final rel in entity.relations) {
      if (rel.type == 'ToOne') {
        buf
          ..writeln()
          ..writeln('  final ${rel.name} = ToOne<${rel.target}>();');
      } else {
        buf
          ..writeln()
          ..writeln('  late final ${rel.name} = ToMany<${rel.target}>();');
      }
    }

    // Constructor
    final requiredFields = entity.fields.where((f) => !f.isId && !f.isNullable);
    final optionalFields = entity.fields.where((f) => f.isId || f.isNullable);

    buf.writeln();
    buf.writeln('  ${entity.entity}({');
    for (final f in requiredFields) {
      buf.writeln('    required this.${f.name},');
    }
    for (final f in optionalFields) {
      buf.writeln('    this.${f.name}${f.isId ? ' = 0' : ''},');
    }
    buf.writeln('  });');

    // fromJson / toJson
    buf
      ..writeln()
      ..writeln(
          '  factory ${entity.entity}.fromJson(Map<String, dynamic> json) => ${entity.entity}(');
    for (final f in entity.fields) {
      if (f.isId) continue;
      final fromExpr = _fromJsonExpr(f);
      buf.writeln('    ${f.name}: $fromExpr,');
    }
    buf.writeln('  );');

    buf
      ..writeln()
      ..writeln('  Map<String, dynamic> toJson() => {');
    for (final f in entity.fields) {
      buf.writeln(
          "    '${f.name}': ${f.name}${_toJsonCast(f.dartType, f.isNullable)},");
    }
    buf.writeln('  };');

    buf
      ..writeln()
      ..writeln('  @override')
      ..writeln('  String toString() {')
      ..writeln(
          "    return '${entity.entity}{${entity.fields.map((f) => '${f.name}: \$${f.name}').join(', ')}}';")
      ..writeln('  }')
      ..writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Generate per-entity storage helper with typed CRUD
  // ---------------------------------------------------------------------------

  String generateEntityStorageHelper(EntityDef entity) {
    final snake = toSnakeCase(entity.entity);
    final boxName = '${toCamelCase(entity.entity)}Box';

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit storage generate` to regenerate.')
      ..writeln()
      ..writeln(
          "import 'package:$appName/core/storage/objectbox/objectbox_store.dart';")
      ..writeln("import 'package:$appName/objectbox.g.dart';")
      ..writeln(
          "import 'package:$appName/core/storage/objectbox/models/${snake}_model.dart';")
      ..writeln()
      ..writeln('/// Storage helper for ${entity.entity}.')
      ..writeln(
          '/// Provides typed CRUD operations for the ${entity.entity} box.')
      ..writeln('class ${entity.entity}StorageHelper {')
      ..writeln('  late final Box<${entity.entity}> _box;')
      ..writeln()
      ..writeln('  ${entity.entity}StorageHelper() {')
      ..writeln('    _box = ObjectBoxStore.instance.$boxName;')
      ..writeln('  }')
      ..writeln()

      // ── CREATE
      ..writeln('  // ── CREATE ──────────────────────────────────────────')
      ..writeln()
      ..writeln(
          '  /// Create or update a ${entity.entity}. Returns the object ID.')
      ..writeln('  int put(${entity.entity} item) => _box.put(item);')
      ..writeln()
      ..writeln('  /// Create or update multiple items. Returns list of IDs.')
      ..writeln(
          '  List<int> putMany(List<${entity.entity}> items) => _box.putMany(items);')
      ..writeln()

      // ── READ
      ..writeln('  // ── READ ────────────────────────────────────────────')
      ..writeln()
      ..writeln('  /// Get ${entity.entity} by ID.')
      ..writeln('  ${entity.entity}? get(int id) => _box.get(id);')
      ..writeln()
      ..writeln('  /// Get all ${entity.entity}.')
      ..writeln('  List<${entity.entity}> getAll() => _box.getAll();')
      ..writeln()
      ..writeln('  /// Get first item matching a query.')
      ..writeln('  ${entity.entity}? getFirst(Query<${entity.entity}> query) {')
      ..writeln('    final result = query.findFirst();')
      ..writeln('    query.close();')
      ..writeln('    return result;')
      ..writeln('  }')
      ..writeln()
      ..writeln('  /// Get all items matching a query.')
      ..writeln(
          '  List<${entity.entity}> getAllMatches(Query<${entity.entity}> query) {')
      ..writeln('    final results = query.find();')
      ..writeln('    query.close();')
      ..writeln('    return results;')
      ..writeln('  }')
      ..writeln();

    // Query helpers for indexed/unique fields
    final queryFields = entity.fields
        .where((f) => f.isUnique || entity.indexes.contains(f.name));
    if (queryFields.isNotEmpty) {
      buf.writeln('  // ── QUERY HELPERS ─────────────────────────────────');
      buf.writeln();
      for (final field in queryFields) {
        buf
          ..writeln('  /// Get ${entity.entity} by ${field.name}.')
          ..writeln(
              '  ${entity.entity}? getBy${toPascalCase(field.name)}(${field.dartType} ${field.name}) {')
          ..writeln(
              '    final query = _box.query(${entity.entity}_.${field.name}.equals(${field.name})).build();')
          ..writeln('    final result = query.findFirst();')
          ..writeln('    query.close();')
          ..writeln('    return result;')
          ..writeln('  }')
          ..writeln();
      }
    }

    // Search helper for string fields
    final stringFields =
        entity.fields.where((f) => f.dartType == 'String').toList();
    if (stringFields.isNotEmpty) {
      buf
        ..writeln('  // ── SEARCH ────────────────────────────────────────')
        ..writeln()
        ..writeln(
            '  /// Search ${entity.entity} by partial match on string fields.')
        ..writeln('  List<${entity.entity}> search(String query) {')
        ..writeln('    final conditions = <Condition<${entity.entity}>>[];');

      for (final field in stringFields) {
        buf.writeln(
            '    conditions.add(${entity.entity}_.${field.name}.contains(query, caseSensitive: false));');
      }

      buf
        ..writeln('    if (conditions.isEmpty) return [];')
        ..writeln(
            '    final q = _box.query(conditions.reduce((a, b) => a.or(b))).build();')
        ..writeln('    final results = q.find();')
        ..writeln('    q.close();')
        ..writeln('    return results;')
        ..writeln('  }')
        ..writeln();
    }

    // ── UPDATE
    buf
      ..writeln('  // ── UPDATE ──────────────────────────────────────────')
      ..writeln()
      ..writeln('  /// Update an existing ${entity.entity}. Same as [put].')
      ..writeln('  int update(${entity.entity} item) => _box.put(item);')
      ..writeln()
      ..writeln('  /// Update multiple items. Same as [putMany].')
      ..writeln(
          '  List<int> updateMany(List<${entity.entity}> items) => _box.putMany(items);')
      ..writeln()

      // ── DELETE
      ..writeln('  // ── DELETE ──────────────────────────────────────────')
      ..writeln()
      ..writeln('  /// Delete ${entity.entity} by ID. Returns true if removed.')
      ..writeln('  bool delete(int id) => _box.remove(id);')
      ..writeln()
      ..writeln('  /// Delete multiple items by IDs.')
      ..writeln('  int deleteMany(List<int> ids) => _box.removeMany(ids);')
      ..writeln()

      // ── CLEAR & COUNT
      ..writeln('  // ── CLEAR & COUNT ───────────────────────────────────')
      ..writeln()
      ..writeln('  /// Delete all ${entity.entity} from the box.')
      ..writeln('  void clear() => _box.removeAll();')
      ..writeln()
      ..writeln('  /// Count items in the box.')
      ..writeln('  int count() => _box.count();')
      ..writeln()
      ..writeln('  /// Check if box is empty.')
      ..writeln('  bool get isEmpty => _box.isEmpty();')
      ..writeln()
      ..writeln('  /// Check if box has data.')
      ..writeln('  bool get isNotEmpty => _box.count() > 0;')
      ..writeln()

      // ── RAW BOX ACCESS
      ..writeln('  // ── RAW ACCESS ──────────────────────────────────────')
      ..writeln()
      ..writeln('  /// Get the underlying Box for advanced queries.')
      ..writeln('  Box<${entity.entity}> get box => _box;')
      ..writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Generate table operations (create/drop/clear)
  // ---------------------------------------------------------------------------

  String generateTableOperations(EntityDef entity, String operation) {
    final snake = toSnakeCase(entity.entity);
    final boxName = '${toCamelCase(entity.entity)}Box';

    return switch (operation) {
      'create' => """// Table operation: CREATE ${entity.table}
// Run: dart run build_runner build --delete-conflicting-outputs
//
// The @Entity() annotation in models/${snake}_model.dart will be
// picked up by objectbox_generator automatically.
//
// Steps:
// 1. Run: dart run build_runner build --delete-conflicting-outputs
// 2. The box '${entity.entity}' will be available via ObjectBoxStore.instance.$boxName
// 3. Use ${entity.entity}StorageHelper for CRUD operations
""",
      'drop' => """// Table operation: DROP ${entity.table}
//
// ObjectBox does not support dropping individual entity tables via API.
// To remove an entity:
//
// 1. Remove the @Entity() annotation from models/${snake}_model.dart
// 2. Remove the field from objectbox_store.dart
// 3. Remove the entity file from storage/
// 4. Run: dart run build_runner build --delete-conflicting-outputs
// 5. Optionally delete the database: ObjectBoxStore.instance.store.close()
//    then delete the database directory and recreate the store.
//
// Or to clear all data without removing the entity:
//   ObjectBoxStore.instance.$boxName.removeAll();
""",
      'clear' => """// Table operation: CLEAR ${entity.table}
//
// Clear all data from the ${entity.entity} box:
//
//   ObjectBoxStore.instance.$boxName.removeAll();
//
// Or using the storage helper:
//
//   final helper = ${entity.entity}StorageHelper();
//   helper.clear();
""",
      _ => throw Exception('Unknown table operation: $operation'),
    };
  }

  // ---------------------------------------------------------------------------
  // Generate storage injector — register all helpers + init ObjectBoxStore
  // ---------------------------------------------------------------------------

  String generateStorageInjector(List<EntityDef> entities) {
    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit storage generate` to regenerate.')
      ..writeln()
      ..writeln("import 'package:get_it/get_it.dart';")
      ..writeln(
          "import 'package:$appName/core/storage/objectbox/objectbox_store.dart';");

    for (final entity in entities) {
      final snake = toSnakeCase(entity.entity);
      buf.writeln(
          "import 'package:$appName/core/storage/objectbox/helpers/${snake}_storage_helper.dart';");
    }

    buf
      ..writeln()
      ..writeln(
          '/// Register all storage dependencies and initialize ObjectBox.')
      ..writeln('/// Call this in your app startup before using any storage.')
      ..writeln('Future<void> storageInjector() async {')
      ..writeln('  // Initialize ObjectBox store')
      ..writeln('  await ObjectBoxStore.create();')
      ..writeln()
      ..writeln('  final getIt = GetIt.instance;')
      ..writeln();

    for (final entity in entities) {
      buf.writeln(
          '  getIt.registerFactory(() => ${entity.entity}StorageHelper());');
    }

    buf.writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Generate DatabaseManager — export/import database to JSON
  // ---------------------------------------------------------------------------

  String generateDatabaseManager(List<EntityDef> entities) {
    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit storage generate` to regenerate.')
      ..writeln()
      ..writeln("import 'dart:convert';")
      ..writeln("import 'dart:io';")
      ..writeln()
      ..writeln(
          "import 'package:$appName/core/storage/objectbox/objectbox_store.dart';");

    for (final entity in entities) {
      final snake = toSnakeCase(entity.entity);
      buf.writeln(
          "import 'package:$appName/core/storage/objectbox/models/${snake}_model.dart';");
    }

    buf
      ..writeln()
      ..writeln('/// Database manager for export/import operations.')
      ..writeln('class DatabaseManager {')
      ..writeln('  final ObjectBoxStore _store = ObjectBoxStore.instance;')
      ..writeln();

    // Export
    buf
      ..writeln('  /// Export all data to a JSON file.')
      ..writeln('  Future<void> export(String filePath) async {')
      ..writeln('    final data = <String, dynamic>{};');

    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf.writeln(
          "    data['${entity.entity}'] = _store.$boxName.getAll().map((e) => e.toJson()).toList();");
    }

    buf
      ..writeln('    final file = File(filePath);')
      ..writeln('    await file.parent.create(recursive: true);')
      ..writeln(
          '    await file.writeAsString(const JsonEncoder.withIndent(\'  \').convert(data));')
      ..writeln('  }')
      ..writeln();

    // Import
    buf
      ..writeln('  /// Import data from a JSON file.')
      ..writeln('  Future<void> import(String filePath) async {')
      ..writeln('    final file = File(filePath);')
      ..writeln(
          '    if (!file.existsSync()) throw Exception(\'File not found: \$filePath\');')
      ..writeln(
          '    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;');

    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf
        ..writeln('    if (data.containsKey(\'${entity.entity}\')) {')
        ..writeln('      _store.$boxName.removeAll();')
        ..writeln(
            '      final items = (data[\'${entity.entity}\'] as List).map((e) => ${entity.entity}.fromJson(e as Map<String, dynamic>)).toList();')
        ..writeln('      _store.$boxName.putMany(items);')
        ..writeln('    }');
    }

    buf
      ..writeln('  }')
      ..writeln()

      // Clear all
      ..writeln('  /// Clear all data from the database.')
      ..writeln('  void clear() {');

    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf.writeln('    _store.$boxName.removeAll();');
    }

    buf
      ..writeln('  }')
      ..writeln()

      // Get stats
      ..writeln('  /// Get database statistics.')
      ..writeln('  Map<String, int> getStats() => {');

    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf.writeln('    \'${entity.entity}\': _store.$boxName.count(),');
    }

    buf
      ..writeln('  };')
      ..writeln()

      // Get database size
      ..writeln('  /// Get approximate database size in bytes.')
      ..writeln('  int getDatabaseSize() {')
      ..writeln("    // ObjectBox stores data in the app's documents directory")
      ..writeln("    // For Android: /data/data/<package>/app_objectbox/")
      ..writeln("    // For iOS: Library/Application Support/objectbox/")
      ..writeln("    // This is an estimate based on entity counts.")
      ..writeln('    int total = 0;');

    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf.writeln('    total += _store.$boxName.count();');
    }

    buf
      ..writeln('    return total;')
      ..writeln('  }')
      ..writeln('}');

    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // Find all entity schema files
  // ---------------------------------------------------------------------------

  List<String> findEntityFiles(String storageDir) {
    final dir = Directory(storageDir);
    if (!dir.existsSync()) return [];

    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .map((f) => f.path)
        .toList()
      ..sort();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _schemaTypeToDartType(String type) {
    return switch (type.toLowerCase()) {
      'string' || 'str' || 'text' => 'String',
      'int' || 'integer' => 'int',
      'double' || 'float' || 'number' => 'double',
      'bool' || 'boolean' => 'bool',
      'datetime' || 'date' => 'DateTime',
      'list' || 'array' => 'List<String>',
      'map' || 'object' => 'Map<String, dynamic>',
      _ => 'String',
    };
  }

  String _safeName(String name) {
    if (_dartReserved.contains(name)) return '\$$name';
    return name;
  }

  String _fromJsonExpr(FieldDef field) {
    final key = field.name;
    return switch (field.dartType) {
      'String' => "json['$key'] as String? ?? ''",
      'int' => "json['$key'] as int? ?? 0",
      'double' => "(json['$key'] as num?)?.toDouble() ?? 0.0",
      'bool' => "json['$key'] as bool? ?? false",
      'DateTime' => field.isNullable
          ? "json['$key'] != null ? DateTime.parse(json['$key'] as String) : null"
          : "json['$key'] != null ? DateTime.parse(json['$key'] as String) : DateTime.now()",
      'List<String>' =>
        "(json['$key'] as List<dynamic>?)?.map((e) => e as String).toList() ?? []",
      'Map<String, dynamic>' => "(json['$key'] as Map<String, dynamic>?) ?? {}",
      _ => "json['$key'] as String? ?? ''",
    };
  }

  String _toJsonCast(String dartType, bool isNullable) {
    return switch (dartType) {
      'DateTime' => isNullable ? '?.toIso8601String()' : '.toIso8601String()',
      _ => '',
    };
  }
}
