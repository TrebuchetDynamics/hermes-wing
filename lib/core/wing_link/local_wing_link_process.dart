typedef LocalWingLinkRunner =
    Future<LocalWingLinkProcessResult> Function(
      String executable,
      List<String> arguments,
    );

typedef LocalWingLinkProgressCallback =
    void Function(LocalWingLinkProgress progress);

typedef LocalWingLinkSetupStarter =
    Future<LocalWingLinkSetupOperation> Function(
      String executable,
      LocalWingLinkProgressCallback onProgress,
    );

class LocalWingLinkProcessResult {
  const LocalWingLinkProcessResult({
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

class LocalWingLinkProgress {
  const LocalWingLinkProgress({
    required this.phase,
    required this.message,
    required this.percent,
  });

  final String phase;
  final String message;
  final int percent;
}

abstract class LocalWingLinkSetupOperation {
  Future<LocalWingLinkProcessResult> get result;

  Future<void> cancel();
}
