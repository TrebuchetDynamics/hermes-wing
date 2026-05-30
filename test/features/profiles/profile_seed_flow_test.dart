import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/core/channel/navivox_channel_provider.dart';
import 'package:navivox/core/gateway/navivox_gateway_protocol.dart';
import '../../support/test_navivox_channel.dart';
import '../shared/test_router_app.dart';

const _servers = [
  NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
];

void main() {
  testWidgets(
    'create from seed drafts editable fields and applies explicit workspace through Gormes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileSeedResults(
          draft: _draftResult(),
          apply: _appliedResult(workspaceCount: 1),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const TestRouterApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-create-from-seed')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('profile-seed-input')),
        ' work on mineru repo ',
      );
      await tester.tap(find.byKey(const ValueKey('profile-seed-draft-button')));
      await tester.pumpAndSettle();

      _expectProfileSeedCall(
        channel.profileSeedCalls.single,
        seed: 'work on mineru repo',
        apply: false,
        workspaceRoots: const [],
      );
      expect(find.text('generation_source=template'), findsOneWidget);
      expect(
        find.text(
          'Evidence: template_fallback, workspace_confirmation_required',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Profile ID'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Display name'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Instructions'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Provider'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Model'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Tool policy'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Voice metadata'), findsOneWidget);
      expect(find.text('Workspace suggestions'), findsOneWidget);
      expect(find.textContaining('requires confirmation'), findsOneWidget);

      var applyButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('profile-seed-apply-button')),
      );
      expect(applyButton.onPressed, isNull);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-seed-workspace-path')),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-seed-workspace-path')),
        '/work/mineru',
      );
      await tester.pumpAndSettle();
      applyButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('profile-seed-apply-button')),
      );
      expect(applyButton.onPressed, isNotNull);

      await tester.tap(find.byKey(const ValueKey('profile-seed-apply-button')));
      await tester.pumpAndSettle();

      _expectProfileSeedCall(
        channel.profileSeedCalls.last,
        seed: 'work on mineru repo',
        apply: true,
        workspaceRoots: const ['/work/mineru'],
      );
      expect(
        find.byKey(const ValueKey('profile-contact-local-work-mineru-repo')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('profile-contact-local-work-mineru-repo')),
      );
      await tester.pumpAndSettle();

      expect(channel.selectedProfileScope, (
        serverId: 'local',
        profileId: 'work-mineru-repo',
      ));
      expect(find.text('Work Mineru Repo'), findsOneWidget);
    },
  );

  testWidgets(
    'template drafts can be applied after explicit no-workspace confirmation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final channel = TestNavivoxChannel()
        ..seedServers(_servers, activeServerId: 'local')
        ..seedProfileSeedResults(
          draft: _draftResult(),
          apply: _appliedResult(workspaceCount: 0),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [navivoxChannelProvider.overrideWithValue(channel)],
          child: const TestRouterApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Add profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('profile-create-from-seed')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-seed-input')),
        'work on mineru repo',
      );
      await tester.tap(find.byKey(const ValueKey('profile-seed-draft-button')));
      await tester.pumpAndSettle();

      expect(find.text('Provider status: unconfigured'), findsOneWidget);
      expect(find.text('generation_source=template'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-seed-no-workspace-confirmation')),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(
        find.byKey(const ValueKey('profile-seed-no-workspace-confirmation')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('profile-seed-apply-button')),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('profile-seed-apply-button')));
      await tester.pumpAndSettle();

      _expectProfileSeedCall(
        channel.profileSeedCalls.last,
        seed: 'work on mineru repo',
        apply: true,
        workspaceRoots: const [],
      );
      expect(
        find.byKey(const ValueKey('profile-contact-local-work-mineru-repo')),
        findsOneWidget,
      );
    },
  );
}

void _expectProfileSeedCall(
  ({String seed, bool apply, List<String> workspaceRoots}) actual, {
  required String seed,
  required bool apply,
  required List<String> workspaceRoots,
}) {
  expect(actual.seed, seed);
  expect(actual.apply, apply);
  expect(actual.workspaceRoots, workspaceRoots);
}

NavivoxProfileSeedResult _draftResult() {
  return NavivoxProfileSeedResult(
    action: 'profile_seed_draft',
    status: 'draft',
    applied: false,
    profileId: '',
    root: '',
    workspaceCount: 0,
    draft: _draft(),
    contact: const {},
  );
}

NavivoxProfileSeedResult _appliedResult({required int workspaceCount}) {
  return NavivoxProfileSeedResult(
    action: 'profile_seed_applied',
    status: 'applied',
    applied: true,
    profileId: 'work-mineru-repo',
    root: '.../work-mineru-repo',
    workspaceCount: workspaceCount,
    draft: _draft(),
    contact: const {
      'server_id': 'local',
      'profile_id': 'work-mineru-repo',
      'display_name': 'Work Mineru Repo',
      'server_label': 'local',
      'health': 'online',
      'latest_preview': 'Profile ready',
      'latest_preview_kind': 'status',
      'workspace_root_count': 0,
      'workspace_roots_ok': true,
      'attention_badges': <String>[],
      'mic_available': false,
      'active_turn_state': 'idle',
      'avatar_seed': 'local:work-mineru-repo',
    },
  );
}

Map<String, Object?> _draft() {
  return const {
    'profile_id': 'work-mineru-repo',
    'display_name': 'Work Mineru Repo',
    'instructions': 'Help the operator work on the Mineru repository.',
    'provider_model_state': {
      'status': 'unconfigured',
      'evidence': ['provider_not_configured'],
    },
    'workspace_root_suggestions': [
      {
        'label': 'Mineru workspace',
        'purpose': 'Operator-confirmed workspace for work on mineru repo',
        'requires_confirmation': true,
      },
    ],
    'tool_policy': {
      'mode': 'safe',
      'allowed': ['read', 'search', 'list'],
      'requires_approval': [
        'write_files',
        'run_commands',
        'network',
        'secrets',
      ],
    },
    'voice_profile_metadata': {
      'status': 'draft',
      'language_policy': 'match_user_language',
      'stt_provider': 'device_or_profile_default',
      'tts_provider': 'profile_default',
      'fallback_voice': 'text_only',
    },
    'generation_source': 'template',
    'evidence': ['template_fallback', 'workspace_confirmation_required'],
  };
}
