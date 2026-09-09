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
  cancelling,
  cancelled,
  complete,
  failed,
}

class LocalHermesSetupController extends ChangeNotifier {
  LocalHermesSetupController(this._host);

  final LocalWingLinkHost _host;
  LocalHermesSetupStatus _status = LocalHermesSetupStatus.idle;
  LocalHermesInspection? _inspection;
  int _generation = 0;
  bool _disposed = false;
  int? _progressPercent;
  int? get progressPercent => _progressPercent;
  String? _progressPhase;
  String? get progressPhase => _progressPhase;
  String? _errorCode;
  String? get errorCode => _errorCode;

  LocalHermesSetupStatus get status => _status;
  LocalHermesInspection? get inspection => _inspection;

  Future<void> inspect() async {
    if (_status == LocalHermesSetupStatus.installing ||
        _status == LocalHermesSetupStatus.cancelling ||
        _status == LocalHermesSetupStatus.detecting) {
      return;
    }
    final generation = ++_generation;
    _status = LocalHermesSetupStatus.detecting;
    _errorCode = null;
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
    _progressPercent = null;
    _progressPhase = null;
    _status = LocalHermesSetupStatus.installing;
    _errorCode = null;
    _notify();
    try {
      final result = await _host.setup(
        onProgress: (progress) {
          if (generation != _generation) return;
          _progressPercent = progress.percent.clamp(0, 100);
          _progressPhase = switch (progress.phase) {
            'inspect' ||
            'download' ||
            'install' ||
            'verify' ||
            'preflight' ||
            'authentication' ||
            'api_endpoint' ||
            'gateway' ||
            'health' ||
            'complete' => progress.phase,
            _ => null,
          };
          _notify();
        },
      );
      if (generation != _generation) return;
      if (!result.hermesInstalled || !result.gatewayStarted) {
        throw const LocalWingLinkException(
          'setup_incomplete',
          'Hermes setup did not complete.',
        );
      }
      _progressPhase = 'verify';
      _progressPercent = null;
      _notify();
      _inspection = await _host.inspect();
      if (generation != _generation) return;
      if (_inspection?.hermesHealthy != true) {
        throw const LocalWingLinkException(
          'verification_failed',
          'Hermes verification failed.',
        );
      }
      _status = LocalHermesSetupStatus.complete;
    } catch (error) {
      if (generation != _generation) return;
      _status = LocalHermesSetupStatus.failed;
      _errorCode = error is LocalWingLinkException ? error.code : null;
    }
    _notify();
  }

  Future<void> cancel() async {
    if (_status != LocalHermesSetupStatus.installing) return;
    ++_generation;
    _status = LocalHermesSetupStatus.cancelling;
    _notify();
    try {
      await _host.cancelSetup();
      _status = LocalHermesSetupStatus.cancelled;
    } catch (_) {
      _status = LocalHermesSetupStatus.failed;
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
