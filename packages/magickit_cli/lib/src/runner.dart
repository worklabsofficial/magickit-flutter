import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'utils/version_utils.dart';

/// Custom CommandRunner dengan styled help output.
class MagicKitRunner extends CommandRunner<void> {
  MagicKitRunner()
      : super(
          'magickit',
          'MagicKit CLI — Flutter development tools & code generator.',
        ) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Tampilkan versi MagicKit CLI.',
    );
  }

  @override
  Future<void> run(Iterable<String> args) async {
    final results = argParser.parse(args);
    if (results['version'] == true) {
      final cliVersion = VersionUtils.readCliVersion();
      print('magickit_cli v$cliVersion');
      return;
    }
    return super.run(args);
  }

  @override
  void printUsage() {
    final log = Logger();
    final cliVersion = VersionUtils.readCliVersion();

    log.info('');
    log.info(
      lightCyan.wrap(
        '  ╔══════════════════════════════════════╗\n'
        '  ║   MagicKit CLI  v$cliVersion               ║\n'
        '  ║   Flutter development toolkit         ║\n'
        '  ╚══════════════════════════════════════╝',
      )!,
    );
    log.info('');
    log.info('${white.wrap('Usage:')} magickit <command> [arguments]');
    log.info('');

    // Setup
    log.info(lightYellow.wrap('  Setup & Diagnostik')!);
    _printCommand(log, 'doctor ', 'Cek environment, dependencies, konfigurasi');
    _printCommand(log, 'init   ', 'Generate magickit.yaml di root project');
    log.info('');

    // Generation
    log.info(lightYellow.wrap('  Code Generation')!);
    _printCommand(log, 'page      ', 'Generate page + routing dalam feature');
    _printCommand(
        log, 'kickstart ', 'Starter app: splash, onboarding, login, main nav');
    _printCommand(
        log, 'api       ', 'Generate full-stack (data/domain/presentation/DI)');
    _printCommand(log, 'assets    ', 'Scan assets/ → Dart class statics');
    _printCommand(log, 'l10n      ', 'Scan lang/ → AppLocalizations class');
    _printCommand(log, 'component ', 'Scaffold widget baru dengan annotation');
    log.info('');

    // Registry & AI
    log.info(lightYellow.wrap('  Registry & AI')!);
    _printCommand(
        log, 'registry  ', 'Scan annotations → component_registry.yaml');
    _printCommand(
        log, 'slicing   ', 'Gambar/Figma → Flutter code via AI provider');
    _printCommand(log, 'snippets  ', 'Install VS Code snippets untuk MagicKit');
    log.info('');

    // Storage
    log.info(lightYellow.wrap('  Storage (ObjectBox)')!);
    _printCommand(
        log, 'storage   ', 'Init, add entity, table ops, generate models');
    log.info('');

    // Info
    log.info(lightYellow.wrap('  Info')!);
    _printCommand(log, 'version   ', 'Tampilkan versi CLI dan UI Kit');
    _printCommand(log, 'help      ', 'Tampilkan bantuan untuk sebuah command');
    log.info('');

    log.info(
      '${white.wrap('Global:')} '
      '${cyan.wrap('-h, --help')}   Tampilkan bantuan\n'
      '         ${cyan.wrap('--version')}  Tampilkan versi',
    );
    log.info('');
    log.info(
      darkGray.wrap(
        '  Contoh: magickit page auth login --path-params id\n'
        '          magickit kickstart\n'
        '          magickit slicing --image ui.png\n'
        '          magickit help <command>',
      )!,
    );
    log.info('');
  }

  void _printCommand(Logger log, String name, String desc) {
    log.info('    ${cyan.wrap(name.padRight(10))}  $desc');
  }
}
