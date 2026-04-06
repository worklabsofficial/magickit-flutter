/// Converts a string to camelCase.
/// Example: "logo_main" -> "logoMain", "my-file" -> "myFile"
String toCamelCase(String input) {
  final parts = input.split(RegExp(r'[_\-\s]+'));
  if (parts.isEmpty) return input;
  final nonEmpty = parts.where((p) => p.isNotEmpty).toList();
  if (nonEmpty.isEmpty) return input;
  // If single part with no separators, preserve original casing for camelCase
  if (nonEmpty.length == 1 && !input.contains(RegExp(r'[_\-\s]'))) {
    return nonEmpty.first[0].toLowerCase() + nonEmpty.first.substring(1);
  }
  return nonEmpty.first.toLowerCase() +
      nonEmpty.skip(1).map(capitalize).join('');
}

/// Converts a string to PascalCase.
/// Example: "my_widget" -> "MyWidget", "MyWidget" -> "MyWidget"
String toPascalCase(String input) {
  // If already looks like PascalCase (starts with uppercase, no separators), keep it
  if (input.isNotEmpty &&
      input[0] == input[0].toUpperCase() &&
      !input.contains(RegExp(r'[_\-\s]'))) {
    return input;
  }
  final camel = toCamelCase(input);
  return camel.isEmpty ? camel : camel[0].toUpperCase() + camel.substring(1);
}

/// Converts a string to snake_case.
/// Example: "MyWidget" -> "my_widget"
String toSnakeCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'([A-Z])'),
        (m) => '_${m.group(0)!.toLowerCase()}',
      )
      .replaceAll(RegExp(r'^_'), '');
}

/// Capitalizes the first letter of a string.
String capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
