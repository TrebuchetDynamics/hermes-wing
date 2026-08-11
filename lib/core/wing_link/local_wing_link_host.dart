import 'dart:convert';

import 'local_wing_link_platform_stub.dart'
    if (dart.library.io) 'local_wing_link_platform_io.dart'
    as platform;
import 'local_wing_link_process.dart';

export 'local_wing_link_process.dart';

class LocalHermesInspection {
  const LocalHermesInspection({
    required this.platform,
    required this.hermesInstalled,
    required this.hermesHealthy,
    required this.hermesVersion,
    required this.wingLinkVersion,
    required this.setupAvailable,
  });

  final String platform;
  final bool hermesInstalled;
  final bool hermesHealthy;
  final String hermesVersion;
  final String wingLinkVersion;
  final bool setupAvailable;
}

class LocalHermesSetupResult {
  const LocalHermesSetupResult({
    required this.hermesInstalled,
    required this.hermesAdopted,
    required this.hermesVersion,
    required this.gatewayStarted,
  });

  final bool hermesInstalled;
  final bool hermesAdopted;
  final String hermesVersion;
  final bool gatewayStarted;
}

class LocalWingLinkException implements Exception {
  const LocalWingLinkException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'LocalWingLinkException($code): $message';
}

class LocalWingLinkHost {
  LocalWingLinkHost({
    String? executablePath,
    LocalWingLinkRunner? runner,
    LocalWingLinkSetupStarter? setupStarter,
  }) : _appExecutable = executablePath ?? platform.localAppExecutablePath(),
       _runner = runner ?? platform.runLocalWingLink,
       _setupStarter =
           setupStarter ??
           (runner == null ? platform.startLocalWingLinkSetup : null);

  final String _appExecutable;
  final LocalWingLinkRunner _runner;
  final LocalWingLinkSetupStarter? _setupStarter;
  LocalWingLinkSetupOperation? _activeSetup;
  bool _setupStarting = false;

  Future<LocalHermesInspection> inspect() async {
    final json = await _runJson(['inspect', '--json']);
    _requireProtocol(json);
    final installed = json['hermes_installed'];
    final healthy = json['hermes_healthy'];
    final setupAvailable = json['setup_available'];
    if (installed is! bool || healthy is! bool || setupAvailable is! bool) {
      throw const LocalWingLinkException(
        'invalid_inspection',
        'Wing Link returned an invalid installation inspection.',
      );
    }
    return LocalHermesInspection(
      platform: json['platform']?.toString() ?? '',
      hermesInstalled: installed,
      hermesHealthy: healthy,
      hermesVersion: json['hermes_version']?.toString() ?? '',
      wingLinkVersion: json['wing_link_version']?.toString() ?? '',
      setupAvailable: setupAvailable,
    );
  }

  Future<LocalHermesSetupResult> setup({
    LocalWingLinkProgressCallback? onProgress,
  }) async {
    final starter = _setupStarter;
    final Map<String, Object?> json;
    if (starter == null) {
      json = await _runJson(['setup', '--json']);
    } else {
      if (_activeSetup != null || _setupStarting) {
        throw const LocalWingLinkException(
          'setup_in_progress',
          'Hermes setup is already running.',
        );
      }
      _setupStarting = true;
      late final LocalWingLinkSetupOperation operation;
      try {
        operation = await starter(_wingLinkExecutable, onProgress ?? (_) {});
        _activeSetup = operation;
      } finally {
        _setupStarting = false;
      }
      try {
        json = _decodeProcessResult(await operation.result);
      } finally {
        if (identical(_activeSetup, operation)) _activeSetup = null;
      }
    }
    _requireProtocol(json);
    final result = json['result'];
    if (result is! Map) {
      throw const LocalWingLinkException(
        'invalid_setup_result',
        'Wing Link returned an invalid setup result.',
      );
    }
    final installed = result['hermes_installed'];
    final adopted = result['hermes_adopted'];
    final gatewayStarted = result['gateway_started'];
    if (installed is! bool || adopted is! bool || gatewayStarted is! bool) {
      throw const LocalWingLinkException(
        'invalid_setup_result',
        'Wing Link returned an invalid setup result.',
      );
    }
    return LocalHermesSetupResult(
      hermesInstalled: installed,
      hermesAdopted: adopted,
      hermesVersion: result['hermes_version']?.toString() ?? '',
      gatewayStarted: gatewayStarted,
    );
  }

  Future<void> cancelSetup() async {
    final operation = _activeSetup;
    if (operation != null) await operation.cancel();
  }

  Future<Map<String, Object?>> _runJson(List<String> arguments) async {
    late final LocalWingLinkProcessResult result;
    try {
      result = await _runner(_wingLinkExecutable, arguments);
    } catch (_) {
      throw const LocalWingLinkException(
        'host_unavailable',
        'Could not start the bundled Wing Link supervisor.',
      );
    }
    return _decodeProcessResult(result);
  }

  Map<String, Object?> _decodeProcessResult(LocalWingLinkProcessResult result) {
    if (result.exitCode != 0) {
      throw const LocalWingLinkException(
        'host_operation_failed',
        'The local Wing Link operation failed. Review diagnostics and retry.',
      );
    }
    try {
      final decoded = jsonDecode(result.stdout);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Fail with the same bounded, non-sensitive error below.
    }
    throw const LocalWingLinkException(
      'invalid_host_response',
      'Wing Link returned invalid data.',
    );
  }

  String get _wingLinkExecutable {
    final slash = _appExecutable.lastIndexOf('/');
    if (slash <= 0) {
      throw const LocalWingLinkException(
        'host_unavailable',
        'Could not locate the bundled Wing Link supervisor.',
      );
    }
    return '${_appExecutable.substring(0, slash)}/wing-link';
  }

  void _requireProtocol(Map<String, Object?> json) {
    if (json['protocol_version'] != 1) {
      throw const LocalWingLinkException(
        'protocol_mismatch',
        'Wing Link uses an unsupported protocol version.',
      );
    }
  }
}
