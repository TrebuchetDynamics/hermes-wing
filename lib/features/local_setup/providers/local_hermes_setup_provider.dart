import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/wing_link/local_wing_link_host.dart';

final localWingLinkHostProvider = Provider<LocalWingLinkHost>(
  (ref) => LocalWingLinkHost(),
);

final localHermesSetupControllerProvider =
    ChangeNotifierProvider.autoDispose<LocalHermesSetupController>((ref) {
      return LocalHermesSetupController(ref.watch(localWingLinkHostProvider));
    });

enum LocalHermesSetupStatus {
  idle,
  detecting,
  missing,
  ready,
  unhealthy,
  installing,
  complete,
  failed,
}

class LocalHermesSetupController extends ChangeNotifier {
  LocalHermesSetupController(this._host);

  final LocalWingLinkHost _host;
  LocalHermesSetupStatus _status = LocalHermesSetupStatus.idle;
  LocalHermesInspection? _inspection;
  String? _errorMessage;
  int _generation = 0;
  bool _disposed = false;

  LocalHermesSetupStatus get status => _status;
  LocalHermesInspection? get inspection => _inspection;
  String? get errorMessage => _errorMessage;

  Future<void> inspect() async {
    final generation = ++_generation;
    _status = LocalHermesSetupStatus.detecting;
    _errorMessage = null;
    _notify();
    try {
      final inspection = await _host.inspect();
      if (generation != _generation) return;
      _inspection = inspection;
      if (!inspection.setupAvailable || inspection.platform != 'linux') {
        throw const LocalWingLinkException(
          'setup_unavailable',
          'Local setup is unavailable on this platform.',
        );
      }
      _status = !inspection.hermesInstalled
          ? LocalHermesSetupStatus.missing
          : inspection.hermesHealthy
          ? LocalHermesSetupStatus.ready
          : LocalHermesSetupStatus.unhealthy;
    } catch (_) {
      if (generation != _generation) return;
      _status = LocalHermesSetupStatus.failed;
      _errorMessage =
          'Hermes Wing could not inspect this Linux host. Review Diagnostics and retry.';
    }
    _notify();
  }

  Future<void> setup() async {
    if (_status != LocalHermesSetupStatus.missing &&
        _status != LocalHermesSetupStatus.ready &&
        _status != LocalHermesSetupStatus.unhealthy) {
      return;
    }
    final generation = ++_generation;
    _status = LocalHermesSetupStatus.installing;
    _errorMessage = null;
    _notify();
    try {
      final result = await _host.setup();
      if (generation != _generation) return;
      if (!result.hermesInstalled || !result.gatewayStarted) {
        throw const LocalWingLinkException(
          'setup_incomplete',
          'Hermes setup did not complete.',
        );
      }
      _inspection = await _host.inspect();
      if (generation != _generation) return;
      if (_inspection?.hermesHealthy != true) {
        throw const LocalWingLinkException(
          'verification_failed',
          'Hermes verification failed.',
        );
      }
      _status = LocalHermesSetupStatus.complete;
    } catch (_) {
      if (generation != _generation) return;
      _status = LocalHermesSetupStatus.failed;
      _errorMessage =
          'Hermes setup did not complete. Some local changes may have been applied; review Diagnostics before retrying.';
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_host.cancelSetup());
    super.dispose();
  }
}
