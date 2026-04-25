import 'package:magickit_cli/magickit_cli.dart';

void main(List<String> arguments) async {
  final runner = MagicKitRunner()
    ..addCommand(DoctorCommand())
    ..addCommand(InitCommand())
    ..addCommand(AssetsCommand())
    ..addCommand(L10nCommand())
    ..addCommand(RegistryCommand())
    ..addCommand(KickstartCommand())
    ..addCommand(PageCommand())
    ..addCommand(ApiCommand())
    ..addCommand(ComponentCommand())
    ..addCommand(SlicingCommand())
    ..addCommand(SnippetsCommand())
    ..addCommand(StorageCommand())
    ..addCommand(VersionCommand());

  await runner.run(arguments);
}
