import 'package:flutter_test/flutter_test.dart';
import 'package:wing/shared/presentation/count_labels.dart';

void main() {
  test('formats singular, regular plural, and custom plural count labels', () {
    expect(countLabel(1, 'profile'), '1 profile');
    expect(countLabel(2, 'profile'), '2 profiles');
    expect(countLabel(1, 'entry', plural: 'entries'), '1 entry');
    expect(countLabel(2, 'entry', plural: 'entries'), '2 entries');
  });
}
