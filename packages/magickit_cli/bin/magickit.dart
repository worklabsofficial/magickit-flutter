import 'package:args/command_runner.dart';
import 'package:magickit_cli/magickit_cli.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner<void>(
    'magickit',
    'MagicKit CLI — Flutter development tools & code generator.',
  )
    ..addCommand(DoctorCommand())
    ..addCommand(InitCommand())
    ..addCommand(AssetsCommand())
    ..addCommand(L10nCommand())
    ..addCommand(RegistryCommand())
    ..addCommand(PageCommand())
    ..addCommand(ApiCommand())
    ..addCommand(ComponentCommand())
    ..addCommand(ThemeCommand())
    ..addCommand(SlicingCommand());

  await runner.run(arguments);
}
