import 'dart:async';
import 'dart:convert';

import '../models/hermes_web_reads.dart';

const hermesSessionHistoryExportByteLimit = 4 * 1024 * 1024;

/// One explicit preparation, never cached or resumed after failure. Cancelling
/// retires this lease only, not the shared authenticated reader or chat socket.
final class HermesSessionHistoryExportAttempt {
  HermesSessionHistoryExportAttempt({
    required this.sessionId,
    required this.title,
    required bool Function() isCurrent,
    required Future<HermesWebRawHistoryPage> Function(int offset) readPage,
  }) : _owns = isCurrent,
       // Public injection retains a private fixed-page reader.
       // ignore: prefer_initializing_formals
       _readPage = readPage;

  final String sessionId;
  final String? title;
  final bool Function() _owns;
  final Future<HermesWebRawHistoryPage> Function(int) _readPage;
  final _cancelled = Completer<void>();
  bool _started = false;
  final _clock = Stopwatch();
  bool get isCurrent => !_cancelled.isCompleted && _owns();

  void cancel() {
    if (!_cancelled.isCompleted) _cancelled.complete();
  }

  void _check() {
    if (_clock.elapsed >= const Duration(seconds: 60)) {
      throw const HermesWebReadException(HermesWebFailureKind.timeout);
    }
    if (!isCurrent) {
      throw const HermesWebReadException(HermesWebFailureKind.stale);
    }
  }

  Future<String> collect({void Function(int count)? onProgress}) async {
    if (_started) throw StateError('Export preparation already started.');
    _started = true;
    _clock.start();
    try {
      return await Future.any([
        _collect(onProgress).timeout(
          const Duration(seconds: 60),
          onTimeout: () =>
              throw const HermesWebReadException(HermesWebFailureKind.timeout),
        ),
        _cancelled.future.then<String>(
          (_) => throw const HermesWebReadException(HermesWebFailureKind.stale),
        ),
      ]);
    } catch (_) {
      cancel();
      rethrow;
    } finally {
      _clock.stop();
    }
  }

  Future<String> _collect(void Function(int)? onProgress) async {
    _check();
    final rows = <String>[];
    final ids = <int>{};
    String? resolved;
    var bytes = 0;
    final exportedAt = DateTime.now().toUtc().toIso8601String();
    onProgress?.call(0);
    while (true) {
      _check();
      final page = await _readPage(rows.length);
      _check();
      resolved ??= page.resolvedSessionId;
      webIdentity(page.resolvedSessionId, resolved);
      for (var i = 0; i < page.encodedMessages.length; i++) {
        if (!ids.add(page.messageIds[i])) webMalformed();
        final row = page.encodedMessages[i];
        bytes += utf8.encode(row).length + (rows.isEmpty ? 0 : 1);
        if (bytes > hermesSessionHistoryExportByteLimit) {
          throw const HermesWebReadException(HermesWebFailureKind.oversized);
        }
        rows.add(row);
      }
      onProgress?.call(rows.length);
      if (page.encodedMessages.length < 500) break;
    }
    final wrapper = jsonEncode({
      'exported_at': exportedAt,
      'session_id': sessionId,
      'title': title,
      'session': null,
      'message_count': rows.length,
    });
    // Include the complete wrapper, punctuation and UTF-8 title in the cap.
    final prefix = '${wrapper.substring(0, wrapper.length - 1)},"messages":[';
    if (utf8.encode(prefix).length + bytes + 2 >
        hermesSessionHistoryExportByteLimit) {
      throw const HermesWebReadException(HermesWebFailureKind.oversized);
    }
    _check();
    return '$prefix${rows.join(',')}]}';
  }
}
