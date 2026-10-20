import 'hermes_session_history_export.dart';
import '../models/hermes_profile.dart';
import '../models/hermes_web_reads.dart';

export '../models/hermes_web_reads.dart';

/// Local serve reads have no browser authentication/transport qualification.
final class HermesWebReadClient {
  HermesWebReadClient.forLocalReads({
    required Uri origin,
    required String credential,
    required String profile,
  }) {
    throw UnsupportedError('Local serve reads require native transport.');
  }

  HermesSessionHistoryExportAttempt beginHistoryExport(
    String session, {
    required String? title,
    required bool Function() isCurrent,
  }) => throw UnsupportedError('Local serve export unavailable.');

  Future<HermesServeLifecycle?> prepareBotChat({
    required bool knownCanonical,
    required bool allowCreate,
    required String idempotencyKey,
    required bool Function() canAccept,
  }) => throw UnsupportedError('Canonical Bot Chat requires native transport.');

  void adoptPreparedBotChat() =>
      throw UnsupportedError('Canonical Bot Chat requires native transport.');

  void disconnect() {}
  void closeLifecycle() {}
  Future<HermesServeLifecycle> connectLifecycleForProduct() =>
      throw UnsupportedError('Local serve chat requires native transport.');
  HermesWebReadClient forProfile(String profile) =>
      throw UnsupportedError('Local serve reads unavailable.');
  Future<List<HermesProfile>> profiles() =>
      throw UnsupportedError('Local serve reads unavailable.');
  Future<HermesWebSessionPage> sessions({int limit = 50, int offset = 0}) =>
      throw UnsupportedError('Local serve reads unavailable.');
  Future<HermesWebHistoryPage> history(
    String session, {
    int limit = 500,
    int offset = 0,
    String order = 'latest',
  }) => throw UnsupportedError('Local serve reads unavailable.');
}
