import 'dart:io';

import 'package:magickit_cli/src/generators/storage_generator.dart';
import 'package:magickit_cli/src/utils/build_runner_args.dart';
import 'package:magickit_cli/src/utils/generated_sources.dart';
import 'package:magickit_cli/src/utils/startup_wiring.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('magickit_storage_test_');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  StorageGenerator generator() => StorageGenerator(appName: 'sample_app');

  String writeJson(String relativePath, String contents) {
    final file = File(p.join(temp.path, relativePath));
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
    return file.path;
  }

  group('schema validation', () {
    test('rejects a double index before any model is usable', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [
    {"name": "score", "type": "double"}
  ],
  "indexes": ["score"]
}
''');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.errors.join('\n'),
            'errors',
            allOf(
              contains('index/unique tidak didukung'),
              contains('score'),
              contains('double'),
            ),
          ),
        ),
      );
    });

    test('rejects list and map indexes', () {
      writeJson('note.json', '''
{
  "entity": "Note",
  "fields": [
    {"name": "tags", "type": "list"},
    {"name": "meta", "type": "map"}
  ],
  "indexes": ["tags", "meta"]
}
''');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.errors.join('\n'),
            'errors',
            allOf(contains('List<String>'), contains('Map<String, dynamic>')),
          ),
        ),
      );
    });

    test('rejects unknown field types and reserved field names', () {
      writeJson('bad.json', '''
{
  "entity": "Item",
  "fields": [
    {"name": "default", "type": "string"},
    {"name": "token", "type": "uuid"}
  ]
}
''');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.errors.join('\n'),
            'errors',
            allOf(contains('default'), contains('uuid')),
          ),
        ),
      );
    });

    test('rejects a reserved entity name', () {
      writeJson('fn.json', '''
{
  "entity": "Function",
  "fields": [{"name": "label", "type": "string"}]
}
''');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            contains('Function'),
          ),
        ),
      );
    });

    test('rejects invalid relation types and missing targets', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "posts", "type": "HasMany", "target": "Post"},
    {"name": "profile", "target": "Profile"}
  ]
}
''');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.errors.join('\n'),
            'errors',
            allOf(
              contains('HasMany'),
              contains('ToOne atau ToMany'),
              contains('profile'),
            ),
          ),
        ),
      );
    });

    test('rejects a relation whose target entity does not exist', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "posts", "type": "ToMany", "target": "Post"}
  ]
}
''');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            contains('Post'),
          ),
        ),
      );
    });

    test('rejects duplicate entity names', () {
      writeJson('user_a.json', '''
{"entity": "User", "fields": [{"name": "name", "type": "string"}]}
''');
      writeJson('user_b.json', '''
{"entity": "user", "fields": [{"name": "email", "type": "string"}]}
''');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            contains('didefinisikan 2 kali'),
          ),
        ),
      );
    });

    test('broken JSON exits the loader with a schema error', () {
      writeJson('broken.json', '{ this is not json');

      expect(
        () => generator().loadEntities(temp.path),
        throwsA(isA<StorageSchemaException>()),
      );
    });

    test('ignores nested JSON and still loads a valid top-level entity', () {
      writeJson('user.json', '''
{"entity": "User", "fields": [{"name": "name", "type": "string"}]}
''');
      writeJson('nested/note.json', '''
{"entity": "Note", "fields": [{"name": "body", "type": "string"}]}
''');

      final entities = generator().loadEntities(temp.path);
      expect(entities.map((e) => e.entity), ['User']);
      expect(entities.single.fields.map((f) => f.name), ['id', 'name']);
    });

    test('accepts ToOne case-insensitively when the target exists', () {
      writeJson('profile.json', '''
{"entity": "Profile", "fields": [{"name": "bio", "type": "string"}]}
''');
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [{"name": "profile", "type": "toone", "target": "profile"}]
}
''');

      final entities = generator().loadEntities(temp.path);
      final user = entities.firstWhere((e) => e.entity == 'User');
      expect(user.relations.single.type, 'ToOne');
      expect(user.relations.single.target, 'Profile');
    });
  });

  group('generation', () {
    test('DateTime indexes use equalsDate and strings still use equals', () {
      final entity = EntityDef(
        entity: 'User',
        table: 'user',
        indexes: const ['email', 'createdAt'],
        fields: const [
          FieldDef(name: 'id', dartType: 'int', isId: true),
          FieldDef(name: 'email', dartType: 'String'),
          FieldDef(name: 'createdAt', dartType: 'DateTime'),
        ],
      );

      final helper = generator().generateEntityStorageHelper(entity);
      expect(helper, contains('User_.createdAt.equalsDate(createdAt)'));
      expect(helper, isNot(contains('User_.createdAt.equals(createdAt)')));
      expect(helper, contains('User_.email.equals(email)'));
    });

    test('close clears the store singleton and registrations are guarded', () {
      final entity = EntityDef(
        entity: 'User',
        table: 'user',
        fields: const [FieldDef(name: 'id', dartType: 'int', isId: true)],
      );
      final gen = generator();

      final store = gen.generateObjectBoxStore([entity]);
      expect(store, contains('store.close();'));
      expect(store, contains('_instance = null;'));

      final injector = gen.generateStorageInjector([entity]);
      expect(
        injector,
        contains('if (!getIt.isRegistered<UserStorageHelper>())'),
      );

      final manager = gen.generateDatabaseManager([entity]);
      expect(
        manager,
        contains('Store.dbFileSize(_store.store.directoryPath)'),
      );
      expect(manager, contains("import 'package:objectbox/objectbox.dart';"));
    });
  });

  group('safe writes', () {
    test('skips user-owned files unless force is set', () {
      final path = p.join(temp.path, 'user_model.dart');
      File(path).writeAsStringSync('class User {}\n');

      expect(
        writeGeneratedSource(
          path: path,
          content: '// GENERATED CODE\nclass User {}\n',
          force: false,
        ),
        GeneratedWriteResult.skippedUserOwned,
      );
      expect(File(path).readAsStringSync(), 'class User {}\n');

      expect(
        writeGeneratedSource(
          path: path,
          content: '// GENERATED CODE\nclass User {}\n',
          force: true,
        ),
        GeneratedWriteResult.updated,
      );
      expect(File(path).readAsStringSync(), startsWith('// GENERATED CODE'));
    });

    test('reports unchanged generated files and creates missing ones', () {
      final path = p.join(temp.path, 'models', 'user_model.dart');
      const content =
          '// GENERATED CODE — DO NOT EDIT BY HAND\nclass User {}\n';

      expect(
        writeGeneratedSource(path: path, content: content, force: false),
        GeneratedWriteResult.created,
      );
      expect(
        writeGeneratedSource(path: path, content: content, force: false),
        GeneratedWriteResult.unchanged,
      );
      expect(
        writeGeneratedSource(
          path: path,
          content: '$content// again\n',
          force: false,
        ),
        GeneratedWriteResult.updated,
      );
    });

    test('deletes stale generated files and keeps user-owned leftovers', () {
      final models = Directory(p.join(temp.path, 'models'))..createSync();
      final keep = File(p.join(models.path, 'user_model.dart'))
        ..writeAsStringSync('// GENERATED CODE\nclass User {}\n');
      final stale = File(p.join(models.path, 'note_model.dart'))
        ..writeAsStringSync('// GENERATED BY MAGICKIT CLI\nclass Note {}\n');
      final owned = File(p.join(models.path, 'custom.dart'))
        ..writeAsStringSync('class Custom {}\n');

      final result = deleteStaleGeneratedSources(
        keepPaths: [keep.path],
        directories: [models.path],
      );

      expect(result.deleted, [normalizeSourcePath(stale.path)]);
      expect(result.keptUserOwned, [normalizeSourcePath(owned.path)]);
      expect(stale.existsSync(), isFalse);
      expect(keep.existsSync(), isTrue);
      expect(owned.existsSync(), isTrue);
    });
  });

  group('startup wiring', () {
    const oldInjector = '''
import 'package:get_it/get_it.dart';
// MAGICKIT:IMPORT

final getIt = GetIt.instance;

void configureDependencies() {
  // MAGICKIT:INJECTOR
}
''';

    const oldMain = '''
import 'package:flutter/material.dart';
import 'core/dependency_injection/injector.dart';

void main() {
  configureDependencies();
  runApp(const App());
}
''';

    test('upgrades sync startup and is idempotent', () {
      final wired = ensureStorageInjectorHook(
        makeConfigureDependenciesAsync(oldInjector),
        'sample_app',
      );
      final again = ensureStorageInjectorHook(
        makeConfigureDependenciesAsync(wired),
        'sample_app',
      );

      expect(wired, contains('Future<void> configureDependencies() async {'));
      expect(
        wired,
        contains(
          "import 'package:sample_app/core/storage/objectbox/storage_injector.dart';",
        ),
      );
      expect(wired, contains('await storageInjector();'));
      expect('await storageInjector();'.allMatches(wired).length, 1);
      expect(again, wired);

      final mainOnce = makeMainAwaitConfigureDependencies(oldMain);
      final mainTwice = makeMainAwaitConfigureDependencies(mainOnce);
      expect(mainOnce, contains('Future<void> main() async {'));
      expect(mainOnce, contains('WidgetsFlutterBinding.ensureInitialized();'));
      expect(mainOnce, contains('await configureDependencies();'));
      expect(
        'WidgetsFlutterBinding.ensureInitialized();'
            .allMatches(mainOnce)
            .length,
        1,
      );
      expect(mainTwice, mainOnce);
    });

    test('adds await to an existing storageInjector call', () {
      const content = '''
void configureDependencies() {
  storageInjector();
}
''';
      final updated = ensureStorageInjectorHook(
        makeConfigureDependenciesAsync(content),
        'sample_app',
      );
      expect(updated, contains('await storageInjector();'));
      expect(updated, isNot(contains('  storageInjector();')));
    });
  });

  group('build_runner args', () {
    test('passes the delete flag only for versions older than 2.7.0', () {
      expect(
        buildRunnerBuildArgs('2.4.11'),
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      );
      expect(
        buildRunnerBuildArgs('2.6.9'),
        contains('--delete-conflicting-outputs'),
      );
      expect(buildRunnerBuildArgs('2.7.0'),
          isNot(contains('--delete-conflicting-outputs')));
      expect(buildRunnerBuildArgs('2.15.1'), ['run', 'build_runner', 'build']);
      expect(buildRunnerBuildArgs(null), ['run', 'build_runner', 'build']);
    });

    test('reads the locked build_runner version', () {
      final lock = File(p.join(temp.path, 'pubspec.lock'))
        ..writeAsStringSync('''
packages:
  build_runner:
    dependency: "direct dev"
    description:
      name: build_runner
    version: "2.15.1"
''');

      expect(readBuildRunnerVersion(lock.path), '2.15.1');
      expect(readBuildRunnerVersion(p.join(temp.path, 'missing.lock')), isNull);
    });
  });
}
