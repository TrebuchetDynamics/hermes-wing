import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/hermes_m2_observer_main.dart' as qa;
import '../../integration_test/support/m2_observer.dart';

void main() {
  test(
    'REG-DEFAULT: actual main refuses without scheduling runtime work',
    () async {
      var scheduled = 0;
      final result = await runZoned(
        () async {
          final pending = qa.main();
          expect(scheduled, 0);
          await pending;
          final result = await m2Bootstrap();
          expect(result.code, 'not_admitted');
          expect(result.continuation, 'continuation_unavailable');
          return result;
        },
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, duration, callback) {
            scheduled++;
            return parent.createTimer(zone, duration, callback);
          },
          createPeriodicTimer: (self, parent, zone, duration, callback) {
            scheduled++;
            return parent.createPeriodicTimer(zone, duration, callback);
          },
        ),
      );
      expect(result.qualifies, isFalse);
      await Future<void>.value();
      expect(scheduled, 0);
    },
  );
}
