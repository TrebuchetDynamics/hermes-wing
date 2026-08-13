import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/profiles/screens/profiles_screen.dart';

void main() {
  test('profiles feature exposes ProfilesScreen', () {
    expect(const ProfilesScreen(), isA<ProfilesScreen>());
  });
}
