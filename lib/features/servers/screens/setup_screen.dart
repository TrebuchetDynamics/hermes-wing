import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/channel/navivox_channel_provider.dart';
import '../../../router/app_routes.dart';

const termuxGormesBootstrapCommands = r'''
printf '%s\n' 'This is one pasted Termux command for Navivox setup.' && \
pkg upgrade -y && \
pkg install -y git curl && \
curl -fsSLO https://github.com/TrebuchetDynamics/gormes-agent/releases/latest/download/install.sh && \
printf '%s\n' 'Review install.sh in the pager. Press q to continue install, or Ctrl-C to abort.' && \
less install.sh && \
GORMES_SKIP_SETUP=1 bash install.sh && \
(gormes navivox pair || gormes navivox connect-info)
''';

const termuxDownloadLinks = '''
Termux install sources:
- Official site: https://termux.dev/en/
- Preferred Android package: https://f-droid.org/packages/com.termux/
- Official GitHub Releases: https://github.com/termux/termux-app/releases

Use one signing source for Termux and plugins. Do not mix F-Droid, GitHub, or other APK sources on the same install.
''';

const termuxPostInstallChecks = '''
After bash install.sh finishes in Termux, run these checks:

gormes version
gormes doctor --offline
gormes navivox connect-info

If connect-info prints a pairing token, paste it only into Navivox. Do not share tokens in logs, screenshots, issues, or chat transcripts.
''';

const termuxNavivoxPairHandoff = '''
Navivox pair handoff target:
The goal is one terminal interaction maximum: install Termux, paste one command, then continue setup in Navivox.

After Gormes installs, choose Navivox (recommended) when prompted. If the installer prints the recommended next step, run:

gormes navivox pair

That command should start local bridge, generate a pairing token, show a QR, print localhost URL, and wait for Navivox connection.

In Navivox, scan/import the QR or paste the base URL and token here. If this Gormes build does not offer pair yet, run gormes navivox connect-info and paste those values into Navivox only.

Navivox does not install APKs or run Termux commands for you. Do not share pairing tokens in logs, screenshots, issues, or chat transcripts.
''';

const termuxGatewayLifecycle = '''
Termux gateway foreground/tmux lifecycle:
Run the Gormes gateway in a Termux foreground tmux session, then use status and connect-info from another Termux session.

tmux new-session -s gormes-gateway "gormes gateway"
gormes gateway status
gormes navivox connect-info
gormes gateway stop

termux-wake-lock and Android battery settings are best-effort only. Android may still stop background processes.
Paste pairing tokens only into Navivox; do not share tokens in logs or screenshots.
''';

const termuxBootHelper = '''
Optional Termux:Boot gateway auto-start helper:
Only use this after Gormes works manually in Termux and after installing the Termux:Boot plugin from the same APK source as Termux.

Commands:
gormes gateway boot-install
gormes gateway status
gormes navivox connect-info

Rollback:
gormes gateway boot-uninstall

The boot-install command writes ~/.termux/boot/gormes-gateway.sh. Reboot Android to let Termux:Boot start the tmux gateway, then verify with gormes gateway status.
Android may still stop background processes. Navivox does not install APKs or run these commands for you.
''';

const termuxSameDeviceConnectionHint = '''
Navivox connection hints:
- Same Android device (Gormes in Termux): use the loopback URL printed by `gormes navivox connect-info`, usually http://127.0.0.1:<port>.
- Android emulator to host Gormes: use http://10.0.2.2:<port>.
- Physical Android device to separate host Gormes: use the LAN, VPN, or Tailscale URL from `gormes navivox connect-info`.

Paste pairing tokens only into Navivox. Do not share tokens in logs, screenshots, issues, or chat transcripts.
''';

const termuxOptionalStorageCommand = '''
Optional Termux shared-storage access:
Only run this if you need to move logs, screenshots, or exported files between Android storage and Termux.

Command:
termux-setup-storage

Android will show an Android storage permission prompt. This is not required for the normal Gormes install path.
''';

typedef SetupQrImageImporter = Future<SetupQrImageImport?> Function();

class SetupQrImageImport {
  const SetupQrImageImport({this.baseUrl, this.token});

  final String? baseUrl;
  final String? token;

  bool get hasValues => baseUrl != null || token != null;
}

class SetupQrImageImportException implements Exception {
  const SetupQrImageImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({this.qrImageImporter, super.key});

