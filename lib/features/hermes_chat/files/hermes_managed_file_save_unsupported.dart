import 'hermes_managed_file_save.dart';

HermesManagedFileSaver createManagedFileSaver() => HermesManagedFileSaver(
  supported: false,
  writeAndReadBack: (_, _, _, _, _) async => null,
);
