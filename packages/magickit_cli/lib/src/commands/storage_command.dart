import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

import '../generators/storage_generator.dart';
import '../utils/build_runner_args.dart';
import '../utils/generated_sources.dart';
import '../utils/logger.dart';
import '../utils/startup_wiring.dart';
import '../utils/string_utils.dart';

class StorageCommand extends Command<void> {
  @override
  String get name => 'storage';

  @override
  String get description =>
      'Manage ObjectBox local storage for Android and iOS.\n\n'
      'ObjectBox storage supports Android and iOS only.\n\n'
      'Usage:\n'
      '  magickit storage init                      # Setup ObjectBox in project\n'
      '  magickit storage generate                    # Generate all entities from storage/ folder\n'
      '  magickit storage info                        # Show entities and generated files\n\n'
      'Define entities as JSON files directly in storage/.';

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
    log.info(
        '  ${cyan.wrap('init'.padRight(12))}  Setup ObjectBox (Android/iOS)');
    log.info(
        '  ${cyan.wrap('generate'.padRight(12))}  Generate entities from storage/');
    log.info(
        '  ${cyan.wrap('info'.padRight(12))}  Show entities and generated files');
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
      'Setup ObjectBox for Android and iOS: dependencies, store, and helpers.';

  @override
  Future<void> run() async {
    final storeFile = File('lib/core/storage/objectbox/objectbox_store.dart');
    if (storeFile.existsSync()) {
      final appName = _readAppName();
      logger.warn('ObjectBox storage sudah diinisialisasi.');
      _applyStorageStartupWiring(appName);
      if (!File('lib/objectbox.g.dart').existsSync()) {
        logger.info('lib/objectbox.g.dart belum ada. Menjalankan codegen...');
        await _runPubGet();
        await _runBuildRunner();
      }
      _printStorageFollowUp(ranBuildRunner: true);
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

    // 9. Wire async startup (configureDependencies + main).
    _applyStorageStartupWiring(appName);

    // 10. Run flutter pub get, then build_runner. Failures exit non-zero.
    logger.info('');
    await _runPubGet();
    logger.info('');
    await _runBuildRunner();

    logger.info('');
    logger.success('ObjectBox storage berhasil diinisialisasi!');
    _printStorageFollowUp(ranBuildRunner: true);
    logger.info('');
  }

  Future<void> _runPubGet() {
    return _runCheckedProcess(
      'flutter',
      ['pub', 'get'],
      running: 'Menjalankan flutter pub get',
      success: 'flutter pub get selesai',
      failure: 'flutter pub get gagal',
    );
  }

  Future<void> _runBuildRunner() {
    return _runCheckedProcess(
      'dart',
      buildRunnerBuildArgs(readBuildRunnerVersion()),
      running: 'Menjalankan build_runner',
      success: 'build_runner selesai',
      failure: 'build_runner gagal',
    );
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
      'Show ObjectBox entities and generated files (Android and iOS only).\n\n'
      'Usage:\n'
      '  magickit storage info';

  @override
  Future<void> run() async {
    final appName = _parent.readAppName();
    final generator = StorageGenerator(appName: appName);

    // Find all entity schemas
    final schemaFiles = generator.findEntityFiles('storage');

    logger.info('');
    logger.info('${lightYellow.wrap('Info database ObjectBox')}');
    logger.info('');
    logger.info('${cyan.wrap('Platform:')} Android dan iOS saja.');
    logger.info('');
    logger.info('${cyan.wrap('Lokasi database:')}');
    logger.info(
        '  openStore() memakai defaultStoreDirectory() dari objectbox_flutter_libs');
    logger.info('  (direktori dokumen aplikasi + /objectbox).');
    logger
        .info('  Path di perangkat baru diketahui setelah aplikasi berjalan.');
    logger.info('');

    // Entities
    if (schemaFiles.isEmpty) {
      logger.warn('Tidak ada schema entity di storage/');
      logger.info(
          'Buat file JSON di storage/ lalu jalankan: magickit storage generate');
    } else {
      logger.info('${cyan.wrap('Entities (${schemaFiles.length}):')}');
      for (final file in schemaFiles) {
        try {
          final entity = generator.parseEntitySchema(file);
          final fieldCount = entity.fields.length;
          final relCount = entity.relations.length;
          logger.info(
              '  ${green.wrap('●')} ${entity.entity} ($fieldCount field${relCount > 0 ? ', $relCount relasi' : ''})');
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
          logger.warn('  ! ${file.split(Platform.pathSeparator).last}: $e');
        }
      }
    }

    logger.info('');

    // Generated files
    logger.info('${cyan.wrap('File generated:')}');
    final generatedFiles = [
      'lib/core/storage/objectbox/objectbox_store.dart',
      'lib/core/storage/objectbox/storage_injector.dart',
      'lib/core/storage/objectbox/database_manager.dart',
      'lib/objectbox.g.dart',
      'lib/objectbox-model.json',
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
        help:
            'Overwrite files even when they are no longer marked as generated.',
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
      'Generate entity models, helpers, and the store from storage/ (Android and iOS only).\n\n'
      'Usage:\n'
      '  magickit storage generate              # Generate all entities\n'
      '  magickit storage generate --force      # Overwrite user-owned files too\n'
      '  magickit storage generate --build-runner  # Also run build_runner';

  @override
  Future<void> run() async {
    final force = argResults?['force'] as bool? ?? false;
    final runBuildRunner = argResults?['build-runner'] as bool? ?? false;
    final appName = _parent.readAppName();
    final generator = StorageGenerator(appName: appName);

    if (!Directory('storage').existsSync()) {
      logger.warn(
        'Folder storage/ tidak ditemukan.\n'
        'Buat file JSON di storage/ lalu jalankan ulang.\n\n'
        'Contoh: storage/user.json',
      );
      return;
    }

    final List<EntityDef> entities;
    try {
      entities = generator.loadEntities('storage');
    } on StorageSchemaException catch (e) {
      logger.err('Schema storage tidak valid:');
      for (final error in e.errors) {
        logger.err('  - $error');
      }
      exit(1);
    }

    if (entities.isEmpty) {
      final changed = _syncSharedFiles(generator, entities, force: force);
      if (!changed) {
        logger.warn(
          'Tidak ada entity schema di storage/.\n'
          'Buat file JSON langsung di storage/ (bukan di subfolder).\n\n'
          'Contoh: storage/user.json',
        );
        return;
      }
      _applyStorageStartupWiring(appName);
      _printStorageFollowUp(ranBuildRunner: runBuildRunner);
      if (runBuildRunner) {
        logger.info('');
        await _runBuildRunner();
      }
      return;
    }

    logger.info('Ditemukan ${entities.length} entity.');

    const modelsDir = 'lib/core/storage/objectbox/models';
    const helpersDir = 'lib/core/storage/objectbox/helpers';
    Directory(modelsDir).createSync(recursive: true);
    Directory(helpersDir).createSync(recursive: true);

    final keepPaths = <String>[];
    var wrote = 0;
    var skipped = 0;

    for (final entity in entities) {
      final snake = toSnakeCase(entity.entity);
      final modelPath = '$modelsDir/${snake}_model.dart';
      final helperPath = '$helpersDir/${snake}_storage_helper.dart';
      keepPaths.add(modelPath);
      keepPaths.add(helperPath);

      wrote += _emit(
        modelPath,
        generator.generateEntityModel(entity),
        force: force,
      );
      if (_lastWriteSkipped) skipped++;
      wrote += _emit(
        helperPath,
        generator.generateEntityStorageHelper(entity, entities: entities),
        force: force,
      );
      if (_lastWriteSkipped) skipped++;
    }

    wrote += _emit(
      'lib/core/storage/objectbox/objectbox_store.dart',
      generator.generateObjectBoxStore(entities),
      force: force,
    );
    if (_lastWriteSkipped) skipped++;
    wrote += _emit(
      'lib/core/storage/objectbox/storage_injector.dart',
      generator.generateStorageInjector(entities),
      force: force,
    );
    if (_lastWriteSkipped) skipped++;
    wrote += _emit(
      'lib/core/storage/objectbox/database_manager.dart',
      generator.generateDatabaseManager(entities),
      force: force,
    );
    if (_lastWriteSkipped) skipped++;

    final cleanup = deleteStaleGeneratedSources(
      keepPaths: keepPaths,
      directories: const [modelsDir, helpersDir],
    );
    for (final path in cleanup.deleted) {
      logger.info('Dihapus: $path');
    }
    for (final path in cleanup.keptUserOwned) {
      logger.warn(
        'Dilewati hapus (bukan file generated, hapus manual jika entity sudah tidak dipakai): $path',
      );
    }

    _applyStorageStartupWiring(appName);

    logger.info('');
    logger.success('$wrote file ditulis, $skipped dilewati.');
    _printStorageFollowUp(ranBuildRunner: runBuildRunner);

    if (runBuildRunner) {
      logger.info('');
      await _runBuildRunner();
    }
  }

  bool _lastWriteSkipped = false;

  int _emit(String path, String content, {required bool force}) {
    final result = writeGeneratedSource(
      path: path,
      content: content,
      force: force,
    );
    switch (result) {
      case GeneratedWriteResult.created:
        logger.success('Dibuat: $path');
        _lastWriteSkipped = false;
        return 1;
      case GeneratedWriteResult.updated:
        logger.success('Diperbarui: $path');
        _lastWriteSkipped = false;
        return 1;
      case GeneratedWriteResult.unchanged:
        logger.info('Dilewati: $path');
        _lastWriteSkipped = true;
        return 0;
      case GeneratedWriteResult.skippedUserOwned:
        logger.warn(
          'Dilewati (bukan file generated, gunakan --force untuk menimpa): $path',
        );
        _lastWriteSkipped = true;
        return 0;
    }
  }

  /// Rewrite store/injector/manager when every entity JSON was removed.
  /// Returns true when something on disk changed.
  bool _syncSharedFiles(
    StorageGenerator generator,
    List<EntityDef> entities, {
    required bool force,
  }) {
    const modelsDir = 'lib/core/storage/objectbox/models';
    const helpersDir = 'lib/core/storage/objectbox/helpers';
    final cleanup = deleteStaleGeneratedSources(
      keepPaths: const [],
      directories: const [modelsDir, helpersDir],
    );
    var changed = cleanup.deleted.isNotEmpty;
    for (final path in cleanup.deleted) {
      logger.info('Dihapus: $path');
    }
    for (final path in cleanup.keptUserOwned) {
      logger.warn(
        'Dilewati hapus (bukan file generated, hapus manual jika entity sudah tidak dipakai): $path',
      );
    }

    final shared = <String, String>{
      'lib/core/storage/objectbox/objectbox_store.dart':
          generator.generateObjectBoxStore(entities),
      'lib/core/storage/objectbox/storage_injector.dart':
          generator.generateStorageInjector(entities),
      'lib/core/storage/objectbox/database_manager.dart':
          generator.generateDatabaseManager(entities),
    };
    for (final entry in shared.entries) {
      if (!File(entry.key).existsSync() && entities.isEmpty) continue;
      final wrote = _emit(entry.key, entry.value, force: force);
      if (wrote > 0) changed = true;
    }
    return changed;
  }

  Future<void> _runBuildRunner() {
    return _runCheckedProcess(
      'dart',
      buildRunnerBuildArgs(readBuildRunnerVersion()),
      running: 'Menjalankan build_runner',
      success: 'build_runner selesai',
      failure: 'build_runner gagal',
    );
  }
}

void _printStorageFollowUp({required bool ranBuildRunner}) {
  logger.info('');
  logger.info('Selanjutnya:');
  if (!ranBuildRunner) {
    logger.info('  - Jalankan: dart run build_runner build');
  }
  logger.info(
    '  - Commit lib/objectbox-model.json ke version control setelah codegen.',
  );
  logger.info('  - ObjectBox storage hanya mendukung Android dan iOS.');
}

Future<void> _runCheckedProcess(
  String executable,
  List<String> args, {
  required String running,
  required String success,
  required String failure,
}) async {
  final progress = logger.magicProgress(running);
  final result = await Process.run(executable, args, runInShell: true);
  if (result.exitCode == 0) {
    progress.complete(success);
    return;
  }
  progress.fail(failure);
  final out = result.stdout.toString().trim();
  final err = result.stderr.toString().trim();
  if (out.isNotEmpty) logger.err(out);
  if (err.isNotEmpty) logger.err(err);
  exit(1);
}

void _applyStorageStartupWiring(String appName) {
  final injectorFile = File('lib/core/dependency_injection/injector.dart');
  if (!injectorFile.existsSync()) {
    logger.info(
      'injector.dart tidak ditemukan. Panggil await storageInjector() '
      'setelah WidgetsFlutterBinding.ensureInitialized() di main.',
    );
  } else {
    final original = injectorFile.readAsStringSync();
    var updated = makeConfigureDependenciesAsync(original);
    final hasMarkers = updated.contains('// MAGICKIT:IMPORT') &&
        updated.contains('// MAGICKIT:INJECTOR');
    if (!hasMarkers && !updated.contains('storageInjector()')) {
      logger.warn(
        'injector.dart tidak memiliki marker MAGICKIT. '
        'storageInjector() tidak ditambahkan otomatis.',
      );
    } else {
      updated = ensureStorageInjectorHook(updated, appName);
    }
    if (updated != original) {
      injectorFile.writeAsStringSync(updated);
      logger.success('injector.dart diperbarui untuk startup storage.');
    }
  }

  final mainFile = File('lib/main.dart');
  if (!mainFile.existsSync()) return;
  final mainOriginal = mainFile.readAsStringSync();
  final mainUpdated = makeMainAwaitConfigureDependencies(mainOriginal);
  if (mainUpdated != mainOriginal) {
    mainFile.writeAsStringSync(mainUpdated);
    logger.success('lib/main.dart menunggu configureDependencies().');
  }
}
