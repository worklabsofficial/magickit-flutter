import 'package:mason_logger/mason_logger.dart';

/// Singleton logger untuk MagicKit CLI.
final logger = Logger();

const _magicPrefix = '✦';

String _magicLabel(String message) {
  final prefix = lightMagenta.wrap(_magicPrefix) ?? _magicPrefix;
  final text = lightCyan.wrap(message) ?? message;
  return '$prefix $text';
}

extension MagicLogger on Logger {
  Progress magicProgress(String message) => progress(_magicLabel(message));
  void magicInfo(String message) => info(_magicLabel(message));
  void magicSuccess(String message) => success(_magicLabel(message));
}
