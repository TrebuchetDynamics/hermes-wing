import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/widgets/hermes_profile_avatar.dart';

void main() {
  test(
    'primary appearance and named profile color follow official defaults',
    () {
      expect(HermesProfileAvatar.shapeFor('default'), 'squircle');
      expect(HermesProfileAvatar.colorFor('default'), const Color(0xff8b5cf6));
      // Official JS hashString('coder') is 94834725, hence hue 285.
      expect(
        HermesProfileAvatar.colorFor('coder'),
        HSLColor.fromAHSL(1, 285, .68, .58).toColor(),
      );
      expect(HermesProfileAvatar.shapeFor('coder'), 'drop');
    },
  );
  testWidgets(
    'all official fallback shapes render without creature preferences',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Wrap(
            children: [
              for (var i = 0; i < 21; i++)
                HermesProfileAvatar(profileId: 'profile-$i'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HermesProfileAvatar), findsNWidgets(21));
      expect(tester.takeException(), isNull);
    },
  );
}
