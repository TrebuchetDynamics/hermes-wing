import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/protocol/wing_json.dart';

void main() {
  test('wire field values prefer exact aliases before canonical matches', () {
    final json = <dynamic, dynamic>{
      'serverId': 'server-camel',
      'server_id': 'server-snake',
      'profileID': 'profile-case',
    };

    expect(wingCanonicalWireFieldName('server_id'), 'serverid');
    expect(wingCanonicalWireFieldNames(const ['server_id', 'profileId']), {
      'serverid',
      'profileid',
    });
    expect(wingWireFieldValuesFromAliases(json, const ['server_id']).toList(), [
      'server-snake',
      'server-camel',
    ]);
    expect(
      wingWireFieldValuesFromAliases(json, const ['profile_id']).toList(),
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
      wingFirstStringFieldFromJson(json, const ['rest_token']),
      'nvbx_normalized',
    );
    expect(
      wingFirstStringFieldFromJson(json, const ['token', 'restToken']),
      'nvbx_exact',
    );
    expect(wingFirstStringFieldFromJson(json, const ['server_id']), 'server-1');
    expect(
      wingFirstStringFieldFromJson(
        <dynamic, dynamic>{
          'rest_token': ' ',
          'restToken': 'nvbx_alias_fallback',
        },
        const ['rest_token'],
      ),
      'nvbx_alias_fallback',
    );
    expect(wingFirstStringFieldFromJson(json, const ['profile_id']), isNull);
  });

  test('strict bool parser accepts only bool values and true/false tokens', () {
    expect(wingStrictBoolFromJson(true), isTrue);
    expect(wingStrictBoolFromJson(false), isFalse);
    expect(wingStrictBoolFromJson(' true '), isTrue);
    expect(wingStrictBoolFromJson('FALSE'), isFalse);

    expect(wingStrictBoolFromJson('1'), isFalse);
    expect(wingStrictBoolFromJson('yes'), isFalse);
    expect(wingStrictBoolFromJson(null, fallback: true), isTrue);
  });

  test('map list parser keeps maps and ignores malformed entries', () {
    final maps = wingMapListFromJson([
      {'id': 'one', 'score': 1},
      'skip',
      {'id': 'two'},
    ]);

    expect(maps, [
      {'id': 'one', 'score': 1},
      {'id': 'two'},
    ]);
    expect(wingMapListFromJson('not-list'), isEmpty);
  });

  test(
    'value from wire trims tokens and falls back for blank or unknown values',
    () {
      expect(
        wingValueFromWire<_WireChoice>(
          value: ' beta ',
          values: _WireChoice.values,
          wireValue: (choice) => choice.wireValue,
          fallback: _WireChoice.alpha,
        ),
        _WireChoice.beta,
      );
      expect(
        wingValueFromWire<_WireChoice>(
          value: 'missing',
          values: _WireChoice.values,
          wireValue: (choice) => choice.wireValue,
          fallback: _WireChoice.alpha,
        ),
        _WireChoice.alpha,
      );
      expect(
        wingValueFromWire<_WireChoice>(
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