  final SetupQrImageImporter? qrImageImporter;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _baseUrlController = TextEditingController(
    text: 'http://127.0.0.1:8765',
  );
  final _tokenController = TextEditingController();
  bool _connecting = false;
  bool _showToken = false;
  bool _importingQr = false;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navivox')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connect to Gormes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Scan/import the QR from `gormes navivox pair`; use '
                    '`gormes navivox connect-info` only as fallback.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Android emulator: use http://10.0.2.2:<port> for '
                        'a host gateway. On a physical Android device, use '
                        'the host LAN, VPN, or Tailscale URL from connect-info.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Gateway base URL',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Pairing token',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Import QR image',
                            icon: _importingQr
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.qr_code_scanner),
                            onPressed: _connecting || _importingQr
                                ? null
                                : _importQrImage,
                          ),
                          IconButton(
                            tooltip: _showToken
                                ? 'Hide pairing token'
                                : 'Show pairing token',
                            icon: Icon(
                              _showToken
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _showToken = !_showToken);
                            },
                          ),
                        ],
                      ),
                    ),
                    obscureText: !_showToken,
                  ),
                  if (_status != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _status!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _connecting ? null : _connectGateway,
                    icon: _connecting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.hub),
                    label: const Text('Connect and talk'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    const Text(
                      'Run `gormes navivox connect-info` on the host and retry.',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Run Gormes on this Android device with Termux: '
                            'install Termux from F-Droid or official GitHub '
                            'Releases, then paste one command from Navivox. '
                            'The command updates packages, installs git/curl, '
                            'downloads and pauses for `install.sh` review, '
                            'then installs Gormes. After Gormes installs, '
                            'choose Navivox (recommended) '
                            'and run `gormes navivox pair` to continue setup '
                            'in Navivox. Navivox cannot silently install '
                            'Gormes; if pair is not available in this Gormes '
                            'build, use the connect-info fallback and paste '
                            '`gormes navivox connect-info` values here.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxCommands,
                            icon: const Icon(Icons.content_copy),
                            label: const Text('Copy one-paste bootstrap'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxDownloadLinks,
                            icon: const Icon(Icons.link),
                            label: const Text('Copy Termux download links'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxPostInstallChecks,
                            icon: const Icon(Icons.checklist),
                            label: const Text('Copy post-install checks'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxNavivoxPairHandoff,
                            icon: const Icon(Icons.qr_code_2),
                            label: const Text('Copy Navivox pair handoff'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxGatewayLifecycle,
                            icon: const Icon(Icons.terminal),
                            label: const Text('Copy Termux gateway lifecycle'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxBootHelper,
                            icon: const Icon(Icons.power_settings_new),
                            label: const Text('Copy Termux:Boot helper'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxConnectionHint,
                            icon: const Icon(Icons.device_hub),
                            label: const Text(
                              'Copy same-device connection hint',
                            ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _copyTermuxStorageCommand,
                            icon: const Icon(Icons.folder_shared),
                            label: const Text('Copy optional storage command'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importQrImage() async {
    setState(() {
      _importingQr = true;
      _error = null;
      _status = null;
    });
    try {
      final importer = widget.qrImageImporter ?? importNavivoxQrImage;
      final result = await importer();
      if (!mounted) return;
      if (result == null || !result.hasValues) {
        setState(() => _status = 'No QR image selected.');
        return;
      }
      setState(() {
        if (result.baseUrl != null) {
          _baseUrlController.text = result.baseUrl!;
        }
        if (result.token != null) {
          _tokenController.text = result.token!;
        }
        _status = 'Imported QR connection details.';
      });
    } on SetupQrImageImportException {
      if (mounted) {
        setState(() => _error = 'Could not read a Navivox QR image.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not read a Navivox QR image.');
      }
    } finally {
      if (mounted) setState(() => _importingQr = false);
    }
  }

  Future<void> _connectGateway() async {
    setState(() {
      _connecting = true;
      _error = null;
      _status = null;
    });
    try {
      await ref
          .read(gatewayNavivoxChannelProvider)
          .connect(
            baseUrl: _baseUrlController.text.trim(),
            token: _tokenController.text.trim(),
          );
      if (mounted) context.go(AppRoutes.chats);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not connect to Gormes gateway.');
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _copyTermuxCommands() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(
        const ClipboardData(text: termuxGormesBootstrapCommands),
      );
      if (mounted) {
        setState(() => _status = 'Copied one-paste Termux bootstrap.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy one-paste bootstrap.');
      }
    }
  }

  Future<void> _copyTermuxDownloadLinks() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(const ClipboardData(text: termuxDownloadLinks));
      if (mounted) {
        setState(() => _status = 'Copied Termux download links.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy Termux download links.');
      }
    }
  }

  Future<void> _copyTermuxPostInstallChecks() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(
        const ClipboardData(text: termuxPostInstallChecks),
      );
      if (mounted) {
        setState(() => _status = 'Copied post-install Termux checks.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy post-install checks.');
      }
    }
  }

  Future<void> _copyTermuxNavivoxPairHandoff() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(
        const ClipboardData(text: termuxNavivoxPairHandoff),
      );
      if (mounted) {
        setState(() => _status = 'Copied Navivox pair handoff.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy Navivox pair handoff.');
      }
    }
  }

  Future<void> _copyTermuxGatewayLifecycle() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(
        const ClipboardData(text: termuxGatewayLifecycle),
      );
      if (mounted) {
        setState(() => _status = 'Copied Termux gateway lifecycle.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy gateway lifecycle.');
      }
    }
  }

  Future<void> _copyTermuxBootHelper() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(const ClipboardData(text: termuxBootHelper));
      if (mounted) {
        setState(() => _status = 'Copied Termux:Boot helper.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy Termux:Boot helper.');
      }
    }
  }

  Future<void> _copyTermuxConnectionHint() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(
        const ClipboardData(text: termuxSameDeviceConnectionHint),
      );
      if (mounted) {
        setState(() => _status = 'Copied same-device connection hint.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy connection hint.');
      }
    }
  }

  Future<void> _copyTermuxStorageCommand() async {
    setState(() {
      _error = null;
      _status = null;
    });
    try {
      await Clipboard.setData(
        const ClipboardData(text: termuxOptionalStorageCommand),
      );
      if (mounted) {
        setState(() => _status = 'Copied optional Termux storage command.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not copy storage command.');
      }
    }
  }
}

