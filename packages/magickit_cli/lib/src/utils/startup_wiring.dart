// Pure edits that make MagicKit startup await ObjectBox safely.
//
// `magickit init` used to emit a synchronous `configureDependencies()` and a
// synchronous `main()`. Storage then inserted `await storageInjector()` into
// that function, which does not compile. These helpers upgrade both call
// sites idempotently.

String makeConfigureDependenciesAsync(String content) {
  if (!content.contains('configureDependencies')) return content;

  final alreadyAsync = RegExp(
    r'Future<void>\s+configureDependencies\s*\(\s*\)\s*async\b',
  );
  if (alreadyAsync.hasMatch(content)) return content;

  final futureSync = RegExp(
    r'Future<void>\s+configureDependencies\s*\(\s*\)\s*\{',
  );
  if (futureSync.hasMatch(content)) {
    return content.replaceFirst(
      futureSync,
      'Future<void> configureDependencies() async {',
    );
  }

  final voidFn = RegExp(
    r'\bvoid\s+configureDependencies\s*\(\s*\)\s*(?:async\s*)?\{',
  );
  if (!voidFn.hasMatch(content)) return content;
  return content.replaceFirst(
    voidFn,
    'Future<void> configureDependencies() async {',
  );
}

/// Await an existing `configureDependencies()` call from an async `main`.
///
/// Leaves the file unchanged when `main` does not call `configureDependencies`.
String makeMainAwaitConfigureDependencies(String content) {
  if (!RegExp(r'configureDependencies\s*\(').hasMatch(content)) {
    return content;
  }

  final lines = content.split('\n');
  final updatedLines = <String>[];
  for (final line in lines) {
    final callsConfigure = line.contains('configureDependencies(') &&
        line.contains(';') &&
        !line.contains('await ');
    if (!callsConfigure) {
      updatedLines.add(line);
      continue;
    }
    updatedLines.add(
      line.replaceFirst(
        'configureDependencies(',
        'await configureDependencies(',
      ),
    );
  }
  var updated = updatedLines.join('\n');

  updated = updated.replaceFirst(
    RegExp(r'Future<void>\s+main\s*\(\s*\)\s*\{'),
    'Future<void> main() async {',
  );
  updated = updated.replaceFirst(
    RegExp(r'\bvoid\s+main\s*\(\s*\)\s*(?:async\s*)?\{'),
    'Future<void> main() async {',
  );

  if (!updated.contains('WidgetsFlutterBinding.ensureInitialized()') &&
      updated.contains('await configureDependencies();')) {
    updated = updated.replaceFirst(
      'await configureDependencies();',
      'WidgetsFlutterBinding.ensureInitialized();\n'
          '  await configureDependencies();',
    );
  }

  return updated;
}

/// Insert the storage import and `await storageInjector()` at the MagicKit
/// markers. Existing calls are left in place and given `await` when missing.
String ensureStorageInjectorHook(String content, String appName) {
  final importLine =
      "import 'package:$appName/core/storage/objectbox/storage_injector.dart';";

  if (!content.contains(importLine) && content.contains('// MAGICKIT:IMPORT')) {
    content = content.replaceFirst(
      '// MAGICKIT:IMPORT',
      '$importLine\n// MAGICKIT:IMPORT',
    );
  }

  if (!content.contains('storageInjector()') &&
      content.contains('// MAGICKIT:INJECTOR')) {
    content = content.replaceFirst(
      '// MAGICKIT:INJECTOR',
      '  await storageInjector();\n  // MAGICKIT:INJECTOR',
    );
  }

  final lines = content.split('\n');
  final updatedLines = <String>[];
  for (final line in lines) {
    if (line.contains('storageInjector()') && !line.contains('await ')) {
      updatedLines.add(
        line.replaceFirst('storageInjector()', 'await storageInjector()'),
      );
    } else {
      updatedLines.add(line);
    }
  }
  return updatedLines.join('\n');
}
