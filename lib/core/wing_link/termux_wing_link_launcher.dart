import 'package:flutter/services.dart';

typedef TermuxWingLinkInvoke =
    Future<Object?> Function(String method, Object? arguments);

enum TermuxWingLinkOperation { status, start, setup }

class TermuxWingLinkAvailability {
  const TermuxWingLinkAvailability({
    required this.termuxInstalled,
    required this.runCommandPermissionGranted,
  });

  final bool termuxInstalled;
  final bool runCommandPermissionGranted;

  bool get ready => termuxInstalled && runCommandPermissionGranted;
}

class TermuxWingLinkException implements Exception {
  const TermuxWingLinkException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'TermuxWingLinkException($code): $message';
}

class TermuxWingLinkLauncher {
  TermuxWingLinkLauncher({TermuxWingLinkInvoke? invoke})
    : _invoke = invoke ?? _invokePlatform;

  static const _channel = MethodChannel(
    'com.trebuchetdynamics.hermes.wing/termux_wing_link',
  );

  final TermuxWingLinkInvoke _invoke;

  Future<TermuxWingLinkAvailability> availability() async {
    final response = await _call('availability', null);
    if (response is! Map) {
      throw const TermuxWingLinkException(
        'termux_invalid_response',
        'Termux availability response is invalid.',
      );
    }
    final installed = response['termux_installed'];
    final permission = response['run_command_permission_granted'];
    if (installed is! bool || permission is! bool) {
      throw const TermuxWingLinkException(
        'termux_invalid_response',
        'Termux availability response is invalid.',
      );
    }
    return TermuxWingLinkAvailability(
      termuxInstalled: installed,
      runCommandPermissionGranted: permission,
    );
  }

  Future<void> dispatch(TermuxWingLinkOperation operation) async {
    final response = await _call('dispatch', {'operation': operation.name});
    if (response is! Map || response['dispatched'] != true) {
      throw const TermuxWingLinkException(
        'termux_dispatch_failed',
        'Termux did not accept the Wing Link operation.',
      );
    }
  }

  Future<Object?> _call(String method, Object? arguments) async {
    try {
      return await _invoke(method, arguments);
    } on PlatformException catch (error) {
      throw TermuxWingLinkException(
        error.code,
        error.message ?? 'Termux operation failed.',
      );
    } on MissingPluginException {
      throw const TermuxWingLinkException(
        'termux_unavailable',
        'The Termux launcher is available only on Android.',
      );
    }
  }

  static Future<Object?> _invokePlatform(String method, Object? arguments) =>
      _channel.invokeMethod<Object?>(method, arguments);
}
