import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hermes/client/hermes_api_client.dart';
import '../../../core/hermes/client/hermes_api_config.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../../core/wing_link/wing_link_client.dart';
import '../../../core/wing_link/wing_link_transport.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../models/hermes_enrollment_payload.dart';
import '../services/hermes_connect_intent_source.dart';

/// Reads the pending Hermes Wing connect pairing payload from the platform's
/// intent ingress; see [HermesConnectIntentSource].
final hermesConnectIntentSourceProvider = Provider<HermesConnectIntentSource>(
  (ref) => MethodChannelHermesConnectIntentSource(),
);

/// Owns the `HermesEnrollmentController` for the current `/enroll` visit.
/// Wires the real unauthenticated inspect/exchange requests and the real
/// secure endpoint store; overridden in tests with fakes.
final hermesEnrollmentControllerProvider =
    ChangeNotifierProvider.autoDispose<HermesEnrollmentController>((ref) {
      final store = ref.watch(hermesEndpointStoreProvider);
      return HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) =>
            HermesApiClient(
              config: HermesApiConfig.fromBaseUrl(origin.toString()),
            ).inspectEnrollment(origin: origin, code: code),
        exchangeEnrollment: ({required origin, required code}) =>
            HermesApiClient(
              config: HermesApiConfig.fromBaseUrl(origin.toString()),
            ).exchangeEnrollment(origin: origin, code: code),
        inspectPinnedEnrollment:
            ({required origin, required code, required hostFingerprint}) {
              final transport = WingLinkTransport(
                expectedHostFingerprint: hostFingerprint,
              );
              return HermesApiClient(
                config: HermesApiConfig.fromBaseUrl(origin.toString()),
                post: transport.post,
              ).inspectEnrollment(origin: origin, code: code);
            },
        exchangePinnedEnrollment:
            ({required origin, required code, required hostFingerprint}) {
              final transport = WingLinkTransport(
                expectedHostFingerprint: hostFingerprint,
              );
              return HermesApiClient(
                config: HermesApiConfig.fromBaseUrl(origin.toString()),
                post: transport.post,
              ).exchangeEnrollment(origin: origin, code: code);
            },
        verifyEnrollment:
            ({
              required hermesOrigin,
              required hermesToken,
              required wingLinkOrigin,
              required wingLinkToken,
            }) async {
              await HermesApiClient(
                config: HermesApiConfig.fromBaseUrl(
                  hermesOrigin.toString(),
                  apiKey: hermesToken,
                ),
              ).health();
            },
        verifyWingLinkIdentity:
            ({
              required origin,
              required token,
              required hostFingerprint,
            }) async {
              final client = WingLinkClient(
                origin: origin,
                token: token,
                hostFingerprint: hostFingerprint,
              );
              await client.verifyPendingCredential();
              if (hostFingerprint != null) {
                final metadata = await client.getMetadata();
                if (metadata.hostFingerprint != hostFingerprint) {
                  throw const WingLinkException(
                    'Wing Link host identity changed',
                  );
                }
              }
            },
        endpointStore: store,
        connectSavedEndpoint: (gatewayId) async {
          final directory = ref.read(hermesGatewayDirectoryProvider);
          await directory.reload();
          await directory.activateGateway(gatewayId);
        },
      );
    });

typedef EnrollmentClock = DateTime Function();

typedef HermesEnrollmentInspect =
    Future<HermesEnrollmentPreview> Function({
      required Uri origin,
      required String code,
    });

typedef HermesEnrollmentExchange =
    Future<HermesIssuedOperatorToken> Function({
      required Uri origin,
      required String code,
    });

typedef HermesPinnedEnrollmentInspect =
    Future<HermesEnrollmentPreview> Function({
      required Uri origin,
      required String code,
      required String hostFingerprint,
    });

typedef HermesPinnedEnrollmentExchange =
    Future<HermesIssuedOperatorToken> Function({
      required Uri origin,
      required String code,
      required String hostFingerprint,
    });

/// Reconnects the shared Hermes channel to a non-secret endpoint config ID just
/// saved by a successful enrollment, so destination screens land connected.
typedef HermesEnrollmentConnect = Future<void> Function(String gatewayId);
typedef HermesEnrollmentVerify =
    Future<void> Function({
      required Uri hermesOrigin,
      required String hermesToken,
      required Uri wingLinkOrigin,
      required String wingLinkToken,
    });
