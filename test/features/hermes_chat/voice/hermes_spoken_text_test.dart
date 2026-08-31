import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/voice/hermes_spoken_text.dart';

void main() {
  test('converts assistant Markdown into speech-friendly text', () {
    expect(
      hermesSpokenText('''
## Result

Use **safe** [documentation](https://example.com) with `inline code`.

- First step
- Second step

![Status chart](data:image/png;base64,AAAA)
'''),
      '''Result

Use safe documentation with inline code.

First step
Second step

Status chart''',
    );
  });

  test('does not speak leaked tool payloads', () {
    expect(
      hermesSpokenText(
        'Before <some_tool>{"command":"raw-command-value"}'
        '</some_tool> after',
      ),
      'Before [tool activity hidden] after',
    );
  });
}
