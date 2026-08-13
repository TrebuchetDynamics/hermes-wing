import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/presentation/hermes_rich_text.dart';

void main() {
  test('presentation package exposes transcript rich text', () {
    expect(const HermesRichText('answer'), isA<HermesRichText>());
  });
}
