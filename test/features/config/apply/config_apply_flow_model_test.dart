import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/apply/config_apply_flow_model.dart';
import 'package:navivox/features/config/form/config_form_model.dart';

void main() {
  test('builds redacted pending changes with confirmation metadata', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'navivox.exposure_mode',
            'label': 'Exposure mode',
            'type': 'string',
            'risk_level': 'high',
            'restart_required': true,
          },
          {
            'path': 'providers.openai.api_key',
            'label': 'OpenAI API key',
            'type': 'secret',
            'secret': true,
          },
        ],
      },
      values: const {
        'navivox.exposure_mode': 'local',
        'providers.openai.api_key': {
          'secret_status': 'configured',
          'value': 'nvbx_secret_should_not_render',
        },
      },
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {
        'navivox.exposure_mode': 'public',
        'providers.openai.api_key': 'rotated-secret',
      },
    );

    expect(flow.hasPendingChanges, isTrue);
    expect(flow.requiresConfirmation, isTrue);
    expect(flow.changes, hasLength(2));

    final exposure = flow.changes.firstWhere(
      (change) => change.path == 'navivox.exposure_mode',
    );
    expect(exposure.label, 'Exposure mode');
    expect(exposure.oldDisplayValue, 'local');
    expect(exposure.newDisplayValue, 'public');
    expect(exposure.requiresConfirmation, isTrue);
    expect(exposure.restartRequired, isTrue);
    expect(exposure.applyValue, 'public');

    final secret = flow.changes.firstWhere(
      (change) => change.path == 'providers.openai.api_key',
    );
    expect(secret.oldDisplayValue, 'Secret configured');
    expect(secret.newDisplayValue, 'Secret will be updated');
    expect(secret.newDisplayValue, isNot(contains('rotated-secret')));
    expect(
      secret.newDisplayValue,
      isNot(contains('nvbx_secret_should_not_render')),
    );
    expect(secret.applyValue, 'rotated-secret');
  });

  test('maps validation errors onto draft changes and blocks apply', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
          {'path': 'providers.default', 'label': 'Default provider'},
        ],
      },
      values: const {
        'navivox.exposure_mode': 'local',
        'providers.default': 'openai',
      },
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {
        'navivox.exposure_mode': 'public',
        'providers.default': 'local',
      },
      validationSnapshot: const {
        'validation_errors': [
          {
            'path': 'navivox.exposure_mode',
            'message': 'Public exposure requires explicit server confirmation.',
          },
        ],
        'field_errors': {
          'providers.default': ['Provider is not available.'],
        },
      },
    );

    expect(flow.canApply, isFalse);
    expect(flow.hasInvalidChanges, isTrue);

    final exposure = flow.changes.firstWhere(
      (change) => change.path == 'navivox.exposure_mode',
    );
    expect(exposure.validationState, ConfigDraftValidationState.invalid);
    expect(exposure.validationMessages, [
      'Public exposure requires explicit server confirmation.',
    ]);

    final provider = flow.changes.firstWhere(
      (change) => change.path == 'providers.default',
    );
    expect(provider.validationMessages, ['Provider is not available.']);
  });

  test('deduplicates repeated validation messages for a field', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
        ],
      },
      values: const {'providers.default': 'openai'},
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {'providers.default': 'missing'},
      validationSnapshot: const {
        'validation_errors': [
          {
            'path': 'providers.default',
            'message': 'Provider is not available.',
          },
        ],
        'field_errors': {
          'providers.default': [
            'Provider is not available.',
            'Choose an installed provider.',
          ],
        },
      },
    );

    expect(flow.validationMessagesFor('providers.default'), [
      'Provider is not available.',
      'Choose an installed provider.',
    ]);
  });

  test('ignores unchanged values and blank secret drafts', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'providers.default', 'type': 'string'},
          {
            'path': 'providers.openai.api_key',
            'type': 'secret',
            'secret': true,
          },
        ],
      },
      values: const {
        'providers.default': 'openai',
        'providers.openai.api_key': {'secret_status': 'configured'},
      },
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {
        'providers.default': 'openai',
        'providers.openai.api_key': '   ',
      },
    );

    expect(flow.hasPendingChanges, isFalse);
    expect(flow.changes, isEmpty);
  });

  test('does not treat equal structured draft values as pending changes', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'tools.enabled', 'type': 'array'},
          {'path': 'providers.options', 'type': 'object'},
        ],
      },
      values: const {
        'tools.enabled': ['shell', 'memory'],
        'providers.options': {
          'openai': {'enabled': true},
          'local': {'enabled': false},
        },
      },
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: {
        'tools.enabled': List<String>.of(['shell', 'memory']),
        'providers.options': {
          'openai': Map<String, Object?>.of({'enabled': true}),
          'local': Map<String, Object?>.of({'enabled': false}),
        },
      },
    );

    expect(flow.hasPendingChanges, isFalse);
    expect(flow.changes, isEmpty);
  });

  test('freezes draft change snapshots after construction', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
        ],
      },
      values: const {'providers.default': 'openai'},
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {'providers.default': 'local'},
    );

    expect(flow.changes, hasLength(1));
    expect(() => flow.changes.clear(), throwsUnsupportedError);
    expect(flow.changes.single.path, 'providers.default');
  });
}