Future<SetupQrImageImport?> importNavivoxQrImage() async {
  final image = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (image == null) return null;

  final scanner = MobileScannerController(autoStart: false);
  try {
    final capture = await scanner.analyzeImage(
      image.path,
      formats: const [BarcodeFormat.qrCode],
    );
    for (final barcode in capture?.barcodes ?? const <Barcode>[]) {
      final payload = barcode.rawValue ?? barcode.displayValue;
      if (payload == null) continue;
      final result = parseNavivoxQrPayload(payload);
      if (result != null && result.hasValues) return result;
    }
    throw const SetupQrImageImportException(
      'No Navivox connection details were found in the QR image.',
    );
  } on SetupQrImageImportException {
    rethrow;
  } on UnsupportedError {
    throw const SetupQrImageImportException(
      'QR image import is not supported on this platform.',
    );
  } catch (_) {
    throw const SetupQrImageImportException(
      'Could not read a Navivox QR image.',
    );
  } finally {
    scanner.dispose();
  }
}

SetupQrImageImport? parseNavivoxQrPayload(String payload) {
  final text = payload.trim();
  if (text.isEmpty) return null;

  final jsonResult = _parseQrJsonPayload(text);
  if (jsonResult != null && jsonResult.hasValues) return jsonResult;

  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) {
    final token = _firstNonEmpty([
      uri.queryParameters['token'],
      uri.queryParameters['pairing_token'],
      uri.queryParameters['pairingToken'],
      uri.queryParameters['auth_token'],
      uri.queryParameters['rest_token'],
      uri.queryParameters['restToken'],
    ]);
    final queryBaseUrl = _normalizeBaseUrl(
      _firstNonEmpty([
        uri.queryParameters['base_url'],
        uri.queryParameters['baseUrl'],
        uri.queryParameters['gateway_url'],
        uri.queryParameters['url'],
      ]),
    );

    if (queryBaseUrl != null || token != null) {
      return SetupQrImageImport(baseUrl: queryBaseUrl, token: token);
    }
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return SetupQrImageImport(baseUrl: _originFromUri(uri), token: token);
    }
  }

  final baseUrl = _normalizeBaseUrl(_firstUrl(text));
  final token = _firstToken(text);
  if (baseUrl != null || token != null) {
    return SetupQrImageImport(baseUrl: baseUrl, token: token);
  }
  return null;
}

