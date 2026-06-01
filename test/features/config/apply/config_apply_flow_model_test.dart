import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/apply/config_apply_flow_model.dart';
import 'package:navivox/features/config/apply/validation/config_validation_issues.dart';
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

  test('config admin errors with keys attach to draft fields', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
        ],
      },
      values: const {'navivox.exposure_mode': 'local'},
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {'navivox.exposure_mode': 'public'},
      validationSnapshot: const {
        'errors': [
          {
            'key': 'navivox.exposure_mode',
            'code': 'invalid_runtime',
            'message': 'Public exposure requires explicit server confirmation.',
          },
        ],
      },
    );

    expect(flow.hasInvalidChanges, isTrue);
    expect(flow.globalValidationMessages, isEmpty);
    expect(flow.validationMessagesFor('navivox.exposure_mode'), [
      'Public exposure requires explicit server confirmation.',
    ]);
  });

  test('generic validation errors block apply without field drift', () {
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
      validationSnapshot: const {
        'errors': ['Gateway validation failed.'],
      },
    );

    expect(flow.hasPendingChanges, isTrue);
    expect(flow.hasInvalidChanges, isTrue);
    expect(flow.canApply, isFalse);
    expect(flow.globalValidationMessages, ['Gateway validation failed.']);
    expect(flow.validationMessagesFor('providers.default'), isEmpty);
  });

  test('field validation errors remain visible for unchanged fields', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
          {'path': 'providers.local.enabled', 'label': 'Local enabled'},
        ],
      },
      values: const {
        'providers.default': 'openai',
        'providers.local.enabled': false,
      },
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {
        'providers.default': 'local',
        'providers.local.enabled': false,
      },
      validationSnapshot: const {
        'field_errors': {
          'providers.local.enabled': ['Local provider is not available.'],
        },
      },
    );

    expect(flow.hasPendingChanges, isTrue);
    expect(flow.hasInvalidChanges, isTrue);
    expect(flow.canApply, isFalse);
    expect(flow.validationMessagesFor('providers.default'), isEmpty);
    expect(flow.validationMessagesFor('providers.local.enabled'), [
      'Local provider is not available.',
    ]);
  });

  test('ignores stale field validation errors outside the current form', () {
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
      validationSnapshot: const {
        'field_errors': {
          'providers.removed': ['Removed provider is unavailable.'],
        },
      },
    );

    expect(flow.hasPendingChanges, isTrue);
    expect(flow.hasInvalidChanges, isFalse);
    expect(flow.canApply, isTrue);
    expect(flow.validationMessagesFor('providers.default'), isEmpty);
    expect(flow.validationMessagesFor('providers.removed'), [
      'Removed provider is unavailable.',
    ]);
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

  test('freezes validation message snapshots for draft changes', () {
    final validationMessages = ['Provider is not available.'];

    final change = ConfigDraftChange(
      path: 'providers.default',
      label: 'Default provider',
      oldDisplayValue: 'openai',
      newDisplayValue: 'missing',
      applyValue: 'missing',
      isSecret: false,
      requiresConfirmation: false,
      restartRequired: false,
      validationMessages: validationMessages,
    );

    validationMessages.add('Mutated after snapshot.');

    expect(change.validationMessages, ['Provider is not available.']);
    expect(() => change.validationMessages.clear(), throwsUnsupportedError);
  });

  group('validation snapshot wire compatibility', () {
    test('replays validation issue candidates before dedupe', () {
      final candidates = configValidationIssueCandidatesFromSnapshotParts(
        validationErrors: const [
          {'field': 'feature.enabled', 'detail': 'Expected a boolean.'},
          {'message': 'Global validation failed.'},
          'not-an-error-object',
        ],
        genericErrors: const [
          {'path': 'feature.enabled', 'message': 'Expected a boolean.'},
          'Gateway validation failed.',
        ],
        fieldErrors: const {
          'feature.enabled': [
            'Expected a boolean.',
            {'error': 'Still not a boolean.'},
          ],
          ' ': ['Dropped blank path.'],
        },
      ).toList();

      expect(
        candidates.map(
          (candidate) => (
            candidate.source,
            candidate.path,
            candidate.message,
            candidate.isGlobal,
          ),
        ),
        [
          (
            ConfigValidationIssueSource.validationErrors,
            'feature.enabled',
            'Expected a boolean.',
            false,
          ),
          (
            ConfigValidationIssueSource.validationErrors,
            null,
            'Global validation failed.',
            true,
          ),
          (
            ConfigValidationIssueSource.genericErrors,
            'feature.enabled',
            'Expected a boolean.',
            false,
          ),
          (
            ConfigValidationIssueSource.genericErrors,
            null,
            'Gateway validation failed.',
            true,
          ),
          (
            ConfigValidationIssueSource.fieldErrors,
            'feature.enabled',
            'Expected a boolean.',
            false,
          ),
          (
            ConfigValidationIssueSource.fieldErrors,
            'feature.enabled',
            'Still not a boolean.',
            false,
          ),
        ],
      );
    });

    test('accepts camelCase validation snapshot aliases', () {
      final form = _singleBooleanFieldForm();

      final flow = ConfigApplyFlowModel.fromDraft(
        form: form,
        draftValues: const {'feature.enabled': 'maybe'},
        validationSnapshot: const {
          'validationErrors': [
            {'field': 'feature.enabled', 'detail': 'Expected a boolean.'},
          ],
          'fieldErrors': {
            'feature.enabled': ['Still not a boolean.'],
          },
          'genericErrors': ['Gateway validation failed.'],
        },
      );

      expect(flow.hasInvalidChanges, isTrue);
      expect(flow.globalValidationMessages, ['Gateway validation failed.']);
      expect(flow.validationMessagesFor('feature.enabled'), [
        'Expected a boolean.',
        'Still not a boolean.',
      ]);
    });

    test('falls through empty generic error snapshot aliases', () {
      final form = _singleBooleanFieldForm();

      final flow = ConfigApplyFlowModel.fromDraft(
        form: form,
        draftValues: const {'feature.enabled': 'maybe'},
        validationSnapshot: const {
          'errors': [],
          'genericErrors': ['Gateway validation failed.'],
        },
      );

      expect(flow.hasInvalidChanges, isTrue);
      expect(flow.canApply, isFalse);
      expect(flow.globalValidationMessages, ['Gateway validation failed.']);
    });

    test('falls through null and empty snapshot aliases', () {
      final form = _singleBooleanFieldForm();

      final nullAliasFlow = ConfigApplyFlowModel.fromDraft(
        form: form,
        draftValues: const {'feature.enabled': 'maybe'},
        validationSnapshot: const {
          'validation_errors': null,
          'validationErrors': [
            {'field': 'feature.enabled', 'detail': 'Expected a boolean.'},
          ],
          'field_errors': null,
          'fieldErrors': {
            'feature.enabled': ['Still not a boolean.'],
          },
        },
      );
      final emptyAliasFlow = ConfigApplyFlowModel.fromDraft(
        form: form,
        draftValues: const {'feature.enabled': 'maybe'},
        validationSnapshot: const {
          'validation_errors': [],
          'validationErrors': [
            {'field': 'feature.enabled', 'detail': 'Expected a boolean.'},
          ],
          'field_errors': {},
          'fieldErrors': {
            'feature.enabled': ['Still not a boolean.'],
          },
        },
      );

      for (final flow in [nullAliasFlow, emptyAliasFlow]) {
        expect(flow.validationMessagesFor('feature.enabled'), [
          'Expected a boolean.',
          'Still not a boolean.',
        ]);
      }
    });

    test('falls through blank aliases in validation error objects', () {
      final form = _singleBooleanFieldForm();

      final flow = ConfigApplyFlowModel.fromDraft(
        form: form,
        draftValues: const {'feature.enabled': 'maybe'},
        validationSnapshot: const {
          'validation_errors': [
            {
              'path': ' ',
              'field': 'feature.enabled',
              'message': ' ',
              'detail': 'Expected a boolean.',
            },
          ],
        },
      );

      expect(flow.validationMessagesFor('feature.enabled'), [
        'Expected a boolean.',
      ]);
    });

    test('accepts nested field error message objects', () {
      final form = _singleBooleanFieldForm();

      final flow = ConfigApplyFlowModel.fromDraft(
        form: form,
        draftValues: const {'feature.enabled': 'maybe'},
        validationSnapshot: const {
          'field_errors': {
            'feature.enabled': {'detail': 'Expected a boolean.'},
          },
        },
      );

      expect(flow.validationMessagesFor('feature.enabled'), [
        'Expected a boolean.',
      ]);
    });
  });

  test('treats set-shaped draft values as unordered structured values', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'tools.enabled', 'type': 'array'},
        ],
      },
      values: const {
        'tools.enabled': {'shell', 'memory'},
      },
    );

    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {
        'tools.enabled': {'memory', 'shell'},
      },
    );

    expect(flow.hasPendingChanges, isFalse);
  });
}

ConfigFormModel _singleBooleanFieldForm() {
  return ConfigFormModel.fromSchema(
    schema: const {
      'fields': [
        {
          'path': 'feature.enabled',
          'type': 'boolean',
          'label': 'Feature enabled',
        },
      ],
    },
    values: const {'feature.enabled': false},
  );
}
