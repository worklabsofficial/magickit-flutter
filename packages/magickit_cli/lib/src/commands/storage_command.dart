import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

import '../generators/storage_generator.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';

class StorageCommand extends Command<void> {
  @override
  String get name => 'storage';

  @override
  String get description =>
      'Manage ObjectBox local storage — init, generate models, database info.\n\n'
      'Usage:\n'
      '  magickit storage init                      # Setup ObjectBox in project\n'
      '  magickit storage generate                    # Generate all entities from storage/ folder\n'
      '  magickit storage info                        # Show database info and path\n\n'
      'Define entities as JSON files in storage/ folder.';

  StorageCommand() {
    addSubcommand(StorageInitCommand());
    addSubcommand(StorageGenerateCommand(this));
    addSubcommand(StorageInfoCommand(this));
  }

  @override
  Future<void> run() async {
    final log = Logger();
    log.info('');
    log.info('${white.wrap('Usage:')} magickit storage <subcommand>');
    log.info('');
    log.info('${lightYellow.wrap('Available subcommands:')}');
    log.info('  ${cyan.wrap('init'.padRight(12))}  Setup ObjectBox in project');
    log.info(
        '  ${cyan.wrap('generate'.padRight(12))}  Generate all entities from storage/');
    log.info(
        '  ${cyan.wrap('info'.padRight(12))}  Show database info and path');
    log.info('');
    log.info(
        '${darkGray.wrap('Run "magickit storage <subcommand> --help" for more information.')}');
    log.info('');
  }

  String readAppName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return 'app';
    try {
      final yaml = loadYaml(pubspec.readAsStringSync());
      final name = yaml is YamlMap ? yaml['name']?.toString() : null;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
    return 'app';
  }
}

// ---------------------------------------------------------------------------
// Subcommand: storage init
// ---------------------------------------------------------------------------

class StorageInitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Setup ObjectBox: inject dependencies, create store, base helper.';

  @override
  Future<void> run() async {
    final storeFile = File('lib/core/storage/objectbox/objectbox_store.dart');
    if (storeFile.existsSync()) {
      logger.warn('ObjectBox storage sudah diinisialisasi.');
      logger.info(
          'Buat file JSON di storage/ lalu jalankan: magickit storage generate');
      return;
    }

    final appName = _readAppName();
    final generator = StorageGenerator(appName: appName);

    // 1. Inject ObjectBox deps to pubspec.yaml
    _injectObjectBoxDeps();

    // 2. Create storage directory
    _createDir('lib/core/storage/objectbox');
    _createDir('lib/core/storage/objectbox/models');
    _createDir('lib/core/storage/objectbox/helpers');
    _createDir('storage');
    logger.success('Folder storage/ berhasil dibuat');

    // 3. Generate ObjectBox Store (empty, will be updated when entities added)
    final storeContent = generator.generateObjectBoxStore([]);
    _writeFile(
        'lib/core/storage/objectbox/objectbox_store.dart', storeContent, true);
    logger.success(
        'lib/core/storage/objectbox/objectbox_store.dart berhasil dibuat');

    // 4. Generate storage injector (empty, will be updated when entities added)
    final injectorContent = generator.generateStorageInjector([]);
    _writeFile('lib/core/storage/objectbox/storage_injector.dart',
        injectorContent, true);
    logger.success(
        'lib/core/storage/objectbox/storage_injector.dart berhasil dibuat');

    // 5. Generate database manager (empty, will be updated when entities added)
    _writeFile('lib/core/storage/objectbox/database_manager.dart',
        generator.generateDatabaseManager([]), true);
    logger.success(
        'lib/core/storage/objectbox/database_manager.dart berhasil dibuat');

    // 7. Create example entity schema
    _createFile('storage/example_entity.json', _exampleEntityJson);
    logger.success('storage/example_entity.json template berhasil dibuat');

    // 8. Generate example entity model + helper so build_runner has something to process
    final exampleEntity =
        generator.parseEntitySchema('storage/example_entity.json');
    final modelPath =
        'lib/core/storage/objectbox/models/example_entity_model.dart';
    _writeFile(modelPath, generator.generateEntityModel(exampleEntity), true);
    logger.success('Generated: $modelPath');

    final helperPath =
        'lib/core/storage/objectbox/helpers/example_entity_storage_helper.dart';
    _writeFile(
        helperPath, generator.generateEntityStorageHelper(exampleEntity), true);
    logger.success('Generated: $helperPath');

    // Update store with example entity
    _writeFile('lib/core/storage/objectbox/objectbox_store.dart',
        generator.generateObjectBoxStore([exampleEntity]), true);

    // Update storage injector with example entity
    _writeFile('lib/core/storage/objectbox/storage_injector.dart',
        generator.generateStorageInjector([exampleEntity]), true);

    // Update database manager with example entity
    _writeFile('lib/core/storage/objectbox/database_manager.dart',
        generator.generateDatabaseManager([exampleEntity]), true);

    // 9. Update main injector
    _updateMainInjectorForStorage(appName);

    // 10. Run flutter pub get
    logger.info('');
    final pubGetProgress = logger.magicProgress('Running flutter pub get');
    final pubGetResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      runInShell: true,
    );
    if (pubGetResult.exitCode == 0) {
      pubGetProgress.complete('flutter pub get completed');
    } else {
      pubGetProgress.fail('flutter pub get failed');
      logger.err(pubGetResult.stderr.toString());
      exit(1);
    }

    // 11. Run build_runner to generate objectbox.g.dart
    logger.info('');
    final buildProgress = logger.magicProgress('Running build_runner');
    final buildResult = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      runInShell: true,
    );
    if (buildResult.exitCode == 0) {
      buildProgress.complete('build_runner completed');
    } else {
      buildProgress.fail('build_runner failed');
      logger.err(buildResult.stderr.toString());
    }

    logger.info('');
    logger.success('ObjectBox storage berhasil diinisialisasi!');
    logger.info('');
  }

  void _injectObjectBoxDeps() {
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      logger.warn('pubspec.yaml tidak ditemukan, skip dependency injection.');
      return;
    }

    var content = pubspecFile.readAsStringSync();
    final existingDeps = <String>{};
    final existingDevDeps = <String>{};
    try {
      final yaml = loadYaml(content) as YamlMap?;
      final deps = yaml?['dependencies'];
      if (deps is YamlMap) {
        existingDeps.addAll(deps.keys.map((k) => k.toString()));
      }
      final devDeps = yaml?['dev_dependencies'];
      if (devDeps is YamlMap) {
        existingDevDeps.addAll(devDeps.keys.map((k) => k.toString()));
      }
    } catch (_) {}

    final depsToAdd = <String>[];
    if (!existingDeps.contains('objectbox')) {
      depsToAdd.add('  objectbox: ^5.3.1');
    }
    if (!existingDeps.contains('objectbox_flutter_libs')) {
      depsToAdd.add('  objectbox_flutter_libs: any');
    }
    if (!existingDeps.contains('get_it')) {
      depsToAdd.add('  get_it: ^8.0.0');
    }

    final devDepsToAdd = <String>[];
    if (!existingDevDeps.contains('build_runner')) {
      devDepsToAdd.add('  build_runner: ^2.4.11');
    }
    if (!existingDevDeps.contains('objectbox_generator')) {
      devDepsToAdd.add('  objectbox_generator: any');
    }

    if (depsToAdd.isEmpty && devDepsToAdd.isEmpty) {
      logger.info('pubspec.yaml: ObjectBox dependencies sudah lengkap');
      return;
    }

    // Insert dependencies
    if (depsToAdd.isNotEmpty) {
      final depsMarker = 'dependencies:';
      final depsIdx = content.indexOf(depsMarker);
      if (depsIdx != -1) {
        final insertIdx = content.indexOf('\n', depsIdx) + 1;
        content =
            '${content.substring(0, insertIdx)}${depsToAdd.join('\n')}\n${content.substring(insertIdx)}';
      }
    }

    // Insert dev_dependencies
    if (devDepsToAdd.isNotEmpty) {
      final devDepsMarker = 'dev_dependencies:';
      final devDepsIdx = content.indexOf(devDepsMarker);
      if (devDepsIdx != -1) {
        final insertIdx = content.indexOf('\n', devDepsIdx) + 1;
        content =
            '${content.substring(0, insertIdx)}${devDepsToAdd.join('\n')}\n${content.substring(insertIdx)}';
      } else {
        content += '\ndev_dependencies:\n${devDepsToAdd.join('\n')}\n';
      }
    }

    pubspecFile.writeAsStringSync(content);
    logger.success('pubspec.yaml: ObjectBox dependencies berhasil ditambahkan');
    for (final dep in [...depsToAdd, ...devDepsToAdd]) {
      logger.info('  + ${dep.trim().split(':').first}');
    }
  }

  String _readAppName() {
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) return 'app';
    try {
      final yaml = loadYaml(pubspec.readAsStringSync());
      final name = yaml is YamlMap ? yaml['name']?.toString() : null;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
    return 'app';
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

  void _writeFile(String path, String content, bool overwrite) {
    final file = File(path);
    if (!file.existsSync() || overwrite) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }
  }

  void _updateMainInjectorForStorage(String appName) {
    final injectorFile = File('lib/core/dependency_injection/injector.dart');
    if (!injectorFile.existsSync()) return;

    var content = injectorFile.readAsStringSync();
    final importLine =
        "import 'package:$appName/core/storage/objectbox/storage_injector.dart';";

    if (!content.contains(importLine) &&
        content.contains('// MAGICKIT:IMPORT')) {
      content = content.replaceFirst(
        '// MAGICKIT:IMPORT',
        '$importLine\n// MAGICKIT:IMPORT',
      );
    }

    if (!content.contains('await storageInjector();') &&
        content.contains('// MAGICKIT:INJECTOR')) {
      content = content.replaceFirst(
        '// MAGICKIT:INJECTOR',
        '  await storageInjector();\n  // MAGICKIT:INJECTOR',
      );
    }

    injectorFile.writeAsStringSync(content);
  }

  static const _exampleEntityJson = '''{
  "entity": "ExampleEntity",
  "table": "example_entities",
  "fields": [
    { "name": "id", "type": "int", "id": true },
    { "name": "name", "type": "String" },
    { "name": "description", "type": "String", "nullable": true },
    { "name": "createdAt", "type": "DateTime" },
    { "name": "isActive", "type": "bool" }
  ],
  "indexes": ["name"],
  "relations": []
}
''';
}