SetupQrImageImport? _parseQrJsonPayload(String text) {
  Object? decoded;
  try {
    decoded = jsonDecode(text);
  } catch (_) {
    return null;
  }
  if (decoded is! Map) return null;

  final topLevelToken = _stringField(decoded, const [
    'token',
    'pairing_token',
    'pairingToken',
    'auth_token',
  ]);
  final topLevelBaseUrl = _normalizeBaseUrl(
    _stringField(decoded, const ['base_url', 'baseUrl', 'gateway_url', 'url']),
  );
  if (topLevelBaseUrl != null || topLevelToken != null) {
    return SetupQrImageImport(baseUrl: topLevelBaseUrl, token: topLevelToken);
  }

  final entries = decoded['entries'];
  if (entries is List) {
    for (final entry in entries) {
      if (entry is! Map) continue;
      final baseUrl = _normalizeBaseUrl(
        _stringField(entry, const [
          'base_url',
          'baseUrl',
          'gateway_url',
          'url',
        ]),
      );
      final token = _stringField(entry, const [
        'token',
        'pairing_token',
        'pairingToken',
        'auth_token',
      ]);
      if (baseUrl != null || token != null) {
        return SetupQrImageImport(baseUrl: baseUrl, token: token);
      }
    }
  }
  return null;
}

String? _stringField(Map<dynamic, dynamic> map, List<String> names) {
  for (final name in names) {
    final exact = _asNonEmptyString(map[name]);
    if (exact != null) return exact;
  }
  final normalizedNames = {for (final name in names) _normalizeKey(name)};
  for (final entry in map.entries) {
    if (!normalizedNames.contains(_normalizeKey('${entry.key}'))) continue;
    final value = _asNonEmptyString(entry.value);
    if (value != null) return value;
  }
  return null;
}

String _normalizeKey(String value) => value.toLowerCase().replaceAll('_', '');

String? _asNonEmptyString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final text = _asNonEmptyString(value);
    if (text != null) return text;
  }
  return null;
}

String? _firstUrl(String text) {
  var value = RegExp(r'https?://\S+').firstMatch(text)?.group(0);
  while (value != null &&
      value.isNotEmpty &&
      ',;)]}"'.contains(value[value.length - 1])) {
    value = value.substring(0, value.length - 1);
  }
  return value;
}

String? _firstToken(String text) {
  final lower = text.toLowerCase();
  const labels = [
    'pairing token',
    'pairing_token',
    'pairing-token',
    'auth token',
    'auth_token',
    'auth-token',
    'token',
  ];
  for (final label in labels) {
    for (final separator in const [':', '=']) {
      final needle = '$label$separator';
      final index = lower.indexOf(needle);
      if (index < 0) continue;
      final token = _readTokenAt(text, index + needle.length);
      if (token != null) return token;
    }
  }

  final navivoxIndex = lower.indexOf('nvbx_');
  return navivoxIndex < 0 ? null : _readTokenAt(text, navivoxIndex);
}

String? _readTokenAt(String text, int start) {
  var index = start;
  while (index < text.length && text.codeUnitAt(index) <= 32) {
    index++;
  }
  final tokenStart = index;
  while (index < text.length && _isTokenChar(text.codeUnitAt(index))) {
    index++;
  }
  if (index == tokenStart) return null;
  return text.substring(tokenStart, index);
}

bool _isTokenChar(int codeUnit) {
  return (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5a) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7a) ||
      codeUnit == 0x2d ||
      codeUnit == 0x2e ||
      codeUnit == 0x2f ||
      codeUnit == 0x3a ||
      codeUnit == 0x3d ||
      codeUnit == 0x5f ||
      codeUnit == 0x7e ||
      codeUnit == 0x2b;
}

String? _normalizeBaseUrl(String? raw) {
  final value = _asNonEmptyString(raw);
  if (value == null) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return value;
  if (uri.scheme != 'http' && uri.scheme != 'https') return value;
  return _originFromUri(uri);
}

String _originFromUri(Uri uri) {
  final host = uri.host.contains(':') ? '[${uri.host}]' : uri.host;
  final port = uri.hasPort ? ':${uri.port}' : '';
  return '${uri.scheme}://$host$port';
}
