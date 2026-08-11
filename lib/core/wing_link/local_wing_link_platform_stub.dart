import 'local_wing_link_process.dart';

String localAppExecutablePath() => '';

Future<LocalWingLinkProcessResult> runLocalWingLink(
  String executable,
  List<String> arguments,
) async => const LocalWingLinkProcessResult(exitCode: 126);

Future<LocalWingLinkSetupOperation> startLocalWingLinkSetup(
  String executable,
  LocalWingLinkProgressCallback onProgress,
) async => _UnavailableSetupOperation();

class _UnavailableSetupOperation implements LocalWingLinkSetupOperation {
  @override
  Future<LocalWingLinkProcessResult> get result async =>
      const LocalWingLinkProcessResult(exitCode: 126);

  @override
  Future<void> cancel() async {}
}
