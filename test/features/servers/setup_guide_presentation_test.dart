import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/servers/setup/setup_guide_presentation.dart';

void main() {
  const presentation = SetupGuidePresentation();

  test('exposes ordered Termux setup guide copy actions', () {
    expect(presentation.introCopy, contains('Same-device setup'));
    expect(presentation.introCopy, contains('gormes navivox pair'));
    expect(presentation.introCopy, contains('gateway status'));

    expect(
      presentation.visibleEntries.map((entry) => entry.id).toList(),
      const [SetupGuideEntryId.bootstrap],
    );

    expect(presentation.entries.map((entry) => entry.id).toList(), const [
      SetupGuideEntryId.bootstrap,
      SetupGuideEntryId.navivoxPairHandoff,
    ]);
    expect(presentation.entries.map((entry) => entry.label).toList(), const [
      'Copy one-paste bootstrap',
      'Copy fix instructions',
    ]);
  });

  test('keeps clipboard payloads safe and statused', () {
    for (final entry in presentation.entries) {
      expect(entry.clipboardText, isNotEmpty, reason: entry.label);
      expect(entry.successMessage, startsWith('Copied'), reason: entry.label);
      expect(
        entry.failureMessage,
        startsWith('Could not copy'),
        reason: entry.label,
      );
      expect(
        entry.clipboardText.toLowerCase(),
        isNot(contains('nvbx_')),
        reason: entry.label,
      );
    }

    final bootstrap = presentation.entry(SetupGuideEntryId.bootstrap);
    expect(bootstrap.clipboardText, contains('one pasted Termux command'));
    expect(bootstrap.clipboardText, contains('less install.sh'));
    expect(
      bootstrap.clipboardText,
      contains('GORMES_SKIP_SETUP=1 bash install.sh'),
    );
    expect(bootstrap.clipboardText.toLowerCase(), isNot(contains('curl | sh')));
  });

  test('owns setup guide copy success and failure messages', () {
    expect(
      presentation.entries.map((entry) => entry.successMessage).toList(),
      const [
        'Copied one-paste Termux bootstrap.',
        'Copied Navivox fix instructions.',
      ],
    );
    expect(
      presentation.entries.map((entry) => entry.failureMessage).toList(),
      const [
        'Could not copy one-paste bootstrap.',
        'Could not copy Navivox fix instructions.',
      ],
    );
  });
}
