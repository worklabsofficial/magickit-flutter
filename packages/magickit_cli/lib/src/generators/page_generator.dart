import 'dart:io';
import '../utils/string_utils.dart';

class PageGenerator {
  /// Generate semua file clean architecture untuk satu feature.
  Future<List<String>> generate({
    required String name,
    required String outputDir,
    required String stateManagement,
  }) async {
    final pascal = toPascalCase(name);
    final snake = toSnakeCase(pascal);
    final featureDir = '$outputDir/$snake';
    final generated = <String>[];

    final files = {
      // Data layer
      '$featureDir/data/datasources/${snake}_remote_datasource.dart':
          _datasourceTemplate(pascal, snake),
      '$featureDir/data/models/${snake}_model.dart':
          _modelTemplate(pascal, snake),
      '$featureDir/data/repositories/${snake}_repository_impl.dart':
          _repositoryImplTemplate(pascal, snake),

      // Domain layer
      '$featureDir/domain/entities/${snake}_entity.dart':
          _entityTemplate(pascal),
      '$featureDir/domain/repositories/${snake}_repository.dart':
          _repositoryTemplate(pascal, snake),
      '$featureDir/domain/usecases/${snake}_usecase.dart':
          _usecaseTemplate(pascal, snake),

      // Presentation layer
      '$featureDir/presentation/pages/${snake}_page.dart':
          _pageTemplate(pascal, snake),
    };

    // State management files
    final smFiles = switch (stateManagement) {
      'cubit' => {
          '$featureDir/presentation/cubit/${snake}_cubit.dart':
              _cubitTemplate(pascal, snake),
          '$featureDir/presentation/cubit/${snake}_state.dart':
              _cubitStateTemplate(pascal),
        },
      _ => {
          '$featureDir/presentation/bloc/${snake}_bloc.dart':
              _blocTemplate(pascal, snake),
          '$featureDir/presentation/bloc/${snake}_event.dart':
              _blocEventTemplate(pascal),
          '$featureDir/presentation/bloc/${snake}_state.dart':
              _blocStateTemplate(pascal),
        },
    };
    files.addAll(smFiles);

    for (final entry in files.entries) {
      final file = File(entry.key);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
      generated.add(entry.key);
    }

    return generated;
  }

  // ─── Templates ─────────────────────────────────────────────────────────────

  String _entityTemplate(String pascal) => '''
class ${pascal}Entity {
  const ${pascal}Entity();
}
''';

  String _repositoryTemplate(String pascal, String snake) => '''
import '../entities/${snake}_entity.dart';

abstract class ${pascal}Repository {
  Future<${pascal}Entity> get();
}
''';

  String _usecaseTemplate(String pascal, String snake) => '''
import '../entities/${snake}_entity.dart';
import '../repositories/${snake}_repository.dart';

class ${pascal}UseCase {
  final ${pascal}Repository _repository;

  const ${pascal}UseCase(this._repository);

  Future<${pascal}Entity> call() async {
    return _repository.get();
  }
}
''';

  String _modelTemplate(String pascal, String snake) => '''
import '../../domain/entities/${snake}_entity.dart';

class ${pascal}Model extends ${pascal}Entity {
  const ${pascal}Model();

  factory ${pascal}Model.fromJson(Map<String, dynamic> json) {
    return const ${pascal}Model();
  }

  Map<String, dynamic> toJson() => {};
}
''';

  String _datasourceTemplate(String pascal, String snake) => '''
import '../models/${snake}_model.dart';

abstract class ${pascal}RemoteDatasource {
  Future<${pascal}Model> get();
}

class ${pascal}RemoteDatasourceImpl implements ${pascal}RemoteDatasource {
  // TODO: inject HTTP client (Dio, http, etc.)

  @override
  Future<${pascal}Model> get() async {
    // TODO: implement API call
    throw UnimplementedError();
  }
}
''';

  String _repositoryImplTemplate(String pascal, String snake) => '''
import '../../domain/entities/${snake}_entity.dart';
import '../../domain/repositories/${snake}_repository.dart';
import '../datasources/${snake}_remote_datasource.dart';

class ${pascal}RepositoryImpl implements ${pascal}Repository {
  final ${pascal}RemoteDatasource _datasource;

  const ${pascal}RepositoryImpl(this._datasource);

  @override
  Future<${pascal}Entity> get() async {
    return _datasource.get();
  }
}
''';

  String _blocTemplate(String pascal, String snake) => '''
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/${snake}_usecase.dart';
import '${snake}_event.dart';
import '${snake}_state.dart';

class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  final ${pascal}UseCase _useCase;

  ${pascal}Bloc(this._useCase) : super(${pascal}Initial()) {
    on<${pascal}Started>(_onStarted);
  }

  Future<void> _onStarted(
    ${pascal}Started event,
    Emitter<${pascal}State> emit,
  ) async {
    emit(${pascal}Loading());
    try {
      final data = await _useCase();
      emit(${pascal}Success(data));
    } catch (e) {
      emit(${pascal}Failure(e.toString()));
    }
  }
}
''';

  String _blocEventTemplate(String pascal) => '''
abstract class ${pascal}Event {
  const ${pascal}Event();
}

class ${pascal}Started extends ${pascal}Event {
  const ${pascal}Started();
}
''';

  String _blocStateTemplate(String pascal) => '''
abstract class ${pascal}State {
  const ${pascal}State();
}

class ${pascal}Initial extends ${pascal}State {
  const ${pascal}Initial();
}

class ${pascal}Loading extends ${pascal}State {
  const ${pascal}Loading();
}

class ${pascal}Success<T> extends ${pascal}State {
  final T data;
  const ${pascal}Success(this.data);
}

class ${pascal}Failure extends ${pascal}State {
  final String message;
  const ${pascal}Failure(this.message);
}
''';

  String _cubitTemplate(String pascal, String snake) => '''
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/${snake}_usecase.dart';
import '${snake}_state.dart';

class ${pascal}Cubit extends Cubit<${pascal}State> {
  final ${pascal}UseCase _useCase;

  ${pascal}Cubit(this._useCase) : super(${pascal}Initial());

  Future<void> load() async {
    emit(${pascal}Loading());
    try {
      final data = await _useCase();
      emit(${pascal}Success(data));
    } catch (e) {
      emit(${pascal}Failure(e.toString()));
    }
  }
}
''';

  String _cubitStateTemplate(String pascal) => '''
abstract class ${pascal}State {
  const ${pascal}State();
}

class ${pascal}Initial extends ${pascal}State {
  const ${pascal}Initial();
}

class ${pascal}Loading extends ${pascal}State {
  const ${pascal}Loading();
}

class ${pascal}Success<T> extends ${pascal}State {
  final T data;
  const ${pascal}Success(this.data);
}

class ${pascal}Failure extends ${pascal}State {
  final String message;
  const ${pascal}Failure(this.message);
}
''';

  String _pageTemplate(String pascal, String snake) => '''
import 'package:flutter/material.dart';

class ${pascal}Page extends StatelessWidget {
  const ${pascal}Page({super.key});

  static const routeName = '/${snake.replaceAll('_', '-')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('$pascal'),
      ),
      body: const Center(
        child: Text('${pascal}Page'),
      ),
    );
  }
}
''';
}
