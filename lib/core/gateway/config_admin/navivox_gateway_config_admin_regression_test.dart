import 'navivox_gateway_config_admin.dart';

void main() {
  schemaFieldListAliasesSurviveGatewayNormalization();
}

void schemaFieldListAliasesSurviveGatewayNormalization() {
  final response = NavivoxConfigAdminSchemaResponse.fromJson({
    'action': 'config_schema',
    'fields': [
      {
        'key': 'voice.capture_mode',
        'type': 'string',
        'allowedValues': ['push-to-talk', 'wake-word'],
        'supportedActions': ['restart-audio'],
      },
    ],
  });

  final formField = response.toConfigSchema()['fields'] as Iterable<Object?>;
  final field = formField.single as Map<String, Object?>;

  _expect(
    (field['allowed'] as List<String>).join(',') == 'push-to-talk,wake-word',
    'gateway schema normalization should preserve camelCase allowedValues',
  );
  _expect(
    (field['actions'] as List<String>).join(',') == 'restart-audio',
    'gateway schema normalization should preserve camelCase supportedActions',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
