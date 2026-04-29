import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../version.g.dart';

class VersionUtils {
  /// Returns the CLI version.
  ///
  /// Uses the compiled-in [packageVersion] as the primary source so that
  /// the version is correct even when the package is installed globally via
  /// `dart pub global activate` (where pubspec.yaml is not accessible).
  /// Falls back to filesystem lookup for local development scenarios.
  static String readCliVersion() {
    // Primary: compiled-in generated version.
    if (packageVersion != 'unknown' && packageVersion.isNotEmpty) {
      return packageVersion;
    }

    // Fallback: filesystem lookup (development / local path dependency).
    final pubspecPath = _findCliPubspec();
    return _readVersionFromPubspec(pubspecPath);
  }

  static String readUiKitVersion() {
    final cliPubspecPath = _findCliPubspec();
    if (cliPubspecPath != null) {
      final cliDir = p.dirname(cliPubspecPath);
      final uiKitPubspecPath = p.join(cliDir, '..', 'magickit', 'pubspec.yaml');
      if (_looksLikeUiKitPubspec(uiKitPubspecPath)) {
        return _readVersionFromPubspec(uiKitPubspecPath);
      }
    }

    final workspaceRoot = _findWorkspaceRoot();
    if (workspaceRoot != null) {
      final uiKitPubspecPath = p.join(
        workspaceRoot.path,
        'packages',
        'magickit',
        'pubspec.yaml',
      );
      if (_looksLikeUiKitPubspec(uiKitPubspecPath)) {
        return _readVersionFromPubspec(uiKitPubspecPath);
      }
    }

    return 'unknown';
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
    final scriptPath = Platform.script.toFilePath();
    var dir = Directory(p.dirname(scriptPath));

    for (var i = 0; i < 10; i++) {
      final candidate = p.join(dir.path, 'pubspec.yaml');
      if (_looksLikeCliPubspec(candidate)) return candidate;

      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
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

  static bool _looksLikeUiKitPubspec(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return false;
      final content = file.readAsStringSync();
      final doc = loadYaml(content);
      return doc is YamlMap && doc['name'] == 'magickit';
    } catch (_) {
      return false;
    }
  }

  static Directory? _findWorkspaceRoot() {
    var dir = Directory.current;
    for (var i = 0; i < 10; i++) {
      final melosFile = File(p.join(dir.path, 'melos.yaml'));
      if (melosFile.existsSync()) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }
}
