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

  void disconnect() {}
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
