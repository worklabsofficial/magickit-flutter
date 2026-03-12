import 'dart:io';

import 'logger.dart';

void requireMagickitInit({bool requireInjector = false}) {
  if (!File('magickit.yaml').existsSync()) {
    logger.err("magickit init not detected.\n   Run 'magickit init' first.");
    exit(1);
  }

  if (requireInjector &&
      !File('lib/core/dependency_injection/injector.dart').existsSync()) {
    logger.err(
      'lib/core/dependency_injection/injector.dart tidak ditemukan.\n'
      'Jalankan `magickit init` terlebih dahulu.',
    );
    exit(1);
  }
}
