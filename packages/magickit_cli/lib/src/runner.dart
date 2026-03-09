import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'commands/version_command.dart';

/// Custom CommandRunner dengan styled help output.
class MagicKitRunner extends CommandRunner<void> {
  MagicKitRunner()
      : super(
          'magickit',
          'MagicKit CLI — Flutter development tools & code generator.',
        );

  @override
  void printUsage() {
    final log = Logger();

    log.info('');
    log.info(
      lightCyan.wrap(
        '  ╔══════════════════════════════════════╗\n'
        '  ║   MagicKit CLI  v${VersionCommand.cliVersion}               ║\n'
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
    _printCommand(log, 'page      ', 'Generate page dalam feature (MagicCubit boilerplate)');
    _printCommand(log, 'feature   ', 'Generate route group untuk sebuah feature');
    _printCommand(log, 'kickstart ', 'Starter app: splash, onboarding, login, main nav');
    _printCommand(log, 'api       ', 'JSON schema → Dart models (fromJson/toJson)');
    _printCommand(log, 'assets    ', 'Scan assets/ → Dart class statics');
    _printCommand(log, 'l10n      ', 'Scan lang/ → AppLocalizations class');
    _printCommand(log, 'component ', 'Scaffold widget baru dengan annotation');
    log.info('');

    // Registry & AI
    log.info(lightYellow.wrap('  Registry & AI')!);
    _printCommand(log, 'registry  ', 'Scan annotations → component_registry.yaml');
    _printCommand(log, 'slicing   ', 'Gambar/Figma → Flutter code via Claude AI');
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
        '          magickit feature auth\n'
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
