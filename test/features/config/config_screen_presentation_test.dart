import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';
import 'package:navivox/features/config/form/config_draft_session.dart';
import 'package:navivox/features/config/presentation/config_screen_presentation.dart';

void main() {
  test(
    'assembles scope, selected sections, validation, and pending apply state',
    () {
      final state = NavivoxChannelState(
        servers: const [
          NavivoxServer(id: 'local', name: 'Local Gormes', status: 'online'),
        ],
        activeServerId: 'local',
        profileContacts: const [
          NavivoxProfileContact(
            serverId: 'local',
            profileId: 'mineru',
            displayName: 'Mineru Builder',
            serverLabel: 'local',
            health: NavivoxProfileHealth.online,
            latestPreview: 'Config active',
          ),
        ],
        selectedProfileContactKey: 'local::mineru',
        configSchema: const {
          'sections': [
            {
              'id': 'providers',
              'label': 'Provider and Models',
              'fields': ['providers.default'],
            },
            {
              'id': 'gateway',
              'label': 'Navivox Gateway',
              'description': 'Gateway exposure and auth.',
              'fields': ['navivox.exposure_mode'],
            },
          ],
          'fields': [
            {'path': 'providers.default', 'label': 'Default provider'},
            {
              'path': 'navivox.exposure_mode',
              'label': 'Exposure mode',
              'risk_level': 'high',
              'restart_required': true,
            },
          ],
        },
        configValues: const {
          'providers.default': 'openai',
          'navivox.exposure_mode': 'local',
        },
        configDiff: const {
          'field_errors': {
            'navivox.exposure_mode': [
              'Public exposure requires explicit server confirmation.',
            ],
          },
        },
      );

      final presentation = ConfigScreenPresentation.fromState(
        state: state,
        sectionId: 'gateway',
        draftSession: const ConfigDraftSession(
          draftValues: {'navivox.exposure_mode': 'public'},
          editingField: 'navivox.exposure_mode',
        ),
      );

      expect(presentation.scope.serverLabel, 'Local Gormes');
      expect(presentation.scope.profileLabel, 'Mineru Builder');
      expect(presentation.isEmpty, isFalse);
      expect(presentation.isMissingSection, isFalse);
      expect(presentation.sections, hasLength(1));
      expect(presentation.sections.single.label, 'Navivox Gateway');
      expect(
        presentation.sections.single.description,
        'Gateway exposure and auth.',
      );
      expect(presentation.sections.single.fields, hasLength(1));
      expect(presentation.sections.single.fields.single.isEditing, isTrue);
      expect(
        presentation.sections.single.fields.single.field.label,
        'Exposure mode',
      );
      expect(
        presentation.sections.single.fields.single.field.validationMessages,
        ['Public exposure requires explicit server confirmation.'],
      );
      expect(presentation.applyFlow.canApply, isFalse);
      expect(presentation.applyPresentation.hasChanges, isTrue);
      expect(presentation.applyPresentation.canApply, isFalse);
      expect(
        presentation.applyPresentation.changes.single.summaryLabel,
        'Exposure mode: local -> public',
      );
      expect(presentation.showPendingChanges, isTrue);
    },
  );

  test(
    'returns a safe missing-section state when the requested section is absent',
    () {
      final presentation = ConfigScreenPresentation.fromState(
        state: const NavivoxChannelState(
          configSchema: {
            'sections': [
              {
                'id': 'providers',
                'label': 'Provider and Models',
                'fields': ['providers.default'],
              },
            ],
            'fields': [
              {'path': 'providers.default', 'label': 'Default provider'},
            ],
          },
          configValues: {'providers.default': 'openai'},
        ),
        sectionId: 'missing',
        draftSession: const ConfigDraftSession(),
      );

      expect(presentation.isEmpty, isFalse);
      expect(presentation.isMissingSection, isTrue);
      expect(presentation.missingSectionId, 'missing');
      expect(
        presentation.missingSectionMessage,
        'Config section not found: missing',
      );
      expect(presentation.sections, isEmpty);
    },
  );

  test('returns empty-state copy when no config schema is loaded', () {
    final presentation = ConfigScreenPresentation.fromState(
      state: const NavivoxChannelState(),
      sectionId: 'missing',
      draftSession: const ConfigDraftSession(),
    );

    expect(presentation.isEmpty, isTrue);
    expect(presentation.emptyMessage, 'No config available');
    expect(presentation.isMissingSection, isFalse);
    expect(presentation.sections, isEmpty);
    expect(presentation.showPendingChanges, isFalse);
  });
}
