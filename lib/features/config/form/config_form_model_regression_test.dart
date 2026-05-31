import 'config_form_model.dart';

void main() {
  preservesUnrecognizedBooleanEditTextForValidation();
  coercesRecognizedBooleanEditTextCaseInsensitively();
  preservesFractionalIntegerEditTextForValidation();
  readsCamelCaseSchemaRiskAndConfirmationFields();
  readsReloadModeAliasesForDisplayAndRestartInference();
  readsAllowedValuesAndActionsWireAliases();
  fallsBackAcrossBlankStringSchemaAliases();
}

void preservesUnrecognizedBooleanEditTextForValidation() {
  final row = _row(type: ConfigFormFieldType.boolean, rawValue: false);

  final result = row.coerceEditValue('maybe');

  _expect(
    result == 'maybe',
    'invalid boolean edit text should be preserved for validation instead of silently becoming false',
  );
}

void coercesRecognizedBooleanEditTextCaseInsensitively() {
  final row = _row(type: ConfigFormFieldType.boolean, rawValue: false);

  _expect(row.coerceEditValue(' TRUE ') == true, 'TRUE should coerce to true');
  _expect(
    row.coerceEditValue(' false ') == false,
    'false should coerce to false',
  );
}

void preservesFractionalIntegerEditTextForValidation() {
  final row = _row(type: ConfigFormFieldType.integer, rawValue: 1);

  final result = row.coerceEditValue('1.5');

  _expect(
    result == '1.5',
    'fractional text entered for an integer field should be preserved for validation instead of coerced to a number',
  );
}

void readsCamelCaseSchemaRiskAndConfirmationFields() {
  final form = ConfigFormModel.fromSchema(
    schema: {
      'fields': [
        {
          'path': 'server.port',
          'type': 'integer',
          'label': 'Server port',
          'restartRequired': true,
          'requiresConfirmation': true,
          'riskLevel': 'Medium',
        },
      ],
    },
    values: {'server.port': 8080},
  );

  final row = form.rows.single;

  _expect(
    row.restartRequired,
    'camelCase restartRequired schema flag should require restart',
  );
  _expect(
    row.requiresConfirmation,
    'camelCase requiresConfirmation schema flag should require confirmation',
  );
  _expect(
    row.riskLevel == 'medium',
    'camelCase riskLevel schema field should be normalized to lowercase',
  );
}

void readsReloadModeAliasesForDisplayAndRestartInference() {
  final form = ConfigFormModel.fromSchema(
    schema: {
      'fields': [
        {
          'path': 'audio.output_device',
          'type': 'string',
          'reloadMode': 'restart-required',
        },
      ],
    },
    values: {'audio.output_device': 'default'},
  );

  final row = form.rows.single;

  _expect(
    row.reloadMode == 'restart-required',
    'camelCase reloadMode schema alias should be retained for presentation',
  );
  _expect(
    row.restartRequired,
    'camelCase reloadMode containing restart should infer restartRequired',
  );
}

void readsAllowedValuesAndActionsWireAliases() {
  final form = ConfigFormModel.fromSchema(
    schema: {
      'fields': [
        {
          'path': 'voice.capture_mode',
          'type': 'string',
          'allowedValues': ['push-to-talk', 'wake-word'],
          'supportedActions': ['restart-audio'],
        },
      ],
    },
    values: {'voice.capture_mode': 'push-to-talk'},
  );

  final row = form.rows.single;

  _expect(
    row.allowedValues.join(',') == 'push-to-talk,wake-word',
    'camelCase allowedValues schema alias should populate allowed values',
  );
  _expect(
    row.actions.join(',') == 'restart-audio',
    'camelCase supportedActions schema alias should populate actions',
  );
}

void fallsBackAcrossBlankStringSchemaAliases() {
  final form = ConfigFormModel.fromSchema(
    schema: {
      'fields': [
        {
          'path': ' ',
          'key': 'server.host',
          'label': ' ',
          'title': 'Server host',
        },
      ],
    },
    values: {'server.host': 'gateway.example'},
  );

  final row = form.rows.single;

  _expect(
    row.field == 'server.host',
    'blank field path aliases should not drop later non-empty key aliases',
  );
  _expect(
    row.label == 'Server host',
    'blank label aliases should not hide later non-empty title aliases',
  );
}

ConfigFormRow _row({required ConfigFormFieldType type, Object? rawValue}) {
  return ConfigFormRow(
    field: 'feature.enabled',
    label: 'Feature enabled',
    type: type,
    required: false,
    restartRequired: false,
    riskLevel: 'low',
    requiresConfirmation: false,
    rawValue: rawValue,
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
