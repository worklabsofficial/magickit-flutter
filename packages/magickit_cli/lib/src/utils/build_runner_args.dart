import 'dart:io';

import 'package:yaml/yaml.dart';

/// Arguments for `dart run build_runner build`.
///
/// `--delete-conflicting-outputs` is the default since build_runner 2.7.0 and
/// current releases warn when it is passed. Older 2.4–2.6 releases still need
/// the flag to replace an existing `objectbox.g.dart`.
List<String> buildRunnerBuildArgs(String? buildRunnerVersion) {
  final args = <String>['run', 'build_runner', 'build'];
  if (buildRunnerVersion != null && _isOlderThan(buildRunnerVersion, 2, 7, 0)) {
    args.add('--delete-conflicting-outputs');
  }
  return args;
}

/// Read the resolved `build_runner` version from a pub lockfile.
String? readBuildRunnerVersion([String lockPath = 'pubspec.lock']) {
  final file = File(lockPath);
  if (!file.existsSync()) return null;
  try {
    final doc = loadYaml(file.readAsStringSync());
    if (doc is! YamlMap) return null;
    final packages = doc['packages'];
    if (packages is! YamlMap) return null;
    final buildRunner = packages['build_runner'];
    if (buildRunner is! YamlMap) return null;
    final version = buildRunner['version']?.toString();
    if (version == null || version.trim().isEmpty) return null;
    return version.trim();
  } catch (_) {
    return null;
  }
}

bool _isOlderThan(String version, int major, int minor, int patch) {
  final parts = version.split('-').first.split('+').first.split('.');
  int at(int index) {
    if (index >= parts.length) return 0;
    return int.tryParse(parts[index]) ?? 0;
  }

  final current = [at(0), at(1), at(2)];
  final target = [major, minor, patch];
  for (var i = 0; i < 3; i++) {
    if (current[i] != target[i]) return current[i] < target[i];
  }
  return false;
}
