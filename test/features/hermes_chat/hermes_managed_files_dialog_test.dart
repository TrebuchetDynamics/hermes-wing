import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/providers/hermes_channel_provider.dart';
import 'package:wing/features/hermes_chat/screens/hermes_chat_screen.dart';
import 'package:wing/core/hermes/client/hermes_managed_files.dart';
import 'package:wing/features/hermes_chat/files/hermes_managed_files_dialog.dart';
import 'package:wing/l10n/app_localizations.dart';

import 'support/fake_hermes_channel.dart';

class FilesChannel extends FakeHermesChannel
    implements HermesManagedFilesChannel {
  int generation = 0, requests = 0;
  Future<Map<String, dynamic>> Function(String, Map<String, String>)? reply;
  void invalidate() {
    generation++;
    notifyListeners();
  }

  @override
  bool get canBrowseManagedFiles => true;
  @override
  HermesManagedFilesSession beginManagedFiles() {
    final owner = generation;
    return HermesManagedFilesSession(
      isCurrent: () => owner == generation,
      request: (route, query, _) async {
        requests++;
        return reply!(route, query);
      },
    );
  }
}

const policy = {
  'root': '/managed',
  'locked_root': '/managed',
  'can_change_path': false,
};
Map<String, dynamic> listing({
  List<Object?> entries = const [],
  String path = '/managed',
  String? parent,
}) => {...policy, 'path': path, 'parent': parent, 'entries': entries};
const note = {
  'name': 'note.html',
  'path': '/managed/note.html',
  'is_directory': false,
  'size': 12,
};

Future<void> open(WidgetTester tester, FakeHermesChannel channel) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => HermesManagedFilesDialog(channel: channel),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pump();
}

void main() {
  testWidgets(
    'Chat exposes Files at compact/wide widths without changing conversation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 1;
      addTearDown(() => tester.binding.setSurfaceSize(null));
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [390.0, 1280.0]) {
        // Constraints can be narrower than MediaQuery (e.g. an embedded pane).
        await tester.binding.setSurfaceSize(Size(width, 1000));
        final channel = FakeHermesChannel();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [hermesChannelProvider.overrideWithValue(channel)],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HermesChatScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final owner = channel.state.activeSessionId;
        if (width < 600) {
          await tester.tap(
            find.byKey(const ValueKey('hermes-more-actions-button')),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Files'));
        } else {
          await tester.tap(find.byKey(const ValueKey('hermes-files-button')));
        }
        await tester.pumpAndSettle();
        expect(find.byType(HermesManagedFilesDialog), findsOneWidget);
        expect(channel.state.activeSessionId, owner);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(HermesManagedFilesDialog), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        channel.dispose();
      }
    },
  );

  testWidgets(
    'Files action cannot adopt an owner changed before the first dialog frame',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final replaceConnection in [false, true]) {
        final original = FilesChannel()..reply = (_, _) async => listing();
        final replacement = FilesChannel()..reply = (_, _) async => listing();
        final container = ProviderContainer(
          overrides: [hermesChannelProvider.overrideWithValue(original)],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HermesChatScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('hermes-files-button')),
            )
            .onPressed!();
        if (replaceConnection) {
          container.updateOverrides([
            hermesChannelProvider.overrideWithValue(replacement),
          ]);
        } else {
          original.invalidate();
        }
        await tester.pumpAndSettle();
        expect(original.requests + replacement.requests, 0);
        expect(
          find.text(
            'The connection or conversation changed. Retry to read the current Agent’s managed root.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(original.requests + replacement.requests, 1);
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        original.dispose();
        replacement.dispose();
      }
    },
  );

  testWidgets(
    'touch/keyboard managed Files shows loading, denied retry, folder, literal preview and empty state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final channel = FilesChannel();
      addTearDown(channel.dispose);
      final gate = Completer<Map<String, dynamic>>();
      channel.reply = (_, _) => gate.future;
      await open(tester, channel);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.completeError(
        const HermesManagedFilesException(HermesManagedFilesFailure.denied),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'File access denied. Check this Agent connection’s file permissions.',
        ),
        findsOneWidget,
      );
      channel.reply = (route, query) async {
        if (route.endsWith('/read')) {
          return {
            ...policy,
            'path': note['path'],
            'name': note['name'],
            'size': 12,
            'mime_type': 'text/html',
            'data_url':
                'data:text/html;base64,${base64Encode(utf8.encode('<b>plain</b>'))}',
          };
        }
        if (query['path'] == '/managed/folder') {
          return listing(path: '/managed/folder', parent: '/managed');
        }
        return listing(
          entries: [
            note,
            {
              'name': 'folder',
              'path': '/managed/folder',
              'is_directory': true,
              'size': null,
            },
          ],
        );
      };
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('/managed'), findsWidgets);
      await tester.tap(find.text('note.html'));
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is SelectableText && w.data == '<b>plain</b>',
        ),
        findsOneWidget,
      );
      final back = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (w) => w is IconButton && w.tooltip == 'Back to files',
        ),
      );
      back.focusNode?.requestFocus();
      await tester.tap(find.byTooltip('Back to files'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('folder'));
      await tester.pumpAndSettle();
      expect(find.text('This folder is empty.'), findsOneWidget);
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Parent folder',
            ),
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('note.html'), findsOneWidget);
      expect(channel.requests, 5);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'owner change clears in-flight data and requires explicit new read',
    (tester) async {
      final channel = FilesChannel();
      addTearDown(channel.dispose);
      channel.reply = (_, _) async => listing(entries: [note]);
      await open(tester, channel);
      await tester.pumpAndSettle();
      final cachedOpen = tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'note.html'))
          .onTap!;
      final gate = Completer<Map<String, dynamic>>();
      channel.reply = (_, _) => gate.future;
      await tester.tap(find.text('note.html'));
      await tester.pump();
      channel.invalidate();
      gate.complete({
        ...policy,
        'path': note['path'],
        'name': note['name'],
        'size': 6,
        'mime_type': 'text/plain',
        'data_url': 'data:text/plain;base64,c2VjcmV0',
      });
      await tester.pumpAndSettle();
      expect(find.text('note.html'), findsNothing);
      expect(
        find.text(
          'The connection or conversation changed. Retry to read the current Agent’s managed root.',
        ),
        findsOneWidget,
      );
      expect(find.text('secret'), findsNothing);
      expect(channel.requests, 2);
      channel.reply = (_, _) async => listing();
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('This folder is empty.'), findsOneWidget);
      expect(channel.requests, 3);
      cachedOpen();
      await tester.pumpAndSettle();
      expect(channel.requests, 3);
      expect(find.text('This folder is empty.'), findsOneWidget);
    },
  );

  testWidgets(
    'messaging-only and unlocked connections show unavailable without browse controls',
    (tester) async {
      final messaging = FakeHermesChannel();
      addTearDown(messaging.dispose);
      await open(tester, messaging);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Files require an authenticated Agent serve connection with an advertised locked managed root. No terminal or Project folder is substituted.',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Parent folder'), findsNothing);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      final channel = FilesChannel();
      addTearDown(channel.dispose);
      channel.reply = (_, _) async => {
        ...listing(entries: [note]),
        'root': null,
        'locked_root': null,
        'can_change_path': true,
      };
      await open(tester, channel);
      await tester.pumpAndSettle();
      expect(find.text('note.html'), findsNothing);
      expect(
        find.text(
          'Files require an authenticated Agent serve connection with an advertised locked managed root. No terminal or Project folder is substituted.',
        ),
        findsOneWidget,
      );
    },
  );
}
