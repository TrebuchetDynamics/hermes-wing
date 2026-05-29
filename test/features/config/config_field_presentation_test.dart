import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/form/config_field_presentation.dart';
import 'package:navivox/features/config/form/config_form_model.dart';

void main() {
  test('presents text field keys input mode and validation copy', () {
    final row = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'model.temperature',
            'label': 'Temperature',
            'type': 'number',
          },
        ],
      },
      values: const {'model.temperature': 0.4},
    ).rows.single;

    final field = ConfigFieldPresentation.fromRow(
      row,
      validationMessages: const ['Temperature must be between 0 and 1.'],
    );

    expect(field.path, 'model.temperature');
    expect(field.label, 'Temperature');
    expect(field.displayValue, '0.4');
    expect(field.editInitialValue, '0.4');
    expect(field.editKey, const ValueKey('config-edit-model.temperature'));
    expect(field.inputKey, const ValueKey('config-input-model.temperature'));
    expect(field.saveKey, const ValueKey('config-save-model.temperature'));
    expect(
      field.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(field.obscureText, isFalse);
    expect(field.validationMessages, ['Temperature must be between 0 and 1.']);
    expect(field.coerceEditValue('0.7'), 0.7);
    expect(field.clearsDraftFor(0.7), isFalse);
  });

  test(
    'keeps secret values redacted and treats blank secret drafts as clearable',
    () {
      final row = ConfigFormModel.fromSchema(
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
            'value': 'nvbx_secret_should_not_render',
          },
        },
      ).rows.single;

      final field = ConfigFieldPresentation.fromRow(
        row,
        validationMessages: const ['Secret mutation denied.'],
      );

      expect(field.displayValue, 'Secret configured');
      expect(
        field.displayValue,
        isNot(contains('nvbx_secret_should_not_render')),
      );
      expect(field.editInitialValue, '');
      expect(field.obscureText, isTrue);
      expect(field.keyboardType, TextInputType.text);
      expect(field.validationMessages, ['Secret mutation denied.']);
      expect(field.coerceEditValue('rotated-secret'), 'rotated-secret');
      expect(field.clearsDraftFor('   '), isTrue);
      expect(field.clearsDraftFor('rotated-secret'), isFalse);
    },
  );
}
