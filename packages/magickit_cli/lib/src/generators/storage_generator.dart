import 'dart:convert';
import 'dart:io';

import '../utils/string_utils.dart';

/// One or more entity-schema problems. [errors] are ready to show to the user.
class StorageSchemaException implements Exception {
  final List<String> errors;

  StorageSchemaException(this.errors);

  @override
  String toString() => errors.join('\n');
}

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

  /// Relation name on [target] that this ToMany reverses.
  ///
  /// Null means this relation owns its links (standalone ToOne/ToMany).
  final String? backlink;

  /// `cascade` or `nullify`. Null keeps ObjectBox's default delete behavior.
  final String? onDelete;

  const RelationDef({
    required this.name,
    required this.type,
    required this.target,
    this.backlink,
    this.onDelete,
  });

  bool get isBacklink => backlink != null;
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

  /// Load every entity JSON directly inside [storageDir].
  ///
  /// Nested JSON files are ignored. Throws [StorageSchemaException] with every
  /// problem found, so callers can fail before writing files.
  List<EntityDef> loadEntities(String storageDir) {
    final files = findEntityFiles(storageDir);
    final entities = <EntityDef>[];
    final errors = <String>[];

    for (final file in files) {
      try {
        entities.add(parseEntitySchema(file));
      } on StorageSchemaException catch (e) {
        errors.addAll(e.errors);
      } on FormatException catch (e) {
        errors.add('$file: ${e.message}');
      } catch (e) {
        errors.add('$file: $e');
      }
    }

    errors.addAll(crossValidate(entities));
    if (errors.isNotEmpty) {
      throw StorageSchemaException(errors);
    }
    return entities;
  }

  /// Relation targets and duplicate entity names, checked across [entities].
  List<String> crossValidate(List<EntityDef> entities) {
    final errors = <String>[];
    final counts = <String, int>{};
    for (final entity in entities) {
      counts.update(entity.entity, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final entry in counts.entries) {
      if (entry.value > 1) {
        errors.add(
          'Entity "${entry.key}" didefinisikan ${entry.value} kali di storage/.',
        );
      }
    }

    final known = counts.keys.toSet();
    final backlinkOwners = <String, String>{};
    for (final entity in entities) {
      for (final relation in entity.relations) {
        if (!known.contains(relation.target)) {
          errors.add(
            'Relasi "${relation.name}" pada ${entity.entity} menunjuk ke '
            '"${relation.target}" yang tidak ada di storage/.',
          );
          continue;
        }
        final backlink = relation.backlink;
        if (backlink == null) continue;

        final target =
            entities.firstWhere((item) => item.entity == relation.target);
        final matches =
            target.relations.where((item) => item.name == backlink).toList();
        if (matches.isEmpty) {
          errors.add(
            'Relasi "${relation.name}" pada ${entity.entity} memakai backlink '
            '"$backlink" yang tidak ada pada ${relation.target}.',
          );
          continue;
        }
        if (matches.length > 1) {
          errors.add(
            'Relasi "${relation.name}" pada ${entity.entity} memakai backlink '
            '"$backlink", tetapi ${relation.target} punya lebih dari satu '
            'relasi dengan nama itu.',
          );
          continue;
        }
        final owner = matches.single;
        if (owner.target != entity.entity) {
          errors.add(
            'Relasi "${relation.name}" pada ${entity.entity} memakai backlink '
            '"$backlink", tetapi relasi itu menunjuk ke "${owner.target}", '
            'bukan ${entity.entity}.',
          );
          continue;
        }
        if (owner.isBacklink) {
          errors.add(
            'Relasi "${relation.name}" pada ${entity.entity} memakai backlink '
            '"$backlink" yang sendiri sebuah backlink. Tuju relasi pemiliknya '
            '(tanpa backlink).',
          );
          continue;
        }
        final key = '${relation.target}.$backlink';
        final previous = backlinkOwners[key];
        if (previous != null) {
          errors.add(
            'Backlink "$key" dipakai oleh $previous dan '
            '${entity.entity}.${relation.name}. Satu relasi pemilik hanya '
            'boleh punya satu backlink.',
          );
          continue;
        }
        backlinkOwners[key] = '${entity.entity}.${relation.name}';
      }
    }
    return errors;
  }

  EntityDef parseEntitySchema(String jsonPath) {
    final file = File(jsonPath);
    if (!file.existsSync()) {
      throw StorageSchemaException(
        ['File schema tidak ditemukan: $jsonPath'],
      );
    }

    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      throw StorageSchemaException(
        ['$jsonPath: schema harus berupa object JSON.'],
      );
    }
    final json = decoded;
    final errors = <String>[];

    final entityRaw = json['entity'] as String? ?? '';
    if (entityRaw.trim().isEmpty) {
      errors.add('$jsonPath: field "entity" wajib diisi.');
    }
    final entity = entityRaw.trim().isEmpty ? '' : toPascalCase(entityRaw);
    if (entity.isNotEmpty && !_isDartIdentifier(entity)) {
      errors.add(
        '$jsonPath: nama entity "$entityRaw" tidak valid untuk class Dart.',
      );
    }

    final table = json['table'] as String? ??
        (entityRaw.trim().isEmpty ? '' : toSnakeCase(entityRaw));
    final rawFields = json['fields'] as List<dynamic>? ?? [];
    final rawIndexes = (json['indexes'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet()
        .toList();
    final rawRelations = json['relations'] as List<dynamic>? ?? [];

    final fields = <FieldDef>[];
    final fieldNames = <String>{};
    var hasId = false;

    for (final raw in rawFields) {
      if (raw is! Map) {
        errors.add('$jsonPath: setiap field harus berupa object.');
        continue;
      }
      final fieldMap = Map<String, dynamic>.from(raw);
      final name = fieldMap['name'] as String?;
      if (name == null || name.isEmpty) {
        errors.add('$jsonPath: ada field tanpa "name".');
        continue;
      }
      if (!_isDartIdentifier(name)) {
        errors.add(
          '$jsonPath: nama field "$name" tidak valid. '
          'Gunakan identifier Dart dan hindari kata kunci.',
        );
        continue;
      }
      if (!fieldNames.add(name)) {
        errors.add('$jsonPath: field "$name" duplikat.');
        continue;
      }

      final typeRaw = fieldMap['type'] as String?;
      if (typeRaw == null || typeRaw.trim().isEmpty) {
        errors.add('$jsonPath: field "$name" tidak punya "type".');
        continue;
      }
      final dartType = _schemaTypeToDartType(typeRaw);
      if (dartType == null) {
        errors.add(
          '$jsonPath: tipe "$typeRaw" pada field "$name" tidak didukung. '
          'Gunakan String, int, double, bool, DateTime, List, atau Map.',
        );
        continue;
      }

      final isId = fieldMap['id'] as bool? ?? false;
      final isUnique = fieldMap['unique'] as bool? ?? false;
      final isNullable = fieldMap['nullable'] as bool? ?? false;
      final defaultValue = fieldMap['default']?.toString();
      if (isId) hasId = true;

      if ((isUnique || rawIndexes.contains(name)) &&
          _unindexableTypes.contains(dartType)) {
        errors.add(
          '$jsonPath: index/unique tidak didukung untuk field "$name" '
          'bertipe $dartType. Index hanya untuk String, int, bool, dan DateTime.',
        );
      }
      if (isId && (isUnique || rawIndexes.contains(name))) {
        errors.add(
          '$jsonPath: field id "$name" sudah unik. '
          'Jangan tambahkan index atau unique.',
        );
      }

      fields.add(FieldDef(
        name: name,
        dartType: dartType,
        isId: isId,
        isUnique: isUnique,
        isNullable: isNullable,
        defaultValue: defaultValue,
      ));
    }

    if (fields.where((field) => field.isId).length > 1) {
      errors.add('$jsonPath: hanya boleh ada satu field id.');
    }

    if (!hasId && errors.isEmpty) {
      fields.insert(
        0,
        const FieldDef(
          name: 'id',
          dartType: 'int',
          isId: true,
        ),
      );
      fieldNames.add('id');
      if (rawIndexes.contains('id')) {
        errors.add(
          '$jsonPath: field id sudah unik. Jangan tambahkan index atau unique.',
        );
      }
    }

    for (final index in rawIndexes) {
      if (!fieldNames.contains(index)) {
        errors.add(
          '$jsonPath: index "$index" tidak merujuk ke field yang ada.',
        );
      }
    }

    final relations = <RelationDef>[];
    final relationNames = <String>{};
    for (final raw in rawRelations) {
      if (raw is! Map) {
        errors.add('$jsonPath: setiap relasi harus berupa object.');
        continue;
      }
      final relMap = Map<String, dynamic>.from(raw);
      final relName = relMap['name'] as String?;
      final relTypeRaw = relMap['type'] as String?;
      final relTarget = relMap['target'] as String?;
      if (relName == null || relName.isEmpty || relTarget == null) {
        errors.add(
          '$jsonPath: relasi wajib punya "name" dan "target".',
        );
        continue;
      }
      if (!_isDartIdentifier(relName)) {
        errors.add(
          '$jsonPath: nama relasi "$relName" tidak valid. '
          'Gunakan identifier Dart dan hindari kata kunci.',
        );
        continue;
      }
      if (!relationNames.add(relName)) {
        errors.add('$jsonPath: relasi "$relName" duplikat.');
        continue;
      }
      if (fieldNames.contains(relName)) {
        errors.add(
          '$jsonPath: nama relasi "$relName" bentrok dengan field.',
        );
        continue;
      }
      if (relTarget.trim().isEmpty) {
        errors.add('$jsonPath: relasi "$relName" tidak punya target.');
        continue;
      }
      final relType =
          relTypeRaw == null ? null : _canonicalRelationType(relTypeRaw);
      if (relType == null) {
        errors.add(
          '$jsonPath: relasi "$relName" memakai tipe '
          '"${relTypeRaw ?? ''}". Gunakan ToOne atau ToMany.',
        );
        continue;
      }

      final backlink =
          _parseBacklink(jsonPath, relName, relType, relMap, errors);
      final onDelete =
          _parseOnDelete(jsonPath, relName, relType, relMap, errors);
      if (backlink == _invalidToken || onDelete == _invalidToken) continue;

      if (backlink == null &&
          relType == 'ToOne' &&
          fieldNames.contains('${relName}Id')) {
        errors.add(
          '$jsonPath: relasi "$relName" mengekspor "${relName}Id" yang '
          'bentrok dengan field.',
        );
        continue;
      }
      if (backlink == null &&
          relType == 'ToMany' &&
          fieldNames.contains('${relName}Ids')) {
        errors.add(
          '$jsonPath: relasi "$relName" mengekspor "${relName}Ids" yang '
          'bentrok dengan field.',
        );
        continue;
      }

      relations.add(RelationDef(
        name: relName,
        type: relType,
        target: toPascalCase(relTarget),
        backlink: backlink,
        onDelete: onDelete,
      ));
    }

    if (errors.isNotEmpty) {
      throw StorageSchemaException(errors);
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
      ..writeln('  void close() {')
      ..writeln('    store.close();')
      ..writeln('    _instance = null;')
      ..writeln('  }')
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

    // Import relations. A self-relation stays in this file.
    final importedTargets = <String>{};
    for (final rel in entity.relations) {
      if (rel.target == entity.entity || !importedTargets.add(rel.target)) {
        continue;
      }
      buf.writeln("import '${toSnakeCase(rel.target)}_model.dart';");
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

    // Relations. Standalone ToMany keeps the previous shape. A backlink is
    // the ObjectBox view of a relation owned by the target entity.
    for (final rel in entity.relations) {
      buf.writeln();
      if (rel.isBacklink) {
        buf.writeln("  @Backlink('${rel.backlink}')");
        buf.writeln('  final ${rel.name} = ToMany<${rel.target}>();');
      } else if (rel.type == 'ToOne') {
        buf.writeln('  final ${rel.name} = ToOne<${rel.target}>();');
      } else {
        buf.writeln('  late final ${rel.name} = ToMany<${rel.target}>();');
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

    // fromJson / toJson. Ids and nulls are preserved. Owning ToOne relations
    // are restored here; ToMany ids are applied by DatabaseManager.import
    // once every target object exists. Backlinks are derived and omitted.
    buf
      ..writeln()
      ..writeln(
          '  factory ${entity.entity}.fromJson(Map<String, dynamic> json) {')
      ..writeln('    final item = ${entity.entity}(');
    for (final field in entity.fields) {
      if (field.isId) {
        buf.writeln(
            "      ${field.name}: (json['${field.name}'] as num?)?.toInt() ?? 0,");
      } else {
        buf.writeln('      ${field.name}: ${_fromJsonExpr(field)},');
      }
    }
    buf.writeln('    );');
    for (final rel in entity.relations) {
      if (rel.isBacklink || rel.type != 'ToOne') continue;
      buf
        ..writeln("    final ${rel.name}Id = json['${rel.name}Id'];")
        ..writeln(
            '    if (${rel.name}Id is num && ${rel.name}Id.toInt() != 0) {')
        ..writeln('      item.${rel.name}.targetId = ${rel.name}Id.toInt();')
        ..writeln('    }');
    }
    buf
      ..writeln('    return item;')
      ..writeln('  }');

    buf
      ..writeln()
      ..writeln('  Map<String, dynamic> toJson() => {');
    for (final f in entity.fields) {
      buf.writeln(
          "    '${f.name}': ${f.name}${_toJsonCast(f.dartType, f.isNullable)},");
    }
    for (final rel in entity.relations) {
      if (rel.isBacklink) continue;
      if (rel.type == 'ToOne') {
        buf.writeln(
          "    '${rel.name}Id': ${rel.name}.targetId == 0 ? null : ${rel.name}.targetId,",
        );
      } else {
        buf.writeln(
          "    '${rel.name}Ids': ${rel.name}.map((e) => e.id).toList(),",
        );
      }
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

  String generateEntityStorageHelper(
    EntityDef entity, {
    List<EntityDef>? entities,
  }) {
    final all = entities ?? [entity];
    final snake = toSnakeCase(entity.entity);
    final boxName = '${toCamelCase(entity.entity)}Box';
    final hasOnDelete = entity.relations.any((rel) => rel.onDelete != null);

    final buf = StringBuffer()
      ..writeln('// GENERATED CODE — DO NOT EDIT BY HAND')
      ..writeln('// Run `magickit storage generate` to regenerate.')
      ..writeln()
      ..writeln(
          "import 'package:$appName/core/storage/objectbox/objectbox_store.dart';")
      ..writeln("import 'package:$appName/objectbox.g.dart';")
      ..writeln(
          "import 'package:$appName/core/storage/objectbox/models/${snake}_model.dart';");

    final importedTargets = <String>{};
    for (final rel in entity.relations) {
      if (rel.target == entity.entity || !importedTargets.add(rel.target)) {
        continue;
      }
      buf.writeln(
        "import 'package:$appName/core/storage/objectbox/models/${toSnakeCase(rel.target)}_model.dart';",
      );
    }

    buf
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
              '    final query = _box.query(${_equalsCondition(entity, field)}).build();')
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

    _writeRelationHelpers(buf, entity, all);

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
      ..writeln();

    if (!hasOnDelete) {
      buf
        ..writeln(
            '  /// Delete ${entity.entity} by ID. Returns true if removed.')
        ..writeln('  bool delete(int id) => _box.remove(id);')
        ..writeln()
        ..writeln('  /// Delete multiple items by IDs.')
        ..writeln('  int deleteMany(List<int> ids) => _box.removeMany(ids);')
        ..writeln()
        ..writeln('  // ── CLEAR & COUNT ───────────────────────────────────')
        ..writeln()
        ..writeln('  /// Delete all ${entity.entity} from the box.')
        ..writeln('  void clear() => _box.removeAll();')
        ..writeln();
    } else {
      buf
        ..writeln(
            '  /// Delete ${entity.entity} by ID. Returns true if removed.')
        ..writeln('  ///')
        ..writeln(
            '  /// Relations with onDelete run in the same write transaction.')
        ..writeln('  bool delete(int id) {')
        ..writeln(
            '    return ObjectBoxStore.instance.store.runInTransaction(TxMode.write, () {')
        ..writeln('      final item = _box.get(id);')
        ..writeln('      if (item == null) return false;')
        ..writeln('      _applyOnDelete(item);')
        ..writeln('      return _box.remove(id);')
        ..writeln('    });')
        ..writeln('  }')
        ..writeln()
        ..writeln('  /// Delete multiple items by IDs.')
        ..writeln('  int deleteMany(List<int> ids) {')
        ..writeln(
            '    return ObjectBoxStore.instance.store.runInTransaction(TxMode.write, () {')
        ..writeln('      var removed = 0;')
        ..writeln('      for (final id in ids) {')
        ..writeln('        final item = _box.get(id);')
        ..writeln('        if (item == null) continue;')
        ..writeln('        _applyOnDelete(item);')
        ..writeln('        if (_box.remove(id)) removed++;')
        ..writeln('      }')
        ..writeln('      return removed;')
        ..writeln('    });')
        ..writeln('  }')
        ..writeln()
        ..writeln('  // ── CLEAR & COUNT ───────────────────────────────────')
        ..writeln()
        ..writeln('  /// Delete all ${entity.entity} from the box.')
        ..writeln('  void clear() {')
        ..writeln(
            '    ObjectBoxStore.instance.store.runInTransaction(TxMode.write, () {')
        ..writeln('      for (final item in _box.getAll()) {')
        ..writeln('        _applyOnDelete(item);')
        ..writeln('      }')
        ..writeln('      _box.removeAll();')
        ..writeln('    });')
        ..writeln('  }')
        ..writeln();
      _writeOnDelete(buf, entity, all);
    }

    buf
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

  void _writeRelationHelpers(
    StringBuffer buf,
    EntityDef entity,
    List<EntityDef> entities,
  ) {
    if (entity.relations.isEmpty) return;
    buf
      ..writeln('  // ── RELATIONS ───────────────────────────────────────')
      ..writeln();

    for (final rel in entity.relations) {
      if (rel.isBacklink) {
        _writeBacklinkHelpers(buf, entity, rel, entities);
      } else if (rel.type == 'ToOne') {
        _writeToOneHelpers(buf, entity, rel);
      } else {
        _writeToManyHelpers(buf, entity, rel);
      }
    }
  }

  void _writeToOneHelpers(StringBuffer buf, EntityDef entity, RelationDef rel) {
    final method = 'get${_plural(entity.entity)}By${toPascalCase(rel.name)}';
    final param = '${rel.name}Id';
    buf
      ..writeln(
          '  /// ${entity.entity} rows whose ${rel.name} points at [$param].')
      ..writeln('  List<${entity.entity}> $method(int $param) {')
      ..writeln(
          '    final query = _box.query(${entity.entity}_.${rel.name}.equals($param)).build();')
      ..writeln('    final results = query.find();')
      ..writeln('    query.close();')
      ..writeln('    return results;')
      ..writeln('  }')
      ..writeln()
      ..writeln(
          '  /// Assign ${rel.name} and save inside one write transaction.')
      ..writeln(
          '  void set${toPascalCase(rel.name)}(${entity.entity} item, ${rel.target} ${rel.name}) {')
      ..writeln(
          '    ObjectBoxStore.instance.store.runInTransaction(TxMode.write, () {')
      ..writeln('      item.${rel.name}.target = ${rel.name};')
      ..writeln('      _box.put(item);')
      ..writeln('    });')
      ..writeln('  }')
      ..writeln();
  }

  void _writeToManyHelpers(
      StringBuffer buf, EntityDef entity, RelationDef rel) {
    final singular = _singular(rel.name);
    final method = 'get${_plural(entity.entity)}By${toPascalCase(singular)}';
    final param = '${singular}Id';
    buf
      ..writeln(
          '  /// ${entity.entity} rows whose ${rel.name} include [$param].')
      ..writeln('  ///')
      ..writeln(
          '  /// ObjectBox has no query condition for a standalone ToMany, so this reads the box.')
      ..writeln('  List<${entity.entity}> $method(int $param) {')
      ..writeln('    return _box')
      ..writeln('        .getAll()')
      ..writeln(
          '        .where((item) => item.${rel.name}.any((target) => target.id == $param))')
      ..writeln('        .toList();')
      ..writeln('  }')
      ..writeln()
      ..writeln(
          '  /// Replace ${rel.name} and save inside one write transaction.')
      ..writeln(
          '  void set${toPascalCase(rel.name)}(${entity.entity} item, List<${rel.target}> ${rel.name}) {')
      ..writeln(
          '    ObjectBoxStore.instance.store.runInTransaction(TxMode.write, () {')
      ..writeln('      if (item.id != 0) {')
      ..writeln('        for (final existing in item.${rel.name}.toList()) {')
      ..writeln('          item.${rel.name}.remove(existing);')
      ..writeln('        }')
      ..writeln('      }')
      ..writeln('      item.${rel.name}.addAll(${rel.name});')
      ..writeln('      _box.put(item);')
      ..writeln('    });')
      ..writeln('  }')
      ..writeln();
  }

  void _writeBacklinkHelpers(
    StringBuffer buf,
    EntityDef entity,
    RelationDef rel,
    List<EntityDef> entities,
  ) {
    final owner = _owningRelation(entities, rel);
    final ownerName = owner?.name ?? rel.backlink!;
    final ownerIsToOne = owner == null || owner.type == 'ToOne';
    final targetBox = '${toCamelCase(rel.target)}Box';
    buf
      ..writeln(
          '  /// ${rel.target} rows reached through ${rel.name} for this ${entity.entity} id.')
      ..writeln(
          '  List<${rel.target}> get${toPascalCase(rel.name)}Of(int id) {')
      ..writeln('    final item = _box.get(id);')
      ..writeln('    if (item == null) return <${rel.target}>[];')
      ..writeln('    return item.${rel.name}.toList();')
      ..writeln('  }')
      ..writeln()
      ..writeln(
          '  /// Replace ${rel.name} by updating ${rel.target}.$ownerName in one write transaction.')
      ..writeln(
          '  void set${toPascalCase(rel.name)}(${entity.entity} item, List<${rel.target}> ${rel.name}) {')
      ..writeln(
          '    ObjectBoxStore.instance.store.runInTransaction(TxMode.write, () {')
      ..writeln('      if (item.id == 0) {')
      ..writeln('        _box.put(item);')
      ..writeln('      }');
    if (ownerIsToOne) {
      buf
        ..writeln('      for (final related in ${rel.name}) {')
        ..writeln('        related.$ownerName.target = item;')
        ..writeln('        ObjectBoxStore.instance.$targetBox.put(related);')
        ..writeln('      }')
        ..writeln(
            '      final desired = ${rel.name}.map((related) => related.id).toSet();')
        ..writeln('      for (final existing in item.${rel.name}.toList()) {')
        ..writeln('        if (desired.contains(existing.id)) continue;')
        ..writeln('        existing.$ownerName.targetId = 0;')
        ..writeln('        ObjectBoxStore.instance.$targetBox.put(existing);')
        ..writeln('      }');
    } else {
      buf
        ..writeln('      for (final related in ${rel.name}) {')
        ..writeln('        if (related.id == 0) {')
        ..writeln('          ObjectBoxStore.instance.$targetBox.put(related);')
        ..writeln('        }')
        ..writeln(
            '        final linked = related.$ownerName.any((target) => target.id == item.id);')
        ..writeln('        if (!linked) related.$ownerName.add(item);')
        ..writeln('        ObjectBoxStore.instance.$targetBox.put(related);')
        ..writeln('      }')
        ..writeln(
            '      final desired = ${rel.name}.map((related) => related.id).toSet();')
        ..writeln('      for (final existing in item.${rel.name}.toList()) {')
        ..writeln('        if (desired.contains(existing.id)) continue;')
        ..writeln(
            '        for (final target in existing.$ownerName.toList()) {')
        ..writeln(
            '          if (target.id == item.id) existing.$ownerName.remove(target);')
        ..writeln('        }')
        ..writeln('        ObjectBoxStore.instance.$targetBox.put(existing);')
        ..writeln('      }');
    }
    buf
      ..writeln('    });')
      ..writeln('  }')
      ..writeln();
  }

  void _writeOnDelete(
    StringBuffer buf,
    EntityDef entity,
    List<EntityDef> entities,
  ) {
    buf
      ..writeln(
          '  /// One-level onDelete. Related objects are not walked further.')
      ..writeln('  void _applyOnDelete(${entity.entity} item) {');
    for (final rel in entity.relations) {
      if (rel.onDelete == null) continue;
      final targetBox = '${toCamelCase(rel.target)}Box';
      if (rel.isBacklink) {
        final owner = _owningRelation(entities, rel);
        final ownerName = owner?.name ?? rel.backlink!;
        final ownerIsToOne = owner == null || owner.type == 'ToOne';
        buf.writeln('    for (final related in item.${rel.name}.toList()) {');
        if (rel.onDelete == 'cascade') {
          buf.writeln(
              '      ObjectBoxStore.instance.$targetBox.remove(related.id);');
        } else if (ownerIsToOne) {
          buf
            ..writeln('      related.$ownerName.targetId = 0;')
            ..writeln('      ObjectBoxStore.instance.$targetBox.put(related);');
        } else {
          buf
            ..writeln(
                '      for (final target in related.$ownerName.toList()) {')
            ..writeln(
                '        if (target.id == item.id) related.$ownerName.remove(target);')
            ..writeln('      }')
            ..writeln('      ObjectBoxStore.instance.$targetBox.put(related);');
        }
        buf.writeln('    }');
      } else if (rel.type == 'ToOne') {
        buf
          ..writeln('    final ${rel.name}Id = item.${rel.name}.targetId;')
          ..writeln('    if (${rel.name}Id != 0) {')
          ..writeln(
              '      ObjectBoxStore.instance.$targetBox.remove(${rel.name}Id);')
          ..writeln('    }');
      } else if (rel.onDelete == 'cascade') {
        buf
          ..writeln('    for (final related in item.${rel.name}.toList()) {')
          ..writeln(
              '      ObjectBoxStore.instance.$targetBox.remove(related.id);')
          ..writeln('    }');
      } else {
        buf
          ..writeln('    for (final related in item.${rel.name}.toList()) {')
          ..writeln('      item.${rel.name}.remove(related);')
          ..writeln('    }')
          ..writeln('    _box.put(item);');
      }
    }
    buf
      ..writeln('  }')
      ..writeln();
  }

  void _writeImportLinker(StringBuffer buf, EntityDef entity) {
    final idField = entity.fields.cast<FieldDef?>().firstWhere(
          (field) => field?.isId ?? false,
          orElse: () => null,
        );
    final idName = idField?.name ?? 'id';
    final boxName = '${toCamelCase(entity.entity)}Box';
    final toMany = entity.relations
        .where((rel) => !rel.isBacklink && rel.type == 'ToMany')
        .toList();
    buf
      ..writeln(
          '  void _link${entity.entity}(List<Map<String, dynamic>> rows) {')
      ..writeln('    for (final row in rows) {')
      ..writeln("      final id = (row['$idName'] as num?)?.toInt() ?? 0;");
    if (toMany.isNotEmpty) {
      final checks = toMany
          .map(
            (rel) =>
                "(row['${rel.name}Ids'] is List && (row['${rel.name}Ids'] as List).isNotEmpty)",
          )
          .join(' || ');
      buf
        ..writeln('      if (id == 0) {')
        ..writeln('        if ($checks) {')
        ..writeln(
            "          throw StateError('Import ${entity.entity} needs a positive id to restore ToMany relations.');")
        ..writeln('        }')
        ..writeln('        continue;')
        ..writeln('      }');
    }
    buf
      ..writeln('      final item = _store.$boxName.get(id);')
      ..writeln('      if (item == null) {')
      ..writeln(
          "        throw StateError('Import ${entity.entity} id \$id was not stored.');")
      ..writeln('      }');
    for (final rel in toMany) {
      final targetBox = '${toCamelCase(rel.target)}Box';
      buf
        ..writeln("      final ${rel.name}Ids = row['${rel.name}Ids'];")
        ..writeln('      if (${rel.name}Ids is List) {')
        ..writeln('        for (final rawId in ${rel.name}Ids) {')
        ..writeln('          final targetId = (rawId as num).toInt();')
        ..writeln('          final target = _store.$targetBox.get(targetId);')
        ..writeln('          if (target == null) {')
        ..writeln(
            "            throw StateError('Import ${entity.entity}.${rel.name}: id \$targetId was not found.');")
        ..writeln('          }')
        ..writeln('          item.${rel.name}.add(target);')
        ..writeln('        }')
        ..writeln('      }');
    }
    buf
      ..writeln('      _store.$boxName.put(item);')
      ..writeln('    }')
      ..writeln('  }')
      ..writeln();
  }

  RelationDef? _owningRelation(List<EntityDef> entities, RelationDef relation) {
    final backlink = relation.backlink;
    if (backlink == null) return null;
    for (final entity in entities) {
      if (entity.entity != relation.target) continue;
      for (final candidate in entity.relations) {
        if (candidate.name == backlink) return candidate;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Generate table operations (create/drop/clear)
  // ---------------------------------------------------------------------------

  String generateTableOperations(EntityDef entity, String operation) {
    final snake = toSnakeCase(entity.entity);
    final boxName = '${toCamelCase(entity.entity)}Box';

    return switch (operation) {
      'create' => """// Table operation: CREATE ${entity.table}
// Run: dart run build_runner build
//
// The @Entity() annotation in models/${snake}_model.dart will be
// picked up by objectbox_generator automatically.
//
// Steps:
// 1. Run: dart run build_runner build
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
// 4. Run: dart run build_runner build
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
      buf
        ..writeln(
            '  if (!getIt.isRegistered<${entity.entity}StorageHelper>()) {')
        ..writeln(
            '    getIt.registerFactory(() => ${entity.entity}StorageHelper());')
        ..writeln('  }');
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
      ..writeln("import 'package:objectbox/objectbox.dart';")
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
      ..writeln('  ///')
      ..writeln(
          '  /// Every box in the file is cleared before any object is inserted,')
      ..writeln('  /// then objects are inserted with their original id before')
      ..writeln(
          '  /// relations are applied, so file order does not matter. A ToOne')
      ..writeln('  /// id of null or 0 clears that relation. A')
      ..writeln(
          '  /// non-zero ToOne id is stored even when the target object is')
      ..writeln(
          '  /// missing. A ToMany id that is not in the box after the insert')
      ..writeln('  /// pass throws and rolls the whole import back.')
      ..writeln('  Future<void> import(String filePath) async {')
      ..writeln('    final file = File(filePath);')
      ..writeln(
          '    if (!file.existsSync()) throw Exception(\'File not found: \$filePath\');')
      ..writeln(
          '    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;')
      ..writeln('    _store.store.runInTransaction(TxMode.write, () {')
      ..writeln(
          '      final pending = <String, List<Map<String, dynamic>>>{};');

    // Clear every participating box before inserts. Deleting a relation
    // target after the source was written drops the stored ToOne id.
    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf
        ..writeln('      if (data.containsKey(\'${entity.entity}\')) {')
        ..writeln('        _store.$boxName.removeAll();')
        ..writeln('      }');
    }
    for (final entity in entities) {
      final boxName = '${toCamelCase(entity.entity)}Box';
      buf
        ..writeln('      if (data.containsKey(\'${entity.entity}\')) {')
        ..writeln('        final rows = (data[\'${entity.entity}\'] as List)')
        ..writeln(
            '            .map((e) => Map<String, dynamic>.from(e as Map))')
        ..writeln('            .toList();')
        ..writeln("        pending['${entity.entity}'] = rows;")
        ..writeln(
            '        _store.$boxName.putMany(rows.map(${entity.entity}.fromJson).toList());')
        ..writeln('      }');
    }

    for (final entity in entities) {
      if (!entity.relations
          .any((rel) => !rel.isBacklink && rel.type == 'ToMany')) {
        continue;
      }
      buf.writeln(
        "      _link${entity.entity}(pending['${entity.entity}'] ?? <Map<String, dynamic>>[]);",
      );
    }

    buf
      ..writeln('    });')
      ..writeln('  }')
      ..writeln();

    for (final entity in entities) {
      if (entity.relations
          .any((rel) => !rel.isBacklink && rel.type == 'ToMany')) {
        _writeImportLinker(buf, entity);
      }
    }

    buf

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
      ..writeln('  /// Size in bytes of the main ObjectBox database file.')
      ..writeln('  ///')
      ..writeln('  /// Returns 0 when the file is missing or cannot be read.')
      ..writeln('  int getDatabaseSize() =>')
      ..writeln('      Store.dbFileSize(_store.store.directoryPath);')
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
        .listSync(recursive: false)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.json'))
        .map((f) => f.path)
        .toList()
      ..sort();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static const _unindexableTypes = {
    'double',
    'List<String>',
    'Map<String, dynamic>',
  };

  String? _schemaTypeToDartType(String type) {
    return switch (type.toLowerCase()) {
      'string' || 'str' || 'text' => 'String',
      'int' || 'integer' => 'int',
      'double' || 'float' || 'number' => 'double',
      'bool' || 'boolean' => 'bool',
      'datetime' || 'date' => 'DateTime',
      'list' || 'array' => 'List<String>',
      'map' || 'object' => 'Map<String, dynamic>',
      _ => null,
    };
  }

  String? _canonicalRelationType(String type) {
    return switch (type.toLowerCase()) {
      'toone' => 'ToOne',
      'tomany' => 'ToMany',
      _ => null,
    };
  }

  bool _isDartIdentifier(String name) {
    return RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name) &&
        !_dartReserved.contains(name);
  }

  String _equalsCondition(EntityDef entity, FieldDef field) {
    final property = '${entity.entity}_.${field.name}';
    final value = field.name;
    if (field.dartType == 'DateTime') {
      return '$property.equalsDate($value)';
    }
    return '$property.equals($value)';
  }

  String _fromJsonExpr(FieldDef field) {
    final key = field.name;
    if (field.isNullable) {
      return switch (field.dartType) {
        'String' => "json['$key'] as String?",
        'int' => "(json['$key'] as num?)?.toInt()",
        'double' => "(json['$key'] as num?)?.toDouble()",
        'bool' => "json['$key'] as bool?",
        'DateTime' =>
          "json['$key'] != null ? DateTime.parse(json['$key'] as String) : null",
        'List<String>' =>
          "(json['$key'] as List?)?.map((e) => e as String).toList()",
        'Map<String, dynamic>' =>
          "json['$key'] == null ? null : Map<String, dynamic>.from(json['$key'] as Map)",
        _ => "json['$key'] as String?",
      };
    }
    return switch (field.dartType) {
      'String' => "json['$key'] as String? ?? ''",
      'int' => "(json['$key'] as num?)?.toInt() ?? 0",
      'double' => "(json['$key'] as num?)?.toDouble() ?? 0.0",
      'bool' => "json['$key'] as bool? ?? false",
      'DateTime' =>
        "json['$key'] != null ? DateTime.parse(json['$key'] as String) : DateTime.now()",
      'List<String>' =>
        "(json['$key'] as List?)?.map((e) => e as String).toList() ?? []",
      'Map<String, dynamic>' => "(json['$key'] as Map<String, dynamic>?) ?? {}",
      _ => "json['$key'] as String? ?? ''",
    };
  }

  static const _invalidToken = '\u0000';

  String? _parseBacklink(
    String jsonPath,
    String relName,
    String relType,
    Map<String, dynamic> relMap,
    List<String> errors,
  ) {
    if (!relMap.containsKey('backlink')) return null;
    final raw = relMap['backlink'];
    if (raw is! String || raw.trim().isEmpty) {
      errors.add(
        '$jsonPath: relasi "$relName" punya "backlink" yang kosong atau bukan string.',
      );
      return _invalidToken;
    }
    if (!_isDartIdentifier(raw)) {
      errors.add(
        '$jsonPath: nama backlink "$raw" pada relasi "$relName" tidak valid.',
      );
      return _invalidToken;
    }
    if (relType != 'ToMany') {
      errors.add(
        '$jsonPath: relasi "$relName" bertipe ToOne tidak boleh punya "backlink". '
        'Backlink hanya untuk ToMany.',
      );
      return _invalidToken;
    }
    return raw;
  }

  String? _parseOnDelete(
    String jsonPath,
    String relName,
    String relType,
    Map<String, dynamic> relMap,
    List<String> errors,
  ) {
    if (!relMap.containsKey('onDelete')) return null;
    final raw = relMap['onDelete'];
    if (raw is! String) {
      errors.add(
        '$jsonPath: onDelete pada relasi "$relName" harus berupa string.',
      );
      return _invalidToken;
    }
    final canonical = switch (raw.toLowerCase()) {
      'cascade' => 'cascade',
      'nullify' => 'nullify',
      _ => null,
    };
    if (canonical == null) {
      errors.add(
        '$jsonPath: relasi "$relName" memakai onDelete "$raw". '
        'Gunakan cascade atau nullify.',
      );
      return _invalidToken;
    }
    if (canonical == 'nullify' && relType == 'ToOne') {
      errors.add(
        '$jsonPath: onDelete nullify tidak berlaku untuk relasi ToOne "$relName". '
        'Hapus onDelete, atau gunakan cascade untuk menghapus target.',
      );
      return _invalidToken;
    }
    return canonical;
  }

  String _plural(String name) {
    if (name.endsWith('s') ||
        name.endsWith('x') ||
        name.endsWith('ch') ||
        name.endsWith('sh')) {
      return '${name}es';
    }
    if (name.endsWith('y') &&
        name.length > 1 &&
        !'aeiou'.contains(name[name.length - 2].toLowerCase())) {
      return '${name.substring(0, name.length - 1)}ies';
    }
    return '${name}s';
  }

  String _singular(String name) {
    if (name.endsWith('ies') && name.length > 3) {
      return '${name.substring(0, name.length - 3)}y';
    }
    if (name.endsWith('ches') ||
        name.endsWith('shes') ||
        name.endsWith('xes') ||
        name.endsWith('ses')) {
      return name.substring(0, name.length - 2);
    }
    if (name.endsWith('s') && !name.endsWith('ss') && name.length > 1) {
      return name.substring(0, name.length - 1);
    }
    return name;
  }

  String _toJsonCast(String dartType, bool isNullable) {
    return switch (dartType) {
      'DateTime' => isNullable ? '?.toIso8601String()' : '.toIso8601String()',
      _ => '',
    };
  }
}
