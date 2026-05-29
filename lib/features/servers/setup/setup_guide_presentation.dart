class SetupGuidePresentation {
  const SetupGuidePresentation();

  String get introCopy =>
      'Same-device setup: install Termux from F-Droid or official GitHub '
      'Releases, paste the bootstrap command, then run `gormes navivox pair`. '
      'Navivox should open from the pairing link. If Android only offers QR/image '
      'import or the gateway status looks wrong, copy these instructions and fix '
      'the host setup from Termux/Gormes instead of guessing inside Navivox.';

  String get operatorFixInstructions => _operatorFixInstructions;

  List<SetupGuideEntry> get entries => _entries;

  List<SetupGuideEntry> get visibleEntries => entries
      .where((entry) => entry.id == SetupGuideEntryId.bootstrap)
      .toList();

  SetupGuideEntry entry(SetupGuideEntryId id) =>
      entries.firstWhere((entry) => entry.id == id);
}

enum SetupGuideEntryId { bootstrap, navivoxPairHandoff }

class SetupGuideEntry {
  const SetupGuideEntry({
    required this.id,
    required this.label,
    required this.clipboardText,
    required this.successMessage,
    required this.failureMessage,
  });

  final SetupGuideEntryId id;
  final String label;
  final String clipboardText;
  final String successMessage;
  final String failureMessage;
}

const _entries = [
  SetupGuideEntry(
    id: SetupGuideEntryId.bootstrap,
    label: 'Copy one-paste bootstrap',
    clipboardText: _termuxGormesBootstrapCommands,
    successMessage: 'Copied one-paste Termux bootstrap.',
    failureMessage: 'Could not copy one-paste bootstrap.',
  ),
  SetupGuideEntry(
    id: SetupGuideEntryId.navivoxPairHandoff,
    label: 'Copy fix instructions',
    clipboardText: _operatorFixInstructions,
    successMessage: 'Copied Navivox fix instructions.',
    failureMessage: 'Could not copy Navivox fix instructions.',
  ),
];

const _termuxGormesBootstrapCommands = r'''
printf '%s\n' 'This is one pasted Termux command for Navivox setup.' && \
pkg upgrade -y && \
pkg install -y git curl && \
curl -fsSLO https://github.com/TrebuchetDynamics/gormes-agent/releases/latest/download/install.sh && \
printf '%s\n' 'Review install.sh in the pager. Press q to continue install, or Ctrl-C to abort.' && \
less install.sh && \
GORMES_SKIP_SETUP=1 bash install.sh && \
(gormes navivox pair || gormes navivox connect-info)
''';

const _operatorFixInstructions = '''
Navivox operator fix instructions:

1. In Termux on the same Android device or on the host machine, run:

gormes navivox status

2. If the gateway is not running/listening, run:

gormes navivox pair

3. Keep that command open until Navivox connects. It should start the local bridge, generate a pairing token, show a QR/link, print the base URL, and wait for the Navivox connection.

4. In Navivox, prefer the pairing link that opens the app automatically. If that does not work, import the QR image or paste only the base URL and pairing token shown by Gormes.

5. If Navivox still cannot connect, run:

gormes navivox connect-info

Then use the LAN/VPN/Tailscale URL shown there; 127.0.0.1 only works when Navivox and Gormes are on the same Android environment. Android emulator host gateway usually uses 10.0.2.2.

Do not share pairing tokens in logs, screenshots, issues, or chat transcripts.
''';
