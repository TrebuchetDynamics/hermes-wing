// Qualification only: production WingApp/router, synthetic external boundaries.
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import 'app/wing_app.dart';
import 'core/hermes/channel/hermes_api_channel.dart';
import 'core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'features/hermes_chat/providers/hermes_channel_provider.dart';
import 'features/local_setup/providers/local_hermes_setup_provider.dart';
import 'main_local_setup_recovery_e2e.dart' show SetupRecoveryFixture;

@JS('wingConnectionMatrixControl')
external set _control(JSFunction callback);

@JS('wingE2EEndpointSaveControl')
external set _saveControl(JSFunction callback);
@JS('wingE2EHermesStateSummary')
external set _stateSummary(JSFunction callback);
@JS('wingE2EHermesConnect')
external set _connect(JSFunction callback);
@JS('wingE2EReduceMotion')
external set _reduceMotion(JSFunction callback);

class MatrixEndpointStore extends SecureHermesEndpointStore {
  int attempts = 0;
  int completed = 0;
  bool failNext = false;
  Completer<void>? pending;

  @override
  Future<void> save({
    required String baseUrl,
    String? apiKey,
    String? label,
    String? profileId,
    String? wingLinkOrigin,
    String? wingLinkToken,
    String? wingLinkPendingCredentialId,
    String? wingLinkHostFingerprint,
    String? wingLinkDeviceId,
  }) async {
    attempts++;
    final fail = failNext;
    failNext = false;
    await pending?.future;
    if (fail) throw StateError('synthetic storage rejection');
    await super.save(
      baseUrl: baseUrl,
      apiKey: apiKey,
      label: label,
      profileId: profileId,
      wingLinkOrigin: wingLinkOrigin,
      wingLinkToken: wingLinkToken,
      wingLinkPendingCredentialId: wingLinkPendingCredentialId,
      wingLinkHostFingerprint: wingLinkHostFingerprint,
      wingLinkDeviceId: wingLinkDeviceId,
    );
    completed++;
  }
}

void main() {
  final host = SetupRecoveryFixture();
  final store = MatrixEndpointStore();
  final channel = HermesApiChannel();
  _saveControl = ((JSString action) {
    switch (action.toDart) {
      case 'fail-next':
        store.failNext = true;
      case 'park':
        store.pending ??= Completer<void>();
      case 'release':
        store.pending?.complete();
        store.pending = null;
      case 'read':
        break;
      default:
        throw ArgumentError('Unknown save control');
    }
    return jsonEncode({
      'attempts': store.attempts,
      'completed': store.completed,
      'pending': store.pending != null,
    }).toJS;
  }).toJS;
  _stateSummary = (() => jsonEncode({
    'status': channel.state.status.name,
    'selected_profile_id': channel.state.selectedProfileId,
    'active_session_id': channel.state.activeSessionId,
  }).toJS).toJS;
  _connect = (([JSString? origin]) {
    unawaited(
      channel.connect(baseUrl: origin?.toDart ?? web.window.location.origin),
    );
  }).toJS;
  _reduceMotion = (() {}).toJS;
  _control = ((JSString action) {
    switch (action.toDart) {
      case 'installed':
        host.installed = true;
      case 'missing':
        host.installed = false;
      case 'success':
        host.finish(true);
      case 'failure':
        host.finish(false);
      case 'fail-save':
        store.failNext = true;
      case 'park-save':
        store.pending ??= Completer<void>();
      case 'release-save':
        store.pending?.complete();
        store.pending = null;
      case 'read':
        break;
      default:
        throw ArgumentError('Unknown matrix control');
    }
    final state = channel.state;
    return jsonEncode({
      'inspect': host.inspects,
      'setup': host.setups,
      'cancel': host.cancels,
      'save': {
        'attempts': store.attempts,
        'completed': store.completed,
        'pending': store.pending != null,
      },
      'owner': {
        'origin': state.connectedBaseUrl,
        'profile': state.selectedProfileId,
        'session': state.activeSessionId,
        'status': state.status.name,
      },
    }).toJS;
  }).toJS;
  runApp(
    ProviderScope(
      overrides: [
        hermesChannelProvider.overrideWithValue(channel),
        hermesEndpointStoreProvider.overrideWithValue(store),
        localWingLinkHostProvider.overrideWithValue(host.host),
        localLinuxSetupAvailableProvider.overrideWithValue(true),
      ],
      child: const _MatrixApp(),
    ),
  );
}

class _MatrixApp extends StatelessWidget {
  const _MatrixApp();

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData.fromView(View.of(context)).copyWith(
      textScaler: TextScaler.linear(
        Uri.base.queryParameters['e2eTextScale'] == '2' ? 2 : 1,
      ),
      disableAnimations: true,
    ),
    child: const WingApp(),
  );
}
