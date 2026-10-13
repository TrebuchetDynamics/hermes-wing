import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/client/hermes_api_client.dart';
import 'package:wing/core/hermes/shared/hermes_api_http.dart';
import 'package:wing/features/hermes_chat/widgets/connection_check_panel.dart';
import 'package:wing/l10n/app_localizations.dart';

class Denied implements HermesApiStatusException {
  @override
  int get statusCode => 401;
}

void main() {
  final button = find.byKey(const ValueKey('connection-check-button'));
  Future<void> mount(
    WidgetTester tester,
    Future<String> Function() read, {
    TextEditingController? url,
    bool Function()? owns,
    bool browser = false,
  }) async {
    url ??= TextEditingController(text: 'https://agent.example.invalid/p/demo');
    final token = TextEditingController(text: 'synthetic-input');
    addTearDown(url.dispose);
    addTearDown(token.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConnectionCheckPanel(
              url: url,
              token: token,
              enabled: true,
              ownsIntent: owns ?? () => true,
              confirmCleartext: (_) async => false,
              browserOrigin: browser ? 'http://127.0.0.1:8767' : null,
              clientBuilder: (config) => HermesApiClient(
                config: config,
                get: (uri, _) async {
                  expect(uri.path, '/p/demo/v1/capabilities');
                  return read();
                },
                post: (_, _, _) async =>
                    throw StateError('Unexpected mutation'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(button);
  }

  const document =
      '{"object":"hermes.api_server.capabilities","platform":"hermes-agent","schema_version":1}';
  testWidgets('explicit single-flight discovery never claims generation', (
    tester,
  ) async {
    final pending = Completer<String>();
    var reads = 0;
    await mount(tester, () {
      reads++;
      return pending.future;
    });
    expect(reads, 0);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    expect(reads, 1);
    pending.complete(document);
    await tester.pumpAndSettle();
    expect(find.textContaining('Discovery verified'), findsOneWidget);
    expect(find.textContaining('not advertise a supported'), findsOneWidget);
    expect(find.textContaining('does not save'), findsOneWidget);
  });
  testWidgets('edited draft rejects late result and overlapping read', (
    tester,
  ) async {
    final pending = Completer<String>();
    var reads = 0;
    final url = TextEditingController(
      text: 'https://agent.example.invalid/p/demo',
    );
    await mount(tester, () {
      reads++;
      return pending.future;
    }, url: url);
    await tester.tap(button);
    await tester.pump();
    url.text = 'https://other.example.invalid';
    await tester.pump();
    await tester.tap(button);
    expect(reads, 1);
    pending.complete(document);
    await tester.pumpAndSettle();
    expect(find.textContaining('Discovery verified'), findsNothing);
  });
  testWidgets('owner loss rejects result and ends progress', (tester) async {
    final pending = Completer<String>();
    var owner = true;
    await mount(tester, () => pending.future, owns: () => owner);
    await tester.tap(button);
    await tester.pump();
    owner = false;
    pending.complete(document);
    await tester.pumpAndSettle();
    expect(find.textContaining('Discovery verified'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
  testWidgets('focus selection changes preserve pending discovery', (
    tester,
  ) async {
    final pending = Completer<String>();
    final url = TextEditingController(
      text: 'https://agent.example.invalid/p/demo',
    );
    await mount(tester, () => pending.future, url: url);
    await tester.tap(button);
    await tester.pump();
    url.selection = const TextSelection.collapsed(offset: 0);
    pending.complete(document);
    await tester.pumpAndSettle();
    expect(find.textContaining('Discovery verified'), findsOneWidget);
  });
  testWidgets('browser failure is inconclusive with exact origin', (
    tester,
  ) async {
    await mount(
      tester,
      () async => throw const HermesApiTransportException(
        HermesApiTransportFailureKind.network,
      ),
      browser: true,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('CORS'), findsWidgets);
    expect(find.textContaining('http://127.0.0.1:8767'), findsOneWidget);
    expect(find.textContaining('Authentication rejected'), findsNothing);
  });
  testWidgets('HTTP denial is separate from network failure', (tester) async {
    await mount(tester, () async => throw Denied());
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('Authentication rejected'), findsOneWidget);
  });
}
