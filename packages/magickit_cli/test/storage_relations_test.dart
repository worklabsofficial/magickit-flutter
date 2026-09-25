import 'dart:io';

import 'package:magickit_cli/src/generators/storage_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('magickit_relations_test_');
  });

  tearDown(() {
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  StorageGenerator generator() => StorageGenerator(appName: 'sample_app');

  void writeJson(String name, String contents) {
    File(p.join(temp.path, name)).writeAsStringSync(contents);
  }

  List<EntityDef> load(StorageGenerator gen) => gen.loadEntities(temp.path);

  group('relation schema', () {
    test('parses a one-to-many backlink and leaves a plain ToOne alone', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "posts", "type": "ToMany", "target": "Post", "backlink": "author", "onDelete": "cascade"},
    {"name": "notes", "type": "ToMany", "target": "Note", "backlink": "author", "onDelete": "NULLIFY"}
  ]
}
''');
      writeJson('post.json', '''
{
  "entity": "Post",
  "fields": [
    {"name": "title", "type": "string"},
    {"name": "bio", "type": "string", "nullable": true}
  ],
  "relations": [
    {"name": "author", "type": "ToOne", "target": "User"},
    {"name": "reviewer", "type": "ToOne", "target": "User"}
  ]
}
''');
      writeJson('note.json', '''
{
  "entity": "Note",
  "fields": [{"name": "body", "type": "string"}],
  "relations": [{"name": "author", "type": "ToOne", "target": "User"}]
}
''');

      final entities = load(generator());
      final user = entities.firstWhere((e) => e.entity == 'User');
      final post = entities.firstWhere((e) => e.entity == 'Post');

      expect(user.relations.map((r) => r.backlink), ['author', 'author']);
      expect(user.relations.map((r) => r.onDelete), ['cascade', 'nullify']);
      expect(post.relations.every((r) => r.backlink == null), isTrue);
      expect(post.relations.every((r) => r.onDelete == null), isTrue);
      expect(post.relations.map((r) => r.name), ['author', 'reviewer']);
    });

    test('parses a many-to-many backlink and a standalone ToMany', () {
      writeJson('student.json', '''
{
  "entity": "Student",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [{"name": "teachers", "type": "ToMany", "target": "Teacher"}]
}
''');
      writeJson('teacher.json', '''
{
  "entity": "Teacher",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "students", "type": "ToMany", "target": "Student", "backlink": "teachers"}
  ]
}
''');

      final entities = load(generator());
      final teacher = entities.firstWhere((e) => e.entity == 'Teacher');
      final student = entities.firstWhere((e) => e.entity == 'Student');
      expect(teacher.relations.single.backlink, 'teachers');
      expect(student.relations.single.backlink, isNull);
      expect(student.relations.single.type, 'ToMany');
    });

    test('rejects a backlink on ToOne and a missing owning relation', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "profile", "type": "ToOne", "target": "Profile", "backlink": "user"}
  ]
}
''');
      writeJson('profile.json', '''
{
  "entity": "Profile",
  "fields": [{"name": "bio", "type": "string"}],
  "relations": [{"name": "owner", "type": "ToOne", "target": "User"}]
}
''');

      expect(
        () => load(generator()),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('Backlink hanya untuk ToMany'), contains('profile')),
          ),
        ),
      );
    });

    test('rejects a backlink that does not exist or points elsewhere', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "posts", "type": "ToMany", "target": "Post", "backlink": "missing"},
    {"name": "notes", "type": "ToMany", "target": "Note", "backlink": "author"}
  ]
}
''');
      writeJson('post.json', '''
{"entity": "Post", "fields": [{"name": "title", "type": "string"}]}
''');
      writeJson('note.json', '''
{
  "entity": "Note",
  "fields": [{"name": "body", "type": "string"}],
  "relations": [{"name": "author", "type": "ToOne", "target": "Post"}]
}
''');

      expect(
        () => load(generator()),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('missing'), contains('bukan User')),
          ),
        ),
      );
    });

    test('rejects a backlink aimed at another backlink or used twice', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "posts", "type": "ToMany", "target": "Post", "backlink": "author"}
  ]
}
''');
      writeJson('post.json', '''
{
  "entity": "Post",
  "fields": [{"name": "title", "type": "string"}],
  "relations": [
    {"name": "author", "type": "ToMany", "target": "User", "backlink": "posts"}
  ]
}
''');

      expect(
        () => load(generator()),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            contains('sendiri sebuah backlink'),
          ),
        ),
      );
    });

    test('rejects two backlinks onto the same owning relation', () {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "posts", "type": "ToMany", "target": "Post", "backlink": "author"},
    {"name": "articles", "type": "ToMany", "target": "Post", "backlink": "author"}
  ]
}
''');
      writeJson('post.json', '''
{
  "entity": "Post",
  "fields": [{"name": "title", "type": "string"}],
  "relations": [{"name": "author", "type": "ToOne", "target": "User"}]
}
''');

      expect(
        () => load(generator()),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            contains('satu backlink'),
          ),
        ),
      );
    });

    test('rejects invalid onDelete values and nullify on ToOne', () {
      writeJson('post.json', '''
{
  "entity": "Post",
  "fields": [{"name": "title", "type": "string"}],
  "relations": [
    {"name": "author", "type": "ToOne", "target": "User", "onDelete": "nullify"},
    {"name": "editor", "type": "ToOne", "target": "User", "onDelete": "restrict"}
  ]
}
''');
      writeJson('user.json', '''
{"entity": "User", "fields": [{"name": "name", "type": "string"}]}
''');

      expect(
        () => load(generator()),
        throwsA(
          isA<StorageSchemaException>().having(
            (e) => e.toString(),
            'message',
            allOf(contains('nullify tidak berlaku'), contains('restrict')),
          ),
        ),
      );
    });
  });

  group('generated relations', () {
    late List<EntityDef> entities;

    setUp(() {
      writeJson('user.json', '''
{
  "entity": "User",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "posts", "type": "ToMany", "target": "Post", "backlink": "author", "onDelete": "cascade"},
    {"name": "notes", "type": "ToMany", "target": "Note", "backlink": "author", "onDelete": "nullify"}
  ]
}
''');
      writeJson('post.json', '''
{
  "entity": "Post",
  "fields": [
    {"name": "title", "type": "string"},
    {"name": "bio", "type": "string", "nullable": true}
  ],
  "relations": [{"name": "author", "type": "ToOne", "target": "User"}]
}
''');
      writeJson('note.json', '''
{
  "entity": "Note",
  "fields": [{"name": "body", "type": "string"}],
  "relations": [{"name": "author", "type": "ToOne", "target": "User"}]
}
''');
      writeJson('student.json', '''
{
  "entity": "Student",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "teachers", "type": "ToMany", "target": "Teacher", "onDelete": "nullify"}
  ]
}
''');
      writeJson('teacher.json', '''
{
  "entity": "Teacher",
  "fields": [{"name": "name", "type": "string"}],
  "relations": [
    {"name": "students", "type": "ToMany", "target": "Student", "backlink": "teachers", "onDelete": "cascade"}
  ]
}
''');
      entities = load(generator());
    });

    EntityDef entity(String name) =>
        entities.firstWhere((item) => item.entity == name);

    test('emits Backlink only on the reverse ToMany', () {
      final gen = generator();
      final user = gen.generateEntityModel(entity('User'));
      final post = gen.generateEntityModel(entity('Post'));
      final teacher = gen.generateEntityModel(entity('Teacher'));
      final student = gen.generateEntityModel(entity('Student'));

      expect(user, contains("@Backlink('author')"));
      expect(user, contains('final posts = ToMany<Post>();'));
      expect(post, isNot(contains('@Backlink')));
      expect(post, contains('final author = ToOne<User>();'));
      expect(teacher, contains("@Backlink('teachers')"));
      expect(student, contains('late final teachers = ToMany<Teacher>();'));
      expect(student, isNot(contains('@Backlink')));
    });

    test('helpers query by related id and assign inside a transaction', () {
      final gen = generator();
      final post = gen.generateEntityStorageHelper(
        entity('Post'),
        entities: entities,
      );
      final student = gen.generateEntityStorageHelper(
        entity('Student'),
        entities: entities,
      );
      final user = gen.generateEntityStorageHelper(
        entity('User'),
        entities: entities,
      );

      expect(post, contains('List<Post> getPostsByAuthor(int authorId)'));
      expect(post, contains('Post_.author.equals(authorId)'));
      expect(post, contains('void setAuthor(Post item, User author)'));
      expect(post, contains('runInTransaction(TxMode.write'));
      expect(post, contains('item.author.target = author;'));

      expect(
        student,
        contains('List<Student> getStudentsByTeacher(int teacherId)'),
      );
      expect(student,
          contains('void setTeachers(Student item, List<Teacher> teachers)'));
      expect(user, contains('List<Post> getPostsOf(int id)'));
      expect(user, contains('void setPosts(User item, List<Post> posts)'));
      expect(user, contains('related.author.target = item;'));
    });

    test('onDelete cascade removes dependents and nullify clears targetId', () {
      final gen = generator();
      final user = gen.generateEntityStorageHelper(
        entity('User'),
        entities: entities,
      );
      final student = gen.generateEntityStorageHelper(
        entity('Student'),
        entities: entities,
      );
      final post = gen.generateEntityStorageHelper(
        entity('Post'),
        entities: entities,
      );

      expect(user, contains('postBox.remove(related.id);'));
      expect(user, contains('related.author.targetId = 0;'));
      expect(user, contains('noteBox.put(related);'));
      expect(user, contains('runInTransaction(TxMode.write'));
      expect(student, contains('item.teachers.remove(related);'));
      expect(post, contains('bool delete(int id) => _box.remove(id);'));
      expect(post, isNot(contains('_applyOnDelete')));
    });

    test('export keeps ids and nulls and skips backlink sides', () {
      final gen = generator();
      final post = gen.generateEntityModel(entity('Post'));
      final user = gen.generateEntityModel(entity('User'));
      final student = gen.generateEntityModel(entity('Student'));
      final manager = gen.generateDatabaseManager(entities);

      expect(post, contains("id: (json['id'] as num?)?.toInt() ?? 0"));
      expect(post, contains("bio: json['bio'] as String?"));
      expect(post, isNot(contains("json['bio'] as String? ?? ''")));
      expect(post, contains("title: json['title'] as String? ?? ''"));
      expect(post,
          contains("authorId': author.targetId == 0 ? null : author.targetId"));
      expect(post, contains('item.author.targetId = authorId.toInt();'));
      expect(user, isNot(contains('postsIds')));
      expect(user, isNot(contains('notesIds')));
      expect(
        student,
        contains("teachersIds': teachers.map((e) => e.id).toList()"),
      );

      expect(
          manager.indexOf('removeAll()'), lessThan(manager.indexOf('putMany')));
      expect(manager, contains('runInTransaction(TxMode.write'));
      expect(manager, contains('_linkStudent'));
      expect(manager, contains('was not found'));
      expect(manager, contains('file order does not matter'));
      expect(manager, isNot(contains('_linkUser')));
      expect(manager, isNot(contains('_linkPost')));
    });
  });
}
