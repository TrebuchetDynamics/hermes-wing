import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/models/hermes_chat_turn.dart';
import 'package:wing/features/settings/providers/chat_preferences_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import '../support/fake_hermes_channel.dart';
import 'hermes_chat_window_test.dart' show open;

void main() {
  testWidgets('technical tool results stay explicit bounded and owner scoped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.view.physicalSize = const Size(1280, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final channel = FakeHermesChannel();
    addTearDown(channel.dispose);
    HermesChatTurn tool(
      String id,
      String? result, {
      String status = 'running',
      String session = 'sess_1',
      DateTime? createdAt,
      String name = 'hidden_tool_name',
    }) => HermesChatTurn(
      id: id,
      sessionId: session,
      author: HermesTurnAuthor.system,
      createdAt: createdAt ?? DateTime.utc(2026),
      kind: HermesTurnKind.toolCall,
      toolCall: HermesToolCall(
        name: name,
        preview: 'hidden_command_preview',
        status: status,
        result: result,
      ),
    );
    final disclosure = find.byKey(const ValueKey('hermes-tool-payload-tool'));
    final painted = find.byKey(const ValueKey('hermes-tool-result-tool'));
    String output() => tester.widget<Text>(painted).data!;
    Future<void> update(String? result, {String status = 'running'}) async {
      channel.replaceTranscript([tool('tool', result, status: status)]);
      await tester.pumpAndSettle();
    }

    await update('Loaded neutral result');
    await open(tester, channel, scale: 2);
    expect(find.text('Tool payload'), findsNothing);
    final context = tester.element(find.byType(HermesChatScreen));
    final container = ProviderScope.containerOf(context);
    final preferences = container.read(wingChatPreferencesProvider.notifier);
    final composer = find.byType(TextField).last;
    final editing = tester.widget<TextField>(composer).controller!;
    const draft = TextEditingValue(
      text: 'Selected composing draft',
      selection: TextSelection(baseOffset: 2, extentOffset: 9),
      composing: TextRange(start: 2, end: 9),
    );
    await tester.tap(composer);
    editing.value = draft;
    await tester.pump();
    final composerFocus = FocusManager.instance.primaryFocus;
    final screenState = tester.state(find.byType(HermesChatScreen));
    final list = find.byKey(const ValueKey('hermes-transcript'));
    final scroll = tester.widget<ListView>(list).controller!;
    final beforeScroll = scroll.offset;
    preferences.setToolDisplay(WingToolDisplay.technical);
    await tester.pumpAndSettle();
    expect(disclosure, findsOneWidget);
    expect(painted, findsNothing);
    expect(tester.state(find.byType(HermesChatScreen)), same(screenState));
    expect(tester.widget<TextField>(composer).controller, same(editing));
    expect(editing.value, draft);
    expect(scroll.offset, beforeScroll);
    expect(FocusManager.instance.primaryFocus, same(composerFocus));
    // Deliberately leave the editor to inspect payloads; IME composition ends
    // on blur, unlike a preference rebuild while the editor remains focused.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    final inspectedDraft = editing.value;
    await tester.ensureVisible(disclosure);
    final node = tester.getSemantics(disclosure);
    expect(node.getSemanticsData().label, contains('Tool payload'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.binding.performSemanticsAction(
      SemanticsActionEvent(
        viewId: tester.view.viewId,
        nodeId: node.id,
        type: SemanticsAction.tap,
      ),
    );
    await tester.pumpAndSettle();
    expect(output(), 'Loaded neutral result');
    expect(find.text('Result'), findsOneWidget);
    expect(find.textContaining('Arguments'), findsNothing);
    expect(find.textContaining('hidden_tool_name'), findsNothing);
    expect(find.textContaining('hidden_command_preview'), findsNothing);
    expect(find.byType(SelectableText), findsNothing);
    for (final action in ['Copy as text', 'Copy as Markdown']) {
      await tester.tap(
        find.byKey(const ValueKey('hermes-copy-transcript-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      expect(clipboard, isNotNull);
      expect(clipboard, isNot(contains('Loaded neutral result')));
      expect(clipboard, isNot(contains('hidden_tool_name')));
      expect(clipboard, isNot(contains('hidden_command_preview')));
    }
    // The mounted sanitizer must reject before decoding and bound total paint.
    final rejected = <String>[
      '{malformed',
      '[malformed',
      '{"result":1e999}',
      '{"result":-1e999}',
      '${List.filled(17, '[').join()}0${List.filled(17, ']').join()}',
      jsonEncode(List.filled(1000, 0)),
    ];
    for (final source in rejected) {
      await update(source);
      expect(output(), 'No loaded result available for safe display.');
    }
    await update(List.filled(65537, 'x').join());
    expect(output(), 'Loaded result is too large for safe display.');
    await update(List.filled(65536, 'x').join());
    expect(output().length, 20000);
    expect(output(), endsWith('… [Result truncated]'));
    await update(List.filled(20000, 'x').join());
    expect(output().length, 20000);
    expect(output(), isNot(contains('truncated')));
    await update(
      '${List.filled(16, '[').join()}0${List.filled(16, ']').join()}',
    );
    expect(output(), contains('0'));
    await update(jsonEncode(List.filled(999, 0)));
    expect(output(), isNot(contains('No loaded result')));
    await update(
      jsonEncode({
        'visible': 'neutral value',
        'nested': {
          'API_Key': 'credential-sentinel',
          'AUTH-token': 'auth-sentinel',
          'password': 'password-sentinel',
          'Cookie': 'cookie-sentinel',
          'result': 'token=scalar-sentinel',
          'encoded': '{"password":"encoded-sentinel"}',
          'obfuscated': 'to\u0000ken=control-sentinel',
        },
        'paths': [
          '/home/example/private',
          'C:\\Example\\private',
          '/unusual/private',
          'path=[/other/private]',
        ],
        'locations': [
          'https://example.invalid/payload',
          'urn:example:payload',
          '192.168.20.4',
          '::1',
          'fc00::42',
          '//internal.example/private',
        ],
      }),
    );
    for (final forbidden in [
      'credential-sentinel',
      'auth-sentinel',
      'password-sentinel',
      'cookie-sentinel',
      'scalar-sentinel',
      'encoded-sentinel',
      'control-sentinel',
      '/other/private',
      'internal.example',
      '/home/example',
      'Example',
      '/unusual/private',
      'https:',
      'urn:',
      '192.168.',
      '::1',
      'fc00',
    ]) {
      expect(output(), isNot(contains(forbidden)), reason: forbidden);
    }
    expect(output(), contains('"visible": "neutral value"'));
    for (final path in [
      '/home/example/private folder/path-suffix.txt',
      'C:\\Example\\private folder\\path-suffix.txt',
      '/unusual/private folder/path-suffix.txt',
      '`/unusual/private folder/path-suffix.txt`',
    ]) {
      for (final payload in [
        path,
        jsonEncode({'result': path}),
      ]) {
        await update(payload);
        expect(output(), isNot(contains('folder')));
        expect(output(), isNot(contains('path-suffix')));
      }
    }
    // Credential values are not whitespace-delimited: quoted/escaped suffixes
    // must never reach paint, whether plain, a JSON scalar or a nested leaf.
    for (final source in [
      'password="prefix sensitive-suffix"',
      "password='prefix sensitive-suffix'",
      'PASSWORD = "prefix \\" sensitive-suffix"',
      'api_key="prefix\nsensitive-suffix"',
      'token=`prefix sensitive-suffix`',
      'auth-token: "prefix sensitive-suffix"',
      'Cookie="prefix sensitive-suffix"',
      'Bearer "prefix sensitive-suffix"',
      "Basic 'prefix sensitive-suffix'",
    ]) {
      for (final payload in [
        source,
        jsonEncode(source),
        jsonEncode({'visible': 'neutral value', 'result': source}),
      ]) {
        await update(payload);
        expect(output(), isNot(contains('prefix')));
        expect(output(), isNot(contains('sensitive-suffix')));
      }
    }
    await update(
      'Bearer scalar-sentinel https://example.invalid 10.0.0.1 /home/example/private \u001b[31mneutral',
    );
    expect(output(), isNot(contains('scalar-sentinel')));
    expect(output(), isNot(contains('\u001b')));
    for (final status in ['completed', 'failed']) {
      await update('Terminal neutral result', status: status);
      expect(output(), 'Terminal neutral result');
    }
    await update(null);
    expect(output(), 'No loaded result available for safe display.');
    expect(find.text('Result'), findsNothing);
    await update('   ');
    expect(output(), 'No loaded result available for safe display.');
    // Collapsing clears derived content; a fresh keyboard open uses current data.
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    await update('Fresh neutral result');
    expect(painted, findsNothing);
    FocusManager.instance.primaryFocus?.unfocus();
    var reached = false;
    for (var i = 0; i < 100; i++) {
      FocusManager.instance.primaryFocus?.context?.visitAncestorElements((e) {
        reached = e.widget.key == const ValueKey('hermes-tool-payload-tool');
        return !reached;
      });
      if (reached) break;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(reached, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(output(), 'Fresh neutral result');
    expect(tester.widget<TextField>(composer).controller, same(editing));
    expect(editing.value, inspectedDraft);
    // Same-owner direct ID reuse must not inherit consent or focused controls.
    channel.replaceTranscript([
      tool(
        'tool',
        'Replacement timestamp result',
        createdAt: DateTime.utc(2026, 2),
      ),
    ]);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    channel.replaceTranscript([
      tool(
        'tool',
        'Replacement tool result',
        createdAt: DateTime.utc(2026, 2),
        name: 'another_hidden_tool',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    // Product and ambiguous or removed identities must destroy disclosure intent.
    preferences.setToolDisplay(WingToolDisplay.product);
    await tester.pumpAndSettle();
    preferences.setToolDisplay(WingToolDisplay.technical);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    channel.replaceTranscript([
      tool('tool', 'first'),
      tool('tool', 'second'),
      tool(' ', 'blank'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Tool payload'), findsNothing);
    await update('Reused neutral result');
    expect(painted, findsNothing);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(editing.value, inspectedDraft);
    await channel.connect(baseUrl: 'http://127.0.0.1:12345');
    await update('Other owner result');
    expect(painted, findsNothing);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    channel.replaceTranscript([]);
    await tester.pumpAndSettle();
    await update('Returned result');
    expect(painted, findsNothing);
    final ownerDraft = editing.value;
    // Compact grouped activity retains safe categories and explicit per-step payloads.
    tester.view.physicalSize = const Size(390, 1800);
    channel.replaceTranscript([
      tool('tool', 'Grouped result', status: 'completed'),
      tool('missing', null, status: 'failed'),
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(output(), 'Grouped result');
    final missing = find.byKey(const ValueKey('hermes-tool-payload-missing'));
    await tester.ensureVisible(missing);
    await tester.tap(missing);
    await tester.pumpAndSettle();
    expect(
      find.text('No loaded result available for safe display.'),
      findsOneWidget,
    );
    for (final width in [1280.0, 390.0]) {
      tester.view.physicalSize = Size(width, 1800);
      channel.replaceTranscript([
        tool('tool', 'Updated grouped result', status: 'failed'),
        tool('missing', 'Completed grouped result', status: 'completed'),
        HermesChatTurn(
          id: 'delta',
          sessionId: 'sess_1',
          author: HermesTurnAuthor.assistant,
          createdAt: DateTime.utc(2026),
          text: 'Unrelated streaming delta',
          status: HermesTurnStatus.streaming,
        ),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(output(), 'Updated grouped result');
      expect(find.text('Completed grouped result'), findsOneWidget);
      expect(tester.widget<TextField>(composer).controller, same(editing));
      expect(editing.value, ownerDraft);
      channel.replaceTranscript([
        tool('tool', 'Updated grouped result', status: 'failed'),
        tool('missing', 'Completed grouped result', status: 'completed'),
      ]);
      await tester.pumpAndSettle();
    }
    preferences.setToolDisplay(WingToolDisplay.product);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    preferences.setToolDisplay(WingToolDisplay.technical);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    await tester.ensureVisible(disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    // Duplicate IDs invalidate payloads even inside a still-mounted group.
    channel.replaceTranscript([
      tool('tool', 'Duplicate one'),
      tool('tool', 'Duplicate two'),
      tool('missing', null),
    ]);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    channel.replaceTranscript([
      tool('tool', 'Unique again'),
      tool('missing', null),
    ]);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    await tester.ensureVisible(disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    await channel.selectProfile('synthetic-profile');
    channel.replaceTranscript([
      tool('tool', 'Changed profile'),
      tool('missing', null),
    ]);
    await tester.pumpAndSettle();
    expect(painted, findsNothing);
    expect(editing.value.text, isEmpty);
    // A turn claiming another session can never disclose its result.
    channel.replaceTranscript([
      tool('tool', 'Foreign session', session: 'other'),
      tool('missing', null),
    ]);
    await tester.pumpAndSettle();
    expect(disclosure, findsNothing);
    expect(find.text('Foreign session'), findsNothing);
    expect(channel.loadEarlierMessagesCalls, 0);
    expect(channel.sentVoiceTranscripts, isEmpty);
    expect(channel.stopActiveTurnCalls, 0);
    expect(channel.respondToApprovalCalls, isEmpty);
    expect(channel.selectProfileCalls, ['synthetic-profile']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    expect(find.text('Tool payload'), findsNothing);
    semantics.dispose();
  });
}
