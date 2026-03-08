import 'package:magickit_cli/magickit_cli.dart';

void main(List<String> arguments) async {
  final runner = MagicKitRunner()
    ..addCommand(DoctorCommand())
    ..addCommand(InitCommand())
    ..addCommand(AssetsCommand())
    ..addCommand(L10nCommand())
    ..addCommand(RegistryCommand())
    ..addCommand(FeatureCommand())
    ..addCommand(KickstartCommand())
    ..addCommand(PageCommand())
    ..addCommand(ApiCommand())
    ..addCommand(ComponentCommand())
    ..addCommand(ThemeCommand())
    ..addCommand(SlicingCommand())
    ..addCommand(VersionCommand());

  await runner.run(arguments);
}
