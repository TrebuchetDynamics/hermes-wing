import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/hermes/client/hermes_api_client.dart';
import '../../../core/hermes/client/hermes_api_config.dart';
import '../../../core/hermes/setup/hermes_endpoint_store.dart';
import '../../hermes_chat/providers/hermes_channel_provider.dart';
import '../models/hermes_enrollment_payload.dart';
import '../services/hermes_connect_intent_source.dart';

/// Reads the pending Hermes Wing connect pairing payload from the platform's
/// intent ingress; see [HermesConnectIntentSource].
final hermesConnectIntentSourceProvider = Provider<HermesConnectIntentSource>(
  (ref) => const MethodChannelHermesConnectIntentSource(),
);

/// Owns the `HermesEnrollmentController` for the current `/enroll` visit.
/// Wires the real unauthenticated inspect/exchange requests and the real
/// secure endpoint store; overridden in tests with fakes.
final hermesEnrollmentControllerProvider =
    ChangeNotifierProvider.autoDispose<HermesEnrollmentController>((ref) {
      final store = ref.watch(hermesEndpointStoreProvider);
      final channel = ref.watch(hermesChannelProvider);
      return HermesEnrollmentController(
        inspectEnrollment: ({required origin, required code}) =>
            HermesApiClient(
              config: HermesApiConfig.fromBaseUrl(origin.toString()),
            ).inspectEnrollment(origin: origin, code: code),
        exchangeEnrollment: ({required origin, required code}) =>
            HermesApiClient(
              config: HermesApiConfig.fromBaseUrl(origin.toString()),
            ).exchangeEnrollment(origin: origin, code: code),
        endpointStore: store,
        connectSavedEndpoint: () => hermesAutoConnect(channel, store),
      );
    });

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

/// Reconnects the shared Hermes channel to the endpoint just saved by a
/// successful enrollment, so `/hermes` lands connected rather than idle.
typedef HermesEnrollmentConnect = Future<void> Function();

enum HermesEnrollmentStatus {
  idle,
  inspecting,
  ready,
  confirming,
  confirmed,
  failed,
}

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
    this._connectSavedEndpoint,
  }) : _inspect = inspectEnrollment,
       _exchange = exchangeEnrollment,
       _store = endpointStore;

  final HermesEnrollmentInspect _inspect;
  final HermesEnrollmentExchange _exchange;
  final HermesEndpointStore _store;
  final HermesEnrollmentConnect? _connectSavedEndpoint;

  HermesEnrollmentStatus _status = HermesEnrollmentStatus.idle;
  HermesEnrollmentPreview? _preview;
  String? _errorMessage;
  Uri? _origin;
  String? _code;
  bool _exchangeAttempted = false;
  int _generation = 0;

  bool _disposed = false;

  HermesEnrollmentStatus get status => _status;
  HermesEnrollmentPreview? get preview => _preview;
  String? get errorMessage => _errorMessage;

  /// The origin from the pairing payload — the value that will actually be
  /// saved and connected. The review screen must display this, never the
  /// server-echoed `preview.origin`, so the operator consents to the host
  /// they will really talk to.
  Uri? get origin => _origin;

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Requests server-side inspection of [payload]. Never itself exchanges
  /// the code; only [confirm] does that, and only once.
  Future<void> inspect(HermesEnrollmentPayload payload) async {
    final generation = ++_generation;
    _origin = payload.origin;
    _code = payload.code;
    _exchangeAttempted = false;
    _preview = null;
    _errorMessage = null;
    _status = HermesEnrollmentStatus.inspecting;
    _notify();
    try {
      final preview = await _inspect(
        origin: payload.origin,
        code: payload.code,
      );
      if (generation != _generation) return;
      _preview = preview;
      _status = HermesEnrollmentStatus.ready;
    } catch (_) {
      if (generation != _generation) return;
      _status = HermesEnrollmentStatus.failed;
      _errorMessage =
          'This pairing link could not be verified. It may be expired or '
          'already used.';
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
    final code = _code;
    final preview = _preview;
    if (origin == null || code == null || preview == null) return;
    _exchangeAttempted = true;
    final generation = ++_generation;
    _status = HermesEnrollmentStatus.confirming;
    _notify();
    try {
      final issued = await _exchange(origin: origin, code: code);
      await _store.save(
        baseUrl: origin.toString(),
        apiKey: issued.token,
        label: preview.label,
      );
      if (generation != _generation) return;
      _origin = null;
      _code = null;
      _status = HermesEnrollmentStatus.confirmed;
      _notify();
      await _connectSavedEndpoint?.call();
      return;
    } catch (_) {
      if (generation != _generation) return;
      _status = HermesEnrollmentStatus.failed;
      _errorMessage =
          'Pairing could not be completed. Request a new pairing code and '
          'try again.';
    }
    _notify();
  }

  /// Discards the pending code without contacting the exchange endpoint.
  void cancel() {
    _generation++;
    _origin = null;
    _code = null;
    _preview = null;
    _errorMessage = null;
    _exchangeAttempted = false;
    _status = HermesEnrollmentStatus.idle;
    _notify();
  }
}
