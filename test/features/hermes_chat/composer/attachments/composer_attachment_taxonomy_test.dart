import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/composer/attachments/staged_attachment.dart';

void main() {
  test('composer package owns staged attachments', () {
    const attachment = StagedTextAttachment(name: 'note.txt', content: 'text');
    expect(attachment.name, 'note.txt');
  });
}
