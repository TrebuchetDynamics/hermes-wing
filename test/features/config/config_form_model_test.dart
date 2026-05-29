import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/form/config_form_model.dart';

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