typedef WingLinkIdentityVerify =
    Future<void> Function({
      required Uri origin,
      required String token,
      required String? hostFingerprint,
    });
typedef WingLinkCredentialAcknowledge =
    Future<void> Function({
      required Uri origin,
      required String token,
      required String credentialId,
      required String? hostFingerprint,
    });

enum HermesEnrollmentStatus {
  idle,
  inspecting,
  ready,
  confirming,
  confirmed,
  expired,
  inspectionFailed,
  exchangeFailed,
}

bool _sameEndpointAuthority(String baseUrl, Uri authority) {
  final candidate = Uri.tryParse(baseUrl);
  return candidate != null &&
      candidate.scheme == authority.scheme &&
      candidate.host.toLowerCase() == authority.host.toLowerCase() &&
      candidate.port == authority.port;
}

String _safeEnrollmentLabel(String value) => String.fromCharCodes(
  value.runes
      .where(
        (rune) =>
            rune >= 0x20 &&
            !(rune >= 0x7f && rune <= 0x9f) &&
            rune != 0x061c &&
            !(rune >= 0x200b && rune <= 0x200f) &&
            !(rune >= 0x2028 && rune <= 0x202e) &&
            !(rune >= 0x2060 && rune <= 0x206f),
      )
      .take(80),
).trim();

/// Owns the review-before-exchange one-time pairing lifecycle: [inspect] a
/// pairing code against the operator-supplied origin so the operator can
/// review label/scopes/expiry, then [confirm] exchanges it exactly once. The
/// raw token this receives from a successful exchange is handed straight to
/// `HermesEndpointStore.save` and is never retained on this controller or
/// exposed through any getter — it must never reach widget text or logs.
class HermesEnrollmentController extends ChangeNotifier {
  HermesEnrollmentController({
    required HermesEnrollmentInspect inspectEnrollment,
    required HermesEnrollmentExchange exchangeEnrollment,
    required HermesEndpointStore endpointStore,
    HermesPinnedEnrollmentInspect? inspectPinnedEnrollment,
    HermesPinnedEnrollmentExchange? exchangePinnedEnrollment,
    HermesEnrollmentVerify? verifyEnrollment,
    WingLinkIdentityVerify? verifyWingLinkIdentity,
    WingLinkCredentialAcknowledge? acknowledgeWingLinkCredential,
    EnrollmentClock? clock,
    this._connectSavedEndpoint,
  }) : _clock = clock ?? DateTime.now,
       _inspect = inspectEnrollment,
       _exchange = exchangeEnrollment,
       _inspectPinned = inspectPinnedEnrollment,
       _exchangePinned = exchangePinnedEnrollment,
       _store = endpointStore,
       _verifyEnrollment =
           verifyEnrollment ??
           (({
             required hermesOrigin,
             required hermesToken,
             required wingLinkOrigin,
             required wingLinkToken,
           }) async {}),
       _verifyWingLinkIdentity =
           verifyWingLinkIdentity ??
           (({
             required origin,
             required token,
             required hostFingerprint,
           }) async {}),
       _acknowledgeWingLinkCredential =
           acknowledgeWingLinkCredential ??
           (({
             required origin,
             required token,
             required credentialId,
             required hostFingerprint,
           }) => WingLinkClient(
             origin: origin,
             token: token,
             hostFingerprint: hostFingerprint,
           ).acknowledgeCredential(credentialId));

  final EnrollmentClock _clock;
  final HermesEnrollmentInspect _inspect;
  final HermesEnrollmentExchange _exchange;
  final HermesPinnedEnrollmentInspect? _inspectPinned;
  final HermesPinnedEnrollmentExchange? _exchangePinned;
  final HermesEndpointStore _store;
  final HermesEnrollmentVerify _verifyEnrollment;
  final WingLinkIdentityVerify _verifyWingLinkIdentity;
  final WingLinkCredentialAcknowledge _acknowledgeWingLinkCredential;
  final HermesEnrollmentConnect? _connectSavedEndpoint;

  HermesEnrollmentStatus _status = HermesEnrollmentStatus.idle;
  HermesEnrollmentPreview? _preview;
  String? _errorMessage;
  Uri? _origin;
  Uri? _exchangeOrigin;
  Uri? _wingLinkOrigin;
  String? _wingLinkHostFingerprint;
  String? _code;
  bool _exchangeAttempted = false;
  int? _connectedProfileCount;
  bool _confirmedLoopback = false;
  int _generation = 0;
  Timer? _expiryTimer;

