import 'local_wing_link_process.dart';

String localAppExecutablePath() => '';

Future<LocalWingLinkProcessResult> runLocalWingLink(
  String executable,
  List<String> arguments,
) async => const LocalWingLinkProcessResult(exitCode: 126);

Future<LocalWingLinkSetupOperation> startLocalWingLinkSetup(
  String executable,
  LocalWingLinkProgressCallback onProgress,
) async => const LocalWingLinkSetupOperation.unavailable();