// ---------------------------------------------------------------------------
// Subcommand: storage info
// ---------------------------------------------------------------------------

class StorageInfoCommand extends Command<void> {
  final StorageCommand _parent;

  StorageInfoCommand(this._parent);

  @override
  String get name => 'info';

  @override
  String get description =>
      'Show ObjectBox database info: path, entities, file size.\n\n'
      'Usage:\n'
      '  magickit storage info';

  @override
  Future<void> run() async {
    final appName = _parent.readAppName();
    final generator = StorageGenerator(appName: appName);

    // Find all entity schemas
    final schemaFiles = generator.findEntityFiles('storage');

    logger.info('');
    logger.info('${lightYellow.wrap('ObjectBox Database Info')}');
    logger.info('');

    // Database path
    logger.info('${cyan.wrap('Database path:')}');
    logger.info('  Android: /data/data/$appName/app_objectbox/');
    logger.info('  iOS:     Library/Application Support/objectbox/');
    logger.info('  macOS:   ~/Library/Application Support/$appName/objectbox/');
    logger.info('  Linux:   ~/.local/share/$appName/objectbox/');
    logger.info('');

    // Custom path example
    logger.info('${cyan.wrap('Custom path example:')}');
    logger.info('  await ObjectBoxStore.create(directory: "my_custom_path");');
    logger.info('');

    // Entities
    if (schemaFiles.isEmpty) {
      logger.warn('No entity schemas found in storage/');
      logger.info(
          'Create JSON files in storage/ and run: magickit storage generate');
    } else {
      logger.info('${cyan.wrap('Entities (${schemaFiles.length}):')}');
      for (final file in schemaFiles) {
        try {
          final entity = generator.parseEntitySchema(file);
          final fieldCount = entity.fields.length;
          final relCount = entity.relations.length;
          logger.info(
              '  ${green.wrap('●')} ${entity.entity} ($fieldCount fields${relCount > 0 ? ', $relCount relations' : ''})');
          for (final field in entity.fields) {
            final type =
                field.isNullable ? '${field.dartType}?' : field.dartType;
            final flags = [
              if (field.isId) 'id',
              if (field.isUnique) 'unique',
              if (entity.indexes.contains(field.name)) 'index',
            ].join(', ');
            logger.info(
                '      ${darkGray.wrap('- ${field.name}: $type')} ${flags.isNotEmpty ? darkGray.wrap('[$flags]') : ''}');
          }
        } catch (e) {
          logger.warn('  ! ${file.split('/').last}: $e');
        }
      }
    }

    logger.info('');

    // Generated files
    logger.info('${cyan.wrap('Generated files:')}');
    final generatedFiles = [
      'lib/core/storage/objectbox/objectbox_store.dart',
      'lib/core/storage/objectbox/storage_injector.dart',
      'lib/objectbox.g.dart',
    ];
    for (final f in generatedFiles) {
      final exists = File(f).existsSync();
      final size = exists ? File(f).lengthSync() : 0;
      final sizeStr = exists ? '(${_formatBytes(size)})' : '';
      logger.info('  ${exists ? green.wrap('✓') : red.wrap('✗')} $f $sizeStr');
    }

    final modelsDir = Directory('lib/core/storage/objectbox/models');
    if (modelsDir.existsSync()) {
      final modelFiles = modelsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in modelFiles) {
        final size = f.lengthSync();
        logger.info('  ${green.wrap('✓')} ${f.path} (${_formatBytes(size)})');
      }
    }

