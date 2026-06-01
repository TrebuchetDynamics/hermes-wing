import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/form/config_form_model.dart';
import 'package:navivox/features/config/form/model/config_form_schema_candidates.dart';
import 'package:navivox/features/config/form/model/config_form_schema_wire.dart';

void main() {
  test('parses schema fields with labels values and typed edit coercion', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'providers.default',
            'label': 'Default provider',
            'type': 'string',
            'required': true,
          },
          {'path': 'model.temperature', 'type': 'number'},
          {'path': 'navivox.enabled', 'type': 'boolean'},
        ],
      },
      values: const {
        'providers.default': 'openai',
        'model.temperature': 0.4,
        'navivox.enabled': true,
      },
    );

    expect(model.rows, hasLength(3));
    expect(model.rows[0].field, 'providers.default');
    expect(model.rows[0].label, 'Default provider');
    expect(model.rows[0].displayValue, 'openai');
    expect(model.rows[0].required, isTrue);
    expect(model.rows[1].displayValue, '0.4');
    expect(model.rows[1].coerceEditValue('0.7'), 0.7);
    expect(model.rows[2].coerceEditValue('false'), false);
  });

  test('builds schema row candidates with explicit skip and dedupe rules', () {
    final plan = configFormSchemaRowCandidatePlanFromFields(
      rawFields: const [
        'not-a-field',
        {'path': ' '},
        {'path': 'providers.default', 'label': 'Default provider'},
        {'path': 'providers.default', 'label': 'Duplicate provider'},
        {'key': 'model.temperature', 'type': 'number'},
      ],
      values: const {'providers.default': 'openai', 'model.temperature': 0.4},
    );
    final candidates = plan.candidates;

    expect(plan.acceptedRows, 2);
    expect(plan.skippedInvalidRows, 2);
    expect(plan.skippedDuplicateRows, 1);
    expect(
      plan.rejections.map(
        (rejection) => (rejection.index, rejection.reason, rejection.field),
      ),
      [
        (0, ConfigFormSchemaRowRejectionReason.invalid, null),
        (1, ConfigFormSchemaRowRejectionReason.invalid, null),
        (
          3,
          ConfigFormSchemaRowRejectionReason.duplicateField,
          'providers.default',
        ),
      ],
    );
    expect(() => plan.rejections.clear(), throwsUnsupportedError);
    expect(candidates.map((candidate) => candidate.field), [
      'providers.default',
      'model.temperature',
    ]);
    expect(candidates.first.label, 'Default provider');
    expect(candidates.first.rawValue, 'openai');
    expect(candidates.last.rawValue, 0.4);
    expect(() => candidates.clear(), throwsUnsupportedError);
  });

  test('deduplicates duplicate schema field paths before section grouping', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'provider',
            'fields': ['providers.default'],
          },
        ],
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
          {'path': 'providers.default', 'label': 'Duplicate provider'},
          {'path': 'model.temperature', 'type': 'number'},
        ],
      },
      values: const {'providers.default': 'openai', 'model.temperature': 0.4},
    );

    expect(model.rows.map((row) => row.field), [
      'providers.default',
      'model.temperature',
    ]);
    expect(model.rows.first.label, 'Default provider');
    expect(model.sections.first.rows.single.label, 'Default provider');
    expect(model.sections.last.rows.single.field, 'model.temperature');
  });

  test('groups fields into server-provided schema sections', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Provider and Models',
            'description': 'Model and provider defaults.',
            'fields': ['providers.default', 'model.temperature'],
          },
          {
            'id': 'gateway',
            'label': 'Navivox Gateway',
            'fields': ['navivox.exposure_mode'],
          },
        ],
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
          {'path': 'model.temperature', 'type': 'number'},
          {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
          {'path': 'tools.allow_shell', 'label': 'Allow shell tools'},
        ],
      },
      values: const {
        'providers.default': 'openai',
        'model.temperature': 0.4,
        'navivox.exposure_mode': 'local',
        'tools.allow_shell': false,
      },
    );

    expect(model.sections, hasLength(3));
    expect(model.sections[0].id, 'providers');
    expect(model.sections[0].label, 'Provider and Models');
    expect(model.sections[0].description, 'Model and provider defaults.');
    expect(model.sections[0].rows.map((row) => row.field), [
      'providers.default',
      'model.temperature',
    ]);
    expect(model.sections[1].id, 'gateway');
    expect(model.sections[1].rows.single.field, 'navivox.exposure_mode');
    expect(model.sections[2].label, 'Other config');
    expect(model.sections[2].rows.single.field, 'tools.allow_shell');
  });

  test('parses enum_values as allowed values from schema fields', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'navivox.exposure_mode',
            'type': 'enum',
            'enum_values': ['local', 'tunnel'],
          },
        ],
      },
      values: const {'navivox.exposure_mode': 'local'},
    );

    expect(model.rows.single.allowedValues, ['local', 'tunnel']);
  });

  test('keeps non-finite numeric edits as text for validation replay', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'model.temperature', 'type': 'number'},
          {'path': 'server.port', 'type': 'integer'},
        ],
      },
      values: const {'model.temperature': 0.4, 'server.port': 8080},
    );

    expect(model.rows[0].coerceEditValue('NaN'), 'NaN');
    expect(model.rows[0].coerceEditValue('Infinity'), 'Infinity');
    expect(model.rows[0].coerceEditValue('-Infinity'), '-Infinity');
    expect(model.rows[1].coerceEditValue('NaN'), 'NaN');
  });

  test('redacts secret values and prepares write-only secret edits', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'providers.openai.api_key',
            'label': 'OpenAI API key',
            'type': 'secret',
            'secret': true,
          },
        ],
      },
      values: const {
        'providers.openai.api_key': {
          'secret_status': 'configured',
          'source': 'env:OPENAI_API_KEY',
          'value': 'nvbx_secret_should_not_render',
        },
      },
    );

    final row = model.rows.single;

    expect(row.isSecret, isTrue);
    expect(row.displayValue, 'Secret configured (env:OPENAI_API_KEY)');
    expect(row.displayValue, isNot(contains('nvbx_secret_should_not_render')));
    expect(row.coerceEditValue('new-secret'), 'new-secret');
  });

  test('falls back to name when path is missing and skips invalid fields', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'name': 'temperature', 'type': 'number'},
          {'type': 'string'},
          'not-a-field',
        ],
      },
      values: const {'temperature': 1},
    );

    expect(model.rows, hasLength(1));
    expect(model.rows.single.field, 'temperature');
    expect(model.rows.single.displayValue, '1');
    expect(model.sections.single.id, 'general');
    expect(model.sections.single.rows.single.field, 'temperature');
  });

  test('accepts strict string boolean schema flags', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'server.port',
            'type': 'integer',
            'required': 'true',
            'restartRequired': 'TRUE',
            'requiresConfirmation': 'false',
          },
          {
            'path': 'danger.zone',
            'riskLevel': ' high ',
            'requires_confirmation': 'FALSE',
          },
          {
            'path': 'providers.openai.api_key',
            'type': 'string',
            'secret': 'true',
          },
        ],
      },
      values: const {'server.port': 8080, 'danger.zone': 'disabled'},
    );

    expect(model.rows[0].required, isTrue);
    expect(model.rows[0].restartRequired, isTrue);
    expect(model.rows[0].requiresConfirmation, isFalse);
    expect(model.rows[1].requiresConfirmation, isTrue);
    expect(model.rows[2].isSecret, isTrue);
  });

  test('falls back past blank boolean schema aliases', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'server.port',
            'type': 'integer',
            'restart_required': ' ',
            'restartRequired': true,
            'requires_confirmation': '',
            'requiresConfirmation': 'true',
          },
        ],
      },
      values: const {'server.port': 8080},
    );

    expect(model.rows.single.restartRequired, isTrue);
    expect(model.rows.single.requiresConfirmation, isTrue);
  });

  test('schema alias candidate replay does not duplicate exact keys', () {
    final candidates = configFormSchemaValueCandidates(
      const {
        'fields': ['providers.default'],
        'fieldRefs': ['model.temperature'],
      },
      const ['fields', 'field_refs', 'field_paths'],
    ).toList();

    expect(candidates, [
      ['providers.default'],
      ['model.temperature'],
    ]);
  });

  test('falls back across section field reference aliases', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Providers',
            'fields': [],
            'fieldRefs': [
              {'field': 'providers.default'},
              {'path': 'model.temperature'},
            ],
          },
        ],
        'fields': [
          {'path': 'providers.default'},
          {'path': 'model.temperature'},
        ],
      },
      values: const {},
    );

    expect(model.sections.single.rows.map((row) => row.field), [
      'providers.default',
      'model.temperature',
    ]);
  });

  test('falls back past unusable section field reference aliases', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Providers',
            'fields': [
              {'label': 'not a field ref'},
              '   ',
            ],
            'fieldRefs': [
              {'field': 'providers.default'},
              {'path': 'model.temperature'},
            ],
          },
        ],
        'fields': [
          {'path': 'providers.default'},
          {'path': 'model.temperature'},
          {'path': 'tools.allow_shell'},
        ],
      },
      values: const {},
    );

    expect(model.sections.map((section) => section.id), ['providers', 'other']);
    expect(model.sections.first.rows.map((row) => row.field), [
      'providers.default',
      'model.temperature',
    ]);
    expect(model.sections.last.rows.single.field, 'tools.allow_shell');
  });

  test('does not infer restart from negative reload modes', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'audio.input_device', 'reload': 'no_restart'},
          {'path': 'audio.output_device', 'reload': 'reload_without_restart'},
          {'path': 'model.provider', 'reload': 'restart_or_reload'},
          {'path': 'model.cache', 'reload': 'restart_without_reload'},
        ],
      },
      values: const {},
    );

    expect(model.rows[0].reloadMode, 'no_restart');
    expect(model.rows[0].restartRequired, isFalse);
    expect(model.rows[1].restartRequired, isFalse);
    expect(model.rows[2].restartRequired, isTrue);
    expect(model.rows[3].restartRequired, isTrue);
  });

  test('schema parsing snapshots rows and sections against mutation', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'providers',
            'fields': ['providers.default'],
          },
        ],
        'fields': [
          {'path': 'providers.default'},
        ],
      },
      values: const {},
    );

    expect(() => model.rows.clear(), throwsUnsupportedError);
    expect(() => model.sections.clear(), throwsUnsupportedError);
    expect(() => model.sections.single.rows.clear(), throwsUnsupportedError);
  });

  test(
    'deduplicates repeated section route ids so all sections are reachable',
    () {
      final model = ConfigFormModel.fromSchema(
        schema: const {
          'sections': [
            {
              'id': 'providers',
              'label': 'Providers',
              'fields': ['providers.default'],
            },
            {
              'id': 'providers',
              'label': 'Provider model settings',
              'fields': ['model.temperature'],
            },
          ],
          'fields': [
            {'path': 'providers.default'},
            {'path': 'model.temperature'},
          ],
        },
        values: const {},
      );

      expect(model.sections.map((section) => section.id), [
        'providers',
        'providers-2',
      ]);
      expect(
        model.selectSection('providers-2').sections.single.rows.single.field,
        'model.temperature',
      );
    },
  );

  test('deduplicates unsectioned fallback ids against server section ids', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'other',
            'label': 'Server Other',
            'fields': ['providers.default'],
          },
        ],
        'fields': [
          {'path': 'providers.default'},
          {'path': 'model.temperature'},
        ],
      },
      values: const {},
    );

    expect(model.sections.map((section) => section.id), ['other', 'other-2']);
    expect(
      model.selectSection('other-2').sections.single.rows.single.field,
      'model.temperature',
    );
  });

  test('selects one config section by route id and reports misses', () {
    final model = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Provider and Models',
            'fields': ['providers.default'],
          },
          {
            'id': 'gateway',
            'label': 'Navivox Gateway',
            'fields': ['navivox.exposure_mode'],
          },
        ],
        'fields': [
          {'path': 'providers.default'},
          {'path': 'navivox.exposure_mode'},
        ],
      },
      values: const {},
    );

    final all = model.selectSection(null);
    expect(all.sections.map((section) => section.id), ['providers', 'gateway']);
    expect(all.isFiltered, isFalse);
    expect(all.isMissing, isFalse);

    final providers = model.selectSection(' providers ');
    expect(providers.sections.single.id, 'providers');
    expect(providers.isFiltered, isTrue);
    expect(providers.isMissing, isFalse);

    final missing = model.selectSection('unknown');
    expect(missing.sections, isEmpty);
    expect(missing.isFiltered, isTrue);
    expect(missing.isMissing, isTrue);
    expect(missing.missingId, 'unknown');
  });
}
