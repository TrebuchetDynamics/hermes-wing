import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/hermes/auth/native_gateway_auth.dart';
import '../../../core/hermes/auth/secure_gateway_token_store.dart';
import '../../../core/hermes/channel/hermes_api_channel.dart';
import '../../../core/hermes/setup/hermes_gateway_invite.dart';
import '../../../core/hermes/setup/secure_gateway_recovery_store.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../../../l10n/app_localizations.dart';

final gatewayBrowserLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (_) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
final gatewayTokenStoreProvider = Provider((_) => SecureGatewayTokenStore());

/// Explicit native gateway entry. Never injects tokens into the API-server form.
class GatewayLoginPanel extends ConsumerStatefulWidget {
  const GatewayLoginPanel({super.key});
  @override
  ConsumerState<GatewayLoginPanel> createState() => _GatewayLoginPanelState();
}

class _GatewayLoginPanelState extends ConsumerState<GatewayLoginPanel> {
  final _origin = TextEditingController();
  final _profile = TextEditingController(text: 'default');
  NativeGatewayAuth? _auth;
  bool _busy = false;
  bool _restoring = true;
  bool _connected = false;
  bool _saved = false;
  String? _error;
  int _generation = 0;
  HermesApiChannel? _attemptChannel;
  bool Function()? _ownsChannel;
  static const _metadata = 'wing.gateway.last_invite.v1';
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final generation = _generation;
    try {
      final raw = await _storage.read(key: _metadata);
      if (!mounted || generation != _generation) return;
      if (raw != null) {
        final invite = HermesGatewayInvite.decode(raw);
        _origin.text = invite.origin.toString();
        _profile.text = invite.profile;
        _saved = true;
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        _error = AppLocalizations.of(context).gatewayStorageFailed;
      }
    }
    if (mounted && generation == _generation) {
      setState(() => _restoring = false);
    }
  }

  Future<void> _connect({required bool signIn}) async {
    if (_busy || _restoring) return;
    final generation = ++_generation;
    final channel = ref.read(hermesChannelProvider);
    final store = ref.read(gatewayTokenStoreProvider);
    final s = AppLocalizations.of(context);
    bool current() =>
        mounted &&
        generation == _generation &&
        identical(channel, ref.read(hermesChannelProvider)) &&
        identical(store, ref.read(gatewayTokenStoreProvider));
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (channel is! HermesApiChannel) throw const FormatException();
      final invite = HermesGatewayInvite(
        origin: Uri.parse(_origin.text.trim()),
        profile: _profile.text.trim(),
      );
      final auth = NativeGatewayAuth(
        origin: invite.origin,
        launchBrowser: ref.read(gatewayBrowserLauncherProvider),
      );
      _auth = auth;
      var tokens = signIn
          ? await auth.login()
          : await store.load(invite.origin);
      if (!current()) return;
      if (tokens == null) throw const FormatException();
      if (!signIn && tokens.needsRefresh()) {
        tokens = await auth.refresh(tokens);
        if (!current()) return;
      }
      await store.save(tokens, isCurrent: current);
      if (!current()) return;
      await _storage.write(key: _metadata, value: invite.encode());
      if (!current()) return;
      final recoveryStore = SecureGatewayRecoveryStore();
      final recovery = await recoveryStore.load(invite);
      if (!current()) return;
      var handedOff = false;
      await channel.connectRemoteGateway(
        baseUrl: invite.origin.replace(path: '').toString(),
        accessToken: tokens.accessToken,
        profile: invite.profile,
        canAccept: () => handedOff || current(),
        storedSession: recovery?.storedSessionId,
        uncertain: recovery?.uncertain ?? false,
        persistRecovery: recoveryStore.save,
        onAcquire: (owns) {
          _attemptChannel = channel;
          _ownsChannel = owns;
        },
      );
      if (!current()) return;
      if (!channel.state.isConnected ||
          channel.state.selectedProfileId != invite.profile) {
        throw const FormatException();
      }
      if (channel.state.activeSessionId != null) {
        await channel.enableLocalServeChat();
        if (!current()) return;
        if (channel.state.serveChat == null) throw const FormatException();
      }
      handedOff = true;
      _ownsChannel = null;
      _attemptChannel = null;
      setState(() {
        _connected = true;
        _saved = true;
      });
      if (mounted) context.go('/hermes');
    } catch (_) {
      if (current()) setState(() => _error = s.gatewayLoginFailed);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _forget() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() => _busy = true);
    try {
      final invite = HermesGatewayInvite(
        origin: Uri.parse(_origin.text.trim()),
        profile: _profile.text.trim(),
      );
      await ref.read(gatewayTokenStoreProvider).delete(invite.origin);
      await _storage.delete(key: _metadata);
      if (!mounted || generation != _generation) return;
      setState(() {
        _saved = false;
        _error = null;
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = AppLocalizations.of(context).gatewayStorageFailed,
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  void _cancelAttempt() {
    ++_generation;
    unawaited(_auth?.cancel() ?? Future<void>.value());
    final owns = _ownsChannel;
    final channel = _attemptChannel;
    _ownsChannel = null;
    _attemptChannel = null;
    if (owns?.call() == true && channel != null) {
      unawaited(channel.disconnect());
    }
  }

  @override
  void dispose() {
    // Successful channel ownership survives navigation; pending login does not.
    _cancelAttempt();
    _origin.dispose();
    _profile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.gatewayLoginBody),
            if (_restoring) const LinearProgressIndicator(),
            TextField(
              key: const ValueKey('gateway-address'),
              controller: _origin,
              enabled: !_busy && !_restoring,
              autocorrect: false,
              decoration: InputDecoration(labelText: s.gatewayAddress),
            ),
            TextField(
              key: const ValueKey('gateway-profile'),
              controller: _profile,
              enabled: !_busy && !_restoring,
              autocorrect: false,
              decoration: InputDecoration(labelText: s.gatewayProfile),
            ),
            FilledButton(
              key: const ValueKey('gateway-sign-in'),
              onPressed: _busy || _restoring
                  ? null
                  : () => _connect(signIn: true),
              child: Text(s.gatewaySignIn),
            ),
            if (_saved)
              OutlinedButton(
                key: const ValueKey('gateway-reconnect'),
                onPressed: _busy || _restoring
                    ? null
                    : () => _connect(signIn: false),
                child: Text(s.gatewayReconnect),
              ),
            if (_saved)
              TextButton(
                onPressed: _busy ? null : _forget,
                child: Text(s.gatewayForget),
              ),
            if (_busy) ...[
              Text(s.gatewayLoginPending),
              TextButton(
                onPressed: () {
                  _cancelAttempt();
                  setState(() => _busy = false);
                },
                child: Text(s.cancelAction),
              ),
            ],
            if (_error != null)
              Semantics(liveRegion: true, child: Text(_error!)),
            if (_connected) Text(s.connectionCheckVerified),
          ],
        ),
      ),
    );
  }
}
