import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_json.dart';

void main() {
  test('first string field matches aliases and ignores non-string values', () {
    final json = <dynamic, dynamic>{
      'restToken': ' nvbx_exact ',
      'rest_token': 'nvbx_normalized',
      'serverId': ' server-1 ',
      'profile_id': 123,
    };

    expect(
      navivoxFirstStringFieldFromJson(json, const ['rest_token']),
      'nvbx_normalized',
    );
    expect(
      navivoxFirstStringFieldFromJson(json, const ['token', 'restToken']),
      'nvbx_exact',
    );
    expect(
      navivoxFirstStringFieldFromJson(json, const ['server_id']),
      'server-1',
    );
    expect(navivoxFirstStringFieldFromJson(json, const ['profile_id']), isNull);
  });

  test('strict bool parser accepts only bool values and true/false tokens', () {
    expect(navivoxStrictBoolFromJson(true), isTrue);
    expect(navivoxStrictBoolFromJson(false), isFalse);
    expect(navivoxStrictBoolFromJson(' true '), isTrue);
    expect(navivoxStrictBoolFromJson('FALSE'), isFalse);

    expect(navivoxStrictBoolFromJson('1'), isFalse);
    expect(navivoxStrictBoolFromJson('yes'), isFalse);
    expect(navivoxStrictBoolFromJson(null, fallback: true), isTrue);
  });
}
