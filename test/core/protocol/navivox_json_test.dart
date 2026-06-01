import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/protocol/navivox_json.dart';

void main() {
  group('navivox map coercion', () {
    test('ignores non-string map keys instead of throwing', () {
      final result = navivoxMapFromJson({
        'id': 'mem-1',
        404: 'not-json-object-field',
        const Symbol('debug'): true,
      });

      expect(result, {'id': 'mem-1'});
    });

    test('keeps valid maps from loose lists and drops invalid-key entries', () {
      final result = navivoxMapListFromJson([
        {'id': 'mem-1'},
        {404: 'not-json-object-field'},
        'not-a-map',
      ]);

      expect(result, [
        {'id': 'mem-1'},
        <String, Object?>{},
      ]);
    });
  });
}
