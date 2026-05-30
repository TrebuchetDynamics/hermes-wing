import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/profile_contacts/profile_contact_avatar.dart';

import '../shared/app/test_material_app.dart';
import '../shared/fixtures/profile_contact_fixtures.dart';

final _profile = mineruBuilderProfile(
  serverLabel: 'Local Gormes',
  latestPreview: '',
);

void main() {
  testWidgets('renders a stable Profile contact initial and semantics label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      TestMaterialScaffold(body: ProfileContactAvatar(contact: _profile)),
    );

    expect(find.text('M'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Mineru Builder profile avatar'),
      findsOneWidget,
    );

    final text = tester.widget<Text>(find.text('M'));
    expect(text.style?.color, Colors.white);

    final avatar = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = avatar.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;
    expect(decoration.shape, BoxShape.circle);
    expect(gradient.colors, const [Color(0xffff9500), Color(0xffff2d55)]);
    semantics.dispose();
  });
}
