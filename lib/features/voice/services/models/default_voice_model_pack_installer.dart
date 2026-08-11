import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'voice_model_pack_installer.dart';

Future<VoiceModelPackInstaller> createDefaultVoiceModelPackInstaller() async {
  final support = await getApplicationSupportDirectory();
  return VoiceModelPackInstaller(
    rootDirectory: Directory('${support.path}/voice-model-packs'),
  );
}
