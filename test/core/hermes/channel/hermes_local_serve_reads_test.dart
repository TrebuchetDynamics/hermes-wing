import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:wing/core/hermes/channel/hermes_api_channel.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';

import '../../../../integration_test/support/local_serve_read_fixture.dart';

void main() {
  late LocalServeReadFixture fixture;
  late HermesApiChannel channel;
  setUp(() async {
    fixture = LocalServeReadFixture();
    addTearDown(() => fixture.close());
    await fixture.start();
    channel = HermesApiChannel();
    addTearDown(() => channel.dispose());
  });
  Future<void> connect({
    String token = LocalServeReadFixture.token,
    bool Function()? canAccept,
  }) => channel.connectLocalServeReads(
    baseUrl: fixture.origin,
    credential: token,
    canAccept: canAccept,
  );

  test(
    'fixed REST reads compose profiles and history without granting mutations',
    () async {
      await connect();
      expect(channel.state.isConnected, isTrue);
      expect(channel.state.isServeReadOnly, isTrue);
      expect(channel.state.selectedProfileId, 'default');
      expect(channel.state.activeSessionId, 'default-session');
      expect(channel.state.activeMessages.map((m) => m.text), [
        'default fixture question',
        'default fixture answer',
      ]);
      expect(channel.state.capabilities, isNull);
      expect(channel.state.canCreateSessions, isFalse);
      expect(channel.state.canUpdateSessions, isFalse);
      expect(channel.state.canDeleteSessions, isFalse);
      expect(channel.state.canForkSessions, isFalse);
      expect(channel.state.canWriteProviders, isFalse);
      expect(channel.state.canSteerRuns, isFalse);
      await expectLater(channel.createSession(), throwsStateError);
      await expectLater(channel.sendText('not sent'), throwsStateError);
      await expectLater(
        channel.renameSession(
          sessionId: 'default-session',
          title: 'not changed',
        ),
        throwsStateError,
      );
      await channel.selectProfile('demo');
      expect(channel.state.selectedProfileId, 'demo');
      expect(channel.state.activeMessages.last.text, 'demo fixture answer');
      await channel.selectProfile('default');
      expect(channel.state.activeMessages.last.text, 'default fixture answer');
      channel.clearActiveSession();
      await channel.selectSession('default-session');
      expect(channel.state.activeSessionId, 'default-session');
      expect(fixture.requests.every((r) => r.startsWith('GET ')), isTrue);
      expect(fixture.requests, isNot(contains('GET /api/capabilities')));
    },
  );

  test(
    'paged export lease rejects selection roundtrips and disconnect without changing chat',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(channel.canExportSessionHistory, isFalse);
      await connect();
      expect(channel.canExportSessionHistory, isTrue);
      final original = channel.state.activeMessages;
      final attempt = channel.beginSessionHistoryExport();
      final json = jsonDecode(await attempt.collect()) as Map;
      expect(json['session_id'], 'default-session');
      expect(json['message_count'], 2);
      expect(channel.state.activeMessages, original);
      expect(
        fixture.requests.last,
        'GET /api/sessions/default-session/messages',
      );
      await channel.selectSession('default-session');
      expect(
        attempt.isCurrent,
        isFalse,
        reason: 'Generation, not tuple equality',
      );
      final cancelled = channel.beginSessionHistoryExport();
      cancelled.cancel();
      expect(channel.state.isConnected, isTrue);
      final profileRoundtrip = channel.beginSessionHistoryExport();
      await channel.selectProfile('demo');
      await channel.selectProfile('default');
      expect(profileRoundtrip.isCurrent, isFalse);
      final disconnected = channel.beginSessionHistoryExport();
      await channel.disconnect();
      expect(disconnected.isCurrent, isFalse);
      expect(channel.canExportSessionHistory, isFalse);
    },
  );

  test(
    'denied auth and missing read operation fail closed; retry is explicit',
    () async {
      await connect(token: 'synthetic-denied');
      expect(
        channel.state.connectionFailureKind,
        HermesConnectionFailureKind.authentication,
      );
      expect(fixture.requests.length, 1);
      fixture.unsupported = true;
      await connect();
      expect(
        channel.state.connectionFailureKind,
        HermesConnectionFailureKind.incompatibleResponse,
      );
      expect(fixture.requests.length, 2);
      fixture.unsupported = false;
      await connect();
      expect(channel.state.isConnected, isTrue);
      expect(fixture.requests.length, 5);
    },
  );

  test(
    'cancel and late owner result cannot replace newer connection',
    () async {
      fixture.holdProfiles = Completer<void>();
      fixture.profilesRequested = Completer<void>();
      var admitted = true;
      final first = connect(canAccept: () => admitted);
      await fixture.profilesRequested!.future;
      admitted = false;
      await channel.disconnect();
      fixture.holdProfiles!.complete();
      await first;
      expect(channel.state.status, HermesConnectionStatus.disconnected);
      fixture.holdProfiles = null;
      await connect();
      expect(channel.state.isConnected, isTrue);
      expect(fixture.requests.length, 4);
    },
  );

  test('late first connection cannot replace a newer serve owner', () async {
    final replacement = LocalServeReadFixture();
    await replacement.start();
    addTearDown(replacement.close);
    fixture.holdProfiles = Completer<void>();
    fixture.profilesRequested = Completer<void>();
    final first = connect();
    await fixture.profilesRequested!.future;
    await channel.connectLocalServeReads(
      baseUrl: replacement.origin,
      credential: LocalServeReadFixture.token,
    );
    fixture.holdProfiles!.complete();
    await first;
    expect(channel.state.connectedBaseUrl, replacement.origin);
    expect(channel.state.isConnected, isTrue);
    expect(fixture.requests.length, 1);
    expect(replacement.requests.length, 3);
  });

  test('invalid credential and non-loopback origin make no requests', () async {
    await connect(token: '');
    expect(
      channel.state.connectionFailureKind,
      HermesConnectionFailureKind.authentication,
    );
    await channel.connectLocalServeReads(
      baseUrl: 'http://example.invalid',
      credential: LocalServeReadFixture.token,
    );
    expect(
      channel.state.connectionFailureKind,
      HermesConnectionFailureKind.invalidEndpoint,
    );
    expect(fixture.requests, isEmpty);
  });
}
