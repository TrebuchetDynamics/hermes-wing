import 'package:flutter_test/flutter_test.dart';
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
