import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class VersionUtils {
  static String readCliVersion() {
    final pubspecPath = _findCliPubspec();
    return _readVersionFromPubspec(pubspecPath);
  }

  static String readUiKitVersion() {
    final workspaceRoot = _findWorkspaceRoot();
    if (workspaceRoot == null) return 'unknown';
    final pubspecPath = p.join(
      workspaceRoot.path,
      'packages',
      'magickit',
      'pubspec.yaml',
    );
    return _readVersionFromPubspec(pubspecPath);
  }

  static String _readVersionFromPubspec(String? pubspecPath) {
    if (pubspecPath == null) return 'unknown';
    try {
      final file = File(pubspecPath);
      if (!file.existsSync()) return 'unknown';
      final content = file.readAsStringSync();
      final doc = loadYaml(content);
      if (doc is YamlMap && doc['version'] is String) {
        return doc['version'] as String;
      }
    } catch (_) {}
    return 'unknown';
  }

  static String? _findCliPubspec() {
    final scriptFile = File.fromUri(Platform.script);
    if (scriptFile.existsSync()) {
      var dir = scriptFile.parent;
      for (var i = 0; i < 6; i++) {
        final candidate = p.join(dir.path, 'pubspec.yaml');
        if (_looksLikeCliPubspec(candidate)) return candidate;
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
    }

    final workspaceRoot = _findWorkspaceRoot();
    if (workspaceRoot != null) {
      final candidate = p.join(
        workspaceRoot.path,
        'packages',
        'magickit_cli',
        'pubspec.yaml',
      );
      if (_looksLikeCliPubspec(candidate)) return candidate;
    }

    return null;
  }

  static bool _looksLikeCliPubspec(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return false;
      final content = file.readAsStringSync();
      final doc = loadYaml(content);
      return doc is YamlMap && doc['name'] == 'magickit_cli';
    } catch (_) {
      return false;
    }
  }

  static Directory? _findWorkspaceRoot() {
    var dir = Directory.current;
    while (true) {
      final melosFile = File(p.join(dir.path, 'melos.yaml'));
      if (melosFile.existsSync()) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) return null;
      dir = parent;
    }
  }
}
