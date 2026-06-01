import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/gateway/config_admin/config_admin_schema_field_projection.dart';
import 'package:navivox/core/gateway/config_admin/navivox_gateway_config_admin.dart';

void main() {
  test('config admin changes normalize key and value wire shape', () {
    expect(
      const NavivoxConfigAdminChange(
        key: ' navivox.allowed_profiles ',
        value: [' mineru ', 'ops'],
      ).toJson(),
      {'key': 'navivox.allowed_profiles', 'value': 'mineru,ops'},
    );

    expect(
      const NavivoxConfigAdminChange(
        key: ' navivox.allowed_profiles ',
        value: [' mineru ', ' ', 'ops', ''],
      ).toJson(),
      {'key': 'navivox.allowed_profiles', 'value': 'mineru,ops'},
    );

    expect(
      const NavivoxConfigAdminChange(
        key: ' navivox.token ',
        value: null,
        delete: true,
      ).toJson(),
      {'key': 'navivox.token', 'value': '', 'delete': true},
    );
  });

  test('config admin changes reject blank keys before ambiguous requests', () {
    expect(
      () => const NavivoxConfigAdminChange(key: ' \t ', value: 8766).toJson(),
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.message,
          'message',
          'must not be blank',
        ),
      ),
    );
  });

  test('diff summary keeps redaction policy explicit', () {
    const diff = NavivoxConfigAdminDiff(
      key: 'navivox.token',
      type: 'secret',
      secret: true,
      beforeRedacted: true,
      afterRedacted: true,
      secretStatus: ' rotated ',
    );

    expect(
      diff.summaryLabel,
      'navivox.token: [redacted] -> [redacted:rotated]',
    );
  });

  test('type-secret config diffs do not retain raw echoed values', () {
    final diff = NavivoxConfigAdminDiff.fromJson(const {
      'key': 'providers.openai.api_key',
      'type': ' Secret ',
      'before': 'old-leaked-api-key',
      'after': 'new-leaked-api-key',
      'secretStatus': 'rotated',
    });

    expect(diff.secret, isTrue);
    expect(diff.before, isNull);
    expect(diff.after, isNull);
    expect(diff.beforeRedacted, isTrue);
    expect(diff.afterRedacted, isTrue);
    expect(diff.summaryLabel, contains('[redacted:rotated]'));
    expect(diff.toJson().toString(), isNot(contains('leaked-api-key')));
  });

  test(
    'constructed type-secret config diffs redact snapshots and summaries',
    () {
      const diff = NavivoxConfigAdminDiff(
        key: 'providers.openai.api_key',
        type: 'secret',
        before: 'old-leaked-api-key',
        after: 'new-leaked-api-key',
        secretStatus: 'set',
      );

      expect(
        diff.summaryLabel,
        'providers.openai.api_key: [redacted] -> [redacted:set]',
      );
      expect(diff.toJson().toString(), isNot(contains('leaked-api-key')));
    },
  );

  test('secret config values never retain raw gateway value payloads', () {
    final value = NavivoxConfigAdminValue.fromJson(const {
      'key': 'providers.openai.api_key',
      'type': 'secret',
      'value': 'leaked-api-key',
      'secret': true,
      'secretStatus': 'set',
      'source': 'env:GORMES_OPENAI_API_KEY',
    });

    expect(value.value, isNull);
    expect(value.formValue, {
      'secret_status': 'set',
      'source': 'env:GORMES_OPENAI_API_KEY',
    });
    expect(value.toString(), isNot(contains('leaked-api-key')));
  });

  test('constructed secret config values normalize non-secret provenance', () {
    const value = NavivoxConfigAdminValue(
      key: 'providers.openai.api_key',
      type: 'secret',
      secret: true,
      value: 'constructed-leaked-api-key',
      secretStatus: ' set ',
      source: ' env:GORMES_OPENAI_API_KEY ',
    );

    expect(value.value, isNull);
    expect(value.formValue, {
      'secret_status': 'set',
      'source': 'env:GORMES_OPENAI_API_KEY',
    });
  });

  test(
    'type-secret config values are redacted without duplicate secret flag',
    () {
      final value = NavivoxConfigAdminValue.fromJson(const {
        'key': 'providers.openai.api_key',
        'type': 'secret',
        'value': 'leaked-api-key',
        'secretStatus': 'set',
      });

      expect(value.secret, isTrue);
      expect(value.value, isNull);
      expect(value.formValue, {'secret_status': 'set'});
      expect(value.toString(), isNot(contains('leaked-api-key')));
    },
  );

  test('secret type matching is case-insensitive before redaction', () {
    final value = NavivoxConfigAdminValue.fromJson(const {
      'key': 'providers.openai.api_key',
      'type': ' Secret ',
      'value': 'leaked-api-key',
      'secretStatus': 'set',
    });

    expect(value.secret, isTrue);
    expect(value.value, isNull);
    expect(value.formValue, {'secret_status': 'set'});
    expect(value.toString(), isNot(contains('leaked-api-key')));

    final field = NavivoxConfigAdminField.fromJson(const {
      'path': 'providers.openai.api_key',
      'type': ' SECRET ',
      'label': 'OpenAI API key',
    });

    expect(field.secret, isTrue);
    expect(field.toFormField()['secret'], isTrue);
  });

  test('type-secret schema fields expose secret form metadata', () {
    final field = NavivoxConfigAdminField.fromJson(const {
      'path': 'providers.openai.api_key',
      'type': 'secret',
      'label': 'OpenAI API key',
    });

    expect(field.secret, isTrue);
    expect(field.toFormField()['secret'], isTrue);
  });

  test('redaction and reload status aliases survive gateway normalization', () {
    final value = NavivoxConfigAdminValue.fromJson(const {
      'key': 'providers.openai.api_key',
      'secret': true,
      'secretStatus': 'set',
    });
    expect(value.secretStatus, 'set');
    expect(value.formValue, {'secret_status': 'set'});

    final response = NavivoxConfigAdminResponse.fromJson(const {
      'action': 'config.apply',
      'valid': true,
      'reloadApplied': true,
      'pendingRestart': true,
      'reloadError': 'restart required',
      'changes': [
        {
          'key': 'providers.openai.api_key',
          'type': 'secret',
          'beforeRedacted': true,
          'afterRedacted': true,
          'secretStatus': 'set',
        },
      ],
    });

    expect(response.reloadApplied, isTrue);
    expect(response.pendingRestart, isTrue);
    expect(response.reloadError, 'restart required');
    expect(response.changes.single.beforeRedacted, isTrue);
    expect(response.changes.single.afterRedacted, isTrue);
    expect(response.changes.single.secretStatus, 'set');
    expect(response.snapshot['reload_applied'], isTrue);
    expect(response.changes.single.summaryLabel, contains('[redacted:set]'));
  });

  test('schema list aliases expose fallback candidate order', () {
    const schemaField = {
      'path': 'voice.capture_mode',
      'allowed': <String>[],
      'allowedValues': ['push-to-talk', 'wake-word'],
      'actions': <String>[],
      'supportedActions': ['restart-audio'],
    };

    expect(configAdminSchemaAllowedValues(schemaField), [
      'push-to-talk',
      'wake-word',
    ]);
    expect(configAdminSchemaActions(schemaField), ['restart-audio']);
  });

  test('preserves enum_values as config admin allowed values', () {
    final field = NavivoxConfigAdminField.fromJson(const {
      'path': 'navivox.exposure_mode',
      'type': 'enum',
      'label': 'Exposure mode',
      'enum_values': ['local', 'tunnel'],
    });

    expect(field.allowed, ['local', 'tunnel']);
    expect(field.toFormField()['allowed'], ['local', 'tunnel']);
  });
}
