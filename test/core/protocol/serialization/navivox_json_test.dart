import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_json.dart';

void main() {
  test('wire field values prefer exact aliases before canonical matches', () {
    final json = <dynamic, dynamic>{
      'serverId': 'server-camel',
      'server_id': 'server-snake',
      'profileID': 'profile-case',
    };

    expect(navivoxCanonicalWireFieldName('server_id'), 'serverid');
    expect(navivoxCanonicalWireFieldNames(const ['server_id', 'profileId']), {
      'serverid',
      'profileid',
    });
    expect(
      navivoxWireFieldValuesFromAliases(json, const ['server_id']).toList(),
      ['server-snake', 'server-camel'],
    );
    expect(
      navivoxWireFieldValuesFromAliases(json, const ['profile_id']).toList(),
      ['profile-case'],
    );
  });

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
    expect(
      navivoxFirstStringFieldFromJson(
        <dynamic, dynamic>{
          'rest_token': ' ',
          'restToken': 'nvbx_alias_fallback',
        },
        const ['rest_token'],
      ),
      'nvbx_alias_fallback',
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

  test('map list parser keeps maps and ignores malformed entries', () {
    final maps = navivoxMapListFromJson([
      {'id': 'one', 'score': 1},
      'skip',
      {'id': 'two'},
    ]);

    expect(maps, [
      {'id': 'one', 'score': 1},
      {'id': 'two'},
    ]);
    expect(navivoxMapListFromJson('not-list'), isEmpty);
  });

  test(
    'value from wire trims tokens and falls back for blank or unknown values',
    () {
      expect(
        navivoxValueFromWire<_WireChoice>(
          value: ' beta ',
          values: _WireChoice.values,
          wireValue: (choice) => choice.wireValue,
          fallback: _WireChoice.alpha,
        ),
        _WireChoice.beta,
      );
      expect(
        navivoxValueFromWire<_WireChoice>(
          value: 'missing',
          values: _WireChoice.values,
          wireValue: (choice) => choice.wireValue,
          fallback: _WireChoice.alpha,
        ),
        _WireChoice.alpha,
      );
      expect(
        navivoxValueFromWire<_WireChoice>(
          value: ' ',
          values: _WireChoice.values,
          wireValue: (choice) => choice.wireValue,
          fallback: _WireChoice.alpha,
        ),
        _WireChoice.alpha,
      );
    },
  );
}

enum _WireChoice {
  alpha('alpha'),
  beta('beta');

  const _WireChoice(this.wireValue);

  final String wireValue;
}
