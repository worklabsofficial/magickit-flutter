// Import matches stop at the semicolon. A pattern that also consumes the
// following whitespace (`\s*`) eats the newline, and inserting there produces
// `';final`.

final RegExp _importStatement = RegExp(
  r"""^import\s+['"][^'"]+['"];""",
  multiLine: true,
);

final RegExp _importStatementWithPath = RegExp(
  r"""^import\s+['"]([^'"]+)['"];""",
  multiLine: true,
);

/// `initialLocation: '...'` — `\s` is a real whitespace class, not `\\s`.
final RegExp initialLocationPattern = RegExp(r"initialLocation:\s*'[^']*'");

/// Inserts [importLine] on its own line after the last import.
String insertDartImport(String content, String importLine) {
  final line = importLine.trim();
  if (line.isEmpty || content.contains(line)) return content;
  return insertDartImportAt(content, lastDartImportEnd(content), line);
}

/// Inserts [importLine] immediately after the import whose path ends with
/// [suffix]. Falls back to [insertDartImport] when that import is missing.
String insertDartImportAfterSuffix(
  String content,
  String suffix,
  String importLine,
) {
  final line = importLine.trim();
  if (line.isEmpty || content.contains(line)) return content;
  final end = importLineEndBySuffix(content, suffix);
  if (end == -1) return insertDartImport(content, line);
  return insertDartImportAt(content, end, line);
}

/// Removes one exact import line, including a single trailing newline.
String removeDartImport(String content, String importLine) {
  final line = importLine.trim();
  if (line.isEmpty) return content;
  final exactLine = RegExp(
    '^[ \\t]*${RegExp.escape(line)}[ \\t]*\\r?\\n?',
    multiLine: true,
  );
  return content.replaceAll(exactLine, '').replaceAll('\n\n\n', '\n\n');
}

/// Index just after the semicolon of the last import, or `-1` when there is
/// none. The newline after the semicolon is not consumed.
int lastDartImportEnd(String content) {
  final matches = _importStatement.allMatches(content).toList();
  if (matches.isEmpty) return -1;
  return matches.last.end;
}

/// Index just after the semicolon of the import whose URI ends with [suffix].
int importLineEndBySuffix(String content, String suffix) {
  for (final match in _importStatementWithPath.allMatches(content)) {
    final path = match.group(1) ?? '';
    if (path.endsWith(suffix)) return match.end;
  }
  return -1;
}

/// Inserts [importLine] at [end] (an index from [lastDartImportEnd]).
///
/// [end] `< 0` prepends the import. The new import is always followed by a
/// newline before the remaining source.
String insertDartImportAt(String content, int end, String importLine) {
  final line = importLine.trim();
  if (line.isEmpty) return content;
  if (end < 0) {
    if (content.isEmpty) return '$line\n';
    if (content.startsWith('\n')) return '$line$content';
    return '$line\n$content';
  }
  final rest = content.substring(end);
  final gap = rest.startsWith('\n') ? '' : '\n';
  return '${content.substring(0, end)}\n$line$gap$rest';
}

/// Replaces `initialLocation: '...'` with [expression] (a Dart expression,
/// typically a route constant).
String setInitialLocation(String content, String expression) {
  if (!initialLocationPattern.hasMatch(content)) return content;
  return content.replaceFirst(
    initialLocationPattern,
    'initialLocation: $expression',
  );
}