  bool _disposed = false;

  HermesEnrollmentStatus get status => _status;
  HermesEnrollmentPreview? get preview => _preview;
  String? get errorMessage => _errorMessage;
  int? get connectedProfileCount => _connectedProfileCount;
  bool get confirmedLoopback => _confirmedLoopback;
  Duration? get remainingTime {
    final expiresAt = _preview?.expiresAt;
    if (expiresAt == null) return null;
    final remaining = expiresAt.difference(_clock());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// The origin from the pairing payload — the value that will actually be
  /// saved and connected. The review screen must display this, never the
  /// server-echoed `preview.origin`, so the operator consents to the host
  /// they will really talk to.
  Uri? get origin => _origin;
  Uri? get wingLinkOrigin => _wingLinkOrigin;

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  void _setStatus(HermesEnrollmentStatus status) {
    if (_disposed) return;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _status = status;
    final hasExpiry = _preview?.expiresAt != null;
    if (hasExpiry &&
        (status == HermesEnrollmentStatus.ready ||
            status == HermesEnrollmentStatus.confirming)) {
      _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_status == HermesEnrollmentStatus.ready &&
            remainingTime == Duration.zero) {
          _code = null;
          _errorMessage = null;
          _setStatus(HermesEnrollmentStatus.expired);
        }
        _notify();
      });
    }
  }

  @override
  void dispose() {
    _generation++;
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _disposed = true;
    super.dispose();
  }

  /// Requests server-side inspection of [payload]. Never itself exchanges
  /// the code; only [confirm] does that, and only once.
  Future<void> inspect(HermesEnrollmentPayload payload) async {
    if (_status == HermesEnrollmentStatus.confirming) return;
    final generation = ++_generation;
    _origin = payload.origin;
    _exchangeOrigin = payload.brokerOrigin ?? payload.origin;
    _wingLinkOrigin = payload.wingLinkOrigin;
    _wingLinkHostFingerprint = payload.wingLinkHostFingerprint;
    _code = payload.code;
    _exchangeAttempted = false;
    _connectedProfileCount = null;
    _confirmedLoopback = false;
    _preview = null;
    _errorMessage = null;
    _setStatus(HermesEnrollmentStatus.inspecting);
    _notify();
    try {
      final expectedFingerprint = _wingLinkHostFingerprint;
      final pinnedInspect = _inspectPinned;
      final preview = expectedFingerprint != null && pinnedInspect != null
          ? await pinnedInspect(
              origin: _exchangeOrigin!,
              code: payload.code,
              hostFingerprint: expectedFingerprint,
            )
          : await _inspect(origin: _exchangeOrigin!, code: payload.code);
      if (generation != _generation) return;
      if (preview.connectionCount < 1 || preview.connectionCount > 100) {
        throw const FormatException('Enrollment connection count is invalid');
      }
      if (expectedFingerprint != null &&
          (preview.hostFingerprint != expectedFingerprint ||
              (preview.protocolGeneration != 1 &&
                  preview.protocolGeneration != 2))) {
        throw const FormatException('Wing Link host identity did not match');
      }
      _preview = HermesEnrollmentPreview(
        label: _safeEnrollmentLabel(preview.label),
        origin: preview.origin,
        scopes: preview.scopes,
        connectionCount: preview.connectionCount,
        expiresAt: preview.expiresAt,
        hostFingerprint: preview.hostFingerprint,
        protocolGeneration: preview.protocolGeneration,
      );
      final expiresAt = _preview?.expiresAt;
      if (expiresAt != null && !_clock().isBefore(expiresAt)) {
        _code = null;
        _setStatus(HermesEnrollmentStatus.expired);
      } else {
        _setStatus(HermesEnrollmentStatus.ready);
      }
    } catch (_) {
      if (generation != _generation) return;
      _setStatus(HermesEnrollmentStatus.inspectionFailed);
      _errorMessage = null;
    }
    _notify();
  }

  /// Exchanges the inspected code for a bearer token and persists it via
  /// `HermesEndpointStore.save`. A no-op unless inspection succeeded and no
  /// exchange has been attempted yet for the current payload — this
  /// guarantees at most one exchange call per confirmed pairing, matching
  /// the server's single-use pairing code contract.
  Future<void> confirm() async {
    if (_status != HermesEnrollmentStatus.ready || _exchangeAttempted) return;
    final origin = _origin;
    final exchangeOrigin = _exchangeOrigin;
    final code = _code;
    final wingLinkOrigin = _wingLinkOrigin;
    final wingLinkHostFingerprint = _wingLinkHostFingerprint;
    final preview = _preview;
    if (origin == null ||
        exchangeOrigin == null ||
        code == null ||
        preview == null) {
      return;
    }
    final expiresAt = preview.expiresAt;
    if (expiresAt != null && !_clock().isBefore(expiresAt)) {
      _code = null;
      _errorMessage = null;
      _setStatus(HermesEnrollmentStatus.expired);
      _notify();
      return;
    }
    _exchangeAttempted = true;
    final generation = ++_generation;
    _setStatus(HermesEnrollmentStatus.confirming);
    _notify();
    late final String importedGatewayId;
    try {
      final pinnedExchange = _exchangePinned;
      final issued = wingLinkHostFingerprint != null && pinnedExchange != null
          ? await pinnedExchange(
              origin: exchangeOrigin,
              code: code,
              hostFingerprint: wingLinkHostFingerprint,
            )
          : await _exchange(origin: exchangeOrigin, code: code);
      if (generation != _generation) return;
      if (wingLinkOrigin != null &&
          (issued.wingLinkToken.isEmpty ||
              issued.wingLinkCredentialId.isEmpty ||
              issued.wingLinkOrigin != wingLinkOrigin.toString() ||
              (wingLinkHostFingerprint != null &&
                  (issued.hostFingerprint != wingLinkHostFingerprint ||
                      issued.deviceId != issued.wingLinkCredentialId ||
                      issued.deviceScopes.isEmpty ||
                      (issued.protocolGeneration != 1 &&
                          issued.protocolGeneration != 2))))) {
        throw const FormatException('Wing Link credential did not match');
      }
      final connections = issued.connections.isEmpty
          ? [
              HermesIssuedConnection(
                origin: origin.toString(),
                token: issued.token,
                label: preview.label,
                profileId: 'default',
                credentialId: issued.credentialId,
              ),
            ]
          : issued.connections;
      if (connections.isEmpty ||
          connections.length > 100 ||
          connections.length != preview.connectionCount) {
        throw const FormatException(
          'Enrollment connection count did not match',
        );
      }
      final configs = <HermesEndpointConfig>[];
      final profileIds = <String>{};
      final connectionOrigins = <String>{};
      final credentialIds = <String>{};
      for (final connection in connections) {
        final connectionOrigin = Uri.parse(connection.origin);
        final segments = connectionOrigin.pathSegments
            .where((segment) => segment.isNotEmpty)
            .toList(growable: false);
        final isBundle = issued.connections.isNotEmpty;
        final validPath = !isBundle
            ? segments.isEmpty
            : segments.length == 2 &&
                  segments.first == 'p' &&
                  segments.last == connection.profileId &&
                  connection.profileId.isNotEmpty;
        final sameHermesAuthority =
            connectionOrigin.scheme == origin.scheme &&
            connectionOrigin.host.toLowerCase() == origin.host.toLowerCase() &&
            connectionOrigin.port == origin.port;
        final uniqueBundleIdentity =
            !isBundle ||
            (connection.profileId.isNotEmpty &&
                connection.credentialId.isNotEmpty &&
                profileIds.add(connection.profileId) &&
                connectionOrigins.add(
                  hermesPublicEndpointBaseUrl(connectionOrigin.toString()),
                ) &&
                credentialIds.add(connection.credentialId));
        if (!sameHermesAuthority ||
            !validPath ||
            connectionOrigin.hasQuery ||
            connectionOrigin.hasFragment ||
            connectionOrigin.userInfo.isNotEmpty ||
            connection.token.isEmpty ||
            !uniqueBundleIdentity) {
          throw const FormatException('Hermes connection did not match');
        }
        configs.add(
          HermesEndpointConfig(
            id: hermesEndpointIdForBaseUrl(connection.origin),
            baseUrl: connection.origin,
            apiKey: connection.token,
            label: _safeEnrollmentLabel(connection.label),
            wingLinkOrigin: wingLinkOrigin?.toString(),
            wingLinkToken: wingLinkOrigin == null ? null : issued.wingLinkToken,
            wingLinkPendingCredentialId: wingLinkOrigin == null
                ? null
                : issued.wingLinkCredentialId,
            wingLinkHostFingerprint: wingLinkHostFingerprint,
            wingLinkDeviceId: wingLinkOrigin == null ? null : issued.deviceId,
          ),
        );
      }
      if (wingLinkOrigin != null) {
        await _verifyWingLinkIdentity(
          origin: wingLinkOrigin,
          token: issued.wingLinkToken,
          hostFingerprint: wingLinkHostFingerprint,
        );
        if (generation != _generation) return;
        for (var index = 0; index < connections.length; index++) {
          await _verifyEnrollment(
            hermesOrigin: Uri.parse(connections[index].origin),
            hermesToken: connections[index].token,
            wingLinkOrigin: wingLinkOrigin,
            wingLinkToken: issued.wingLinkToken,
          );
          if (generation != _generation) return;
        }
      }
      final existingConfigs = await _store.loadProfiles();
      if (generation != _generation) return;
      final committedIds = configs.map((config) => config.id).toSet();
      final committedOrigins = configs.map((config) => config.baseUrl).toSet();
      final committedProfiles = [
        ...configs,
        for (final existing in existingConfigs)
          if (!committedIds.contains(existing.id) &&
              !committedOrigins.contains(existing.baseUrl) &&
              (issued.connections.isEmpty ||
                  !_sameEndpointAuthority(existing.baseUrl, origin)))
            existing,
      ];
      if (generation != _generation) return;
      await _store.saveAll(committedProfiles);
      if (generation != _generation) {
        await _store.saveAll(existingConfigs);
        return;
      }
      if (wingLinkOrigin != null) {
        await _acknowledgeWingLinkCredential(
          origin: wingLinkOrigin,
          token: issued.wingLinkToken,
          credentialId: issued.wingLinkCredentialId,
          hostFingerprint: wingLinkHostFingerprint,
        );
        // Once acknowledgment succeeds, always remove the pending marker even
        // if the screen was dismissed while the request was in flight. The
        // control credential may already be active server-side, so returning
        // here would strand a locally pending record and mislead recovery.
        await _store.saveAll([
          for (final profile in committedProfiles)
            committedIds.contains(profile.id)
                ? HermesEndpointConfig(
                    id: profile.id,
                    baseUrl: profile.baseUrl,
                    apiKey: profile.apiKey,
                    label: profile.label,
                    wingLinkOrigin: profile.wingLinkOrigin,
                    wingLinkToken: profile.wingLinkToken,
                    wingLinkHostFingerprint: profile.wingLinkHostFingerprint,
                    wingLinkDeviceId: profile.wingLinkDeviceId,
                  )
                : profile,
        ]);
      }
      if (generation != _generation) return;
      _connectedProfileCount = configs.length;
      final confirmedHost = _origin?.host.toLowerCase();
      _confirmedLoopback =
          confirmedHost == '127.0.0.1' || confirmedHost == '::1';
      _origin = null;
      _exchangeOrigin = null;
      _wingLinkOrigin = null;
      _wingLinkHostFingerprint = null;
      _code = null;
      _setStatus(HermesEnrollmentStatus.confirmed);
      _notify();
      importedGatewayId = configs.first.id!;
    } catch (_) {
      if (generation != _generation) return;
      _connectedProfileCount = null;
      _setStatus(HermesEnrollmentStatus.exchangeFailed);
      _errorMessage = null;
      _notify();
      return;
    }

    try {
      await _connectSavedEndpoint?.call(importedGatewayId);
    } catch (_) {
      // Persistence and Wing Link acknowledgment are already committed.
      // Activating the imported endpoint is a best-effort follow-up.
    }
  }

  /// Discards the pending code without contacting the exchange endpoint.
  void cancel() {
    _generation++;
    _origin = null;
    _exchangeOrigin = null;
    _wingLinkOrigin = null;
    _code = null;
    _preview = null;
    _errorMessage = null;
    _exchangeAttempted = false;
    _connectedProfileCount = null;
    _confirmedLoopback = false;
    _setStatus(HermesEnrollmentStatus.idle);
    _notify();
  }

  /// Clears a completed enrollment outcome without retaining credentials or
  /// profile-bundle state for a later visit.
  void clearConfirmed() {
    if (_status != HermesEnrollmentStatus.confirmed) return;
    cancel();
  }
}