    final helpersDir = Directory('lib/core/storage/objectbox/helpers');
    if (helpersDir.existsSync()) {
      final helperFiles = helpersDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in helperFiles) {
        final size = f.lengthSync();
        logger.info('  ${green.wrap('✓')} ${f.path} (${_formatBytes(size)})');
      }
    }

    logger.info('');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ---------------------------------------------------------------------------
// Subcommand: storage generate
// ---------------------------------------------------------------------------

class StorageGenerateCommand extends Command<void> {
  final StorageCommand _parent;

  StorageGenerateCommand(this._parent) {
    argParser
      ..addFlag(
        'force',
        help: 'Overwrite existing generated files.',
        defaultsTo: false,
        negatable: false,
      )
      ..addFlag(
        'build-runner',
        help: 'Run build_runner after generating files.',
        defaultsTo: false,
        negatable: false,
      );
  }

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Generate all entity models, helpers, and store from storage/ folder.\n\n'
      'Usage:\n'
      '  magickit storage generate              # Generate all entities\n'
      '  magickit storage generate --force      # Overwrite existing files\n'
      '  magickit storage generate --build-runner  # Also run build_runner';

  @override
  Future<void> run() async {
    final force = argResults?['force'] as bool? ?? false;
    final runBuildRunner = argResults?['build-runner'] as bool? ?? false;
    final appName = _parent.readAppName();
    final generator = StorageGenerator(appName: appName);

    // Find all schema files
    final schemaFiles = generator.findEntityFiles('storage');
    if (schemaFiles.isEmpty) {
      logger.warn(
        'Tidak ada entity schema ditemukan di storage/.\n'
        'Buat file JSON di storage/ lalu jalankan ulang.\n\n'
        'Contoh: storage/user.json',
      );
      return;
    }

    logger.info('Ditemukan ${schemaFiles.length} entity schema file(s).');

    // Parse all entities
    final entities = <EntityDef>[];
    for (final file in schemaFiles) {
      final progress = logger.magicProgress('Parsing $file');
      try {
        final entity = generator.parseEntitySchema(file);
        entities.add(entity);
        progress.complete('Parsed: ${entity.entity}');
      } catch (e) {
        progress.fail('Gagal parse $file: $e');
      }
    }

    if (entities.isEmpty) {
      logger.err('Tidak ada entity yang berhasil diparse.');
      exit(1);
    }

    // Ensure directories exist
    Directory('lib/core/storage/objectbox/models').createSync(recursive: true);
    Directory('lib/core/storage/objectbox/helpers').createSync(recursive: true);

    var totalGenerated = 0;

    // Generate entity models + helpers
    for (final entity in entities) {
      final snake = toSnakeCase(entity.entity);

      // Model
      final modelPath = 'lib/core/storage/objectbox/models/${snake}_model.dart';
      _writeFile(modelPath, generator.generateEntityModel(entity), force);
      logger.success('Generated: $modelPath');
      totalGenerated++;

      // Helper
      final helperPath =
          'lib/core/storage/objectbox/helpers/${snake}_storage_helper.dart';
      _writeFile(
          helperPath, generator.generateEntityStorageHelper(entity), force);
      logger.success('Generated: $helperPath');
      totalGenerated++;
    }

    // Generate/update ObjectBox Store
    final storePath = 'lib/core/storage/objectbox/objectbox_store.dart';
    _writeFile(storePath, generator.generateObjectBoxStore(entities), true);
    logger.success('Updated: $storePath');
    totalGenerated++;

    // Generate/update storage injector (single file for all entities)
    final storageInjectorPath =
        'lib/core/storage/objectbox/storage_injector.dart';
    _writeFile(
        storageInjectorPath, generator.generateStorageInjector(entities), true);
    logger.success('Updated: $storageInjectorPath');
    totalGenerated++;

    // Generate/update database manager
    final dbManagerPath = 'lib/core/storage/objectbox/database_manager.dart';
    _writeFile(
        dbManagerPath, generator.generateDatabaseManager(entities), true);
    logger.success('Updated: $dbManagerPath');
    totalGenerated++;

    // Update main injector to import storage_injector.dart
    _ensureMainInjectorHasStorageImport(appName);

    logger.info('');
    logger.success('$totalGenerated file(s) generated.');
    logger.info('');

    // Run build_runner if requested
    if (runBuildRunner) {
      logger.info('');
      final progress = logger.magicProgress('Running build_runner');
      try {
        final result = await Process.run(
          'dart',
          ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
          runInShell: true,
        );
        if (result.exitCode == 0) {
          progress.complete('build_runner completed');
        } else {
          progress.fail('build_runner failed');
          logger.err(result.stderr.toString());
        }
      } catch (e) {
        progress.fail('build_runner error: $e');
      }
    }
  }

  void _ensureMainInjectorHasStorageImport(String appName) {
    final injectorFile = File('lib/core/dependency_injection/injector.dart');
    if (!injectorFile.existsSync()) return;

    var content = injectorFile.readAsStringSync();
    final importLine =
        "import 'package:$appName/core/storage/objectbox/storage_injector.dart';";

    if (!content.contains(importLine) &&
        content.contains('// MAGICKIT:IMPORT')) {
      content = content.replaceFirst(
        '// MAGICKIT:IMPORT',
        '$importLine\n// MAGICKIT:IMPORT',
      );
    }

    if (!content.contains('await storageInjector();') &&
        content.contains('// MAGICKIT:INJECTOR')) {
      content = content.replaceFirst(
        '// MAGICKIT:INJECTOR',
        '  await storageInjector();\n  // MAGICKIT:INJECTOR',
      );
    }

    injectorFile.writeAsStringSync(content);
  }

  void _writeFile(String path, String content, bool overwrite) {
    final file = File(path);
    if (!file.existsSync() || overwrite) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }
  }
}
