import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';

// Run both phases inside a fresh dbus-run-session with an unlocked test keyring
// and isolated XDG directories. The second phase must be a new app process.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final receipt = Platform.environment['WING_KEYRING_RECEIPT'];
  final phase = Platform.environment['WING_KEYRING_PHASE'];
  if (Platform.environment['WING_ISOLATED_KEYRING'] != '1' ||
      receipt == null ||
      !{'write', 'verify'}.contains(phase)) {
    throw StateError(
      'An isolated keyring and explicit write/verify phase are required.',
    );
  }
  testWidgets(
    'Linux keyring $phase preserves separate Agent and Wing Link credentials',
    (tester) async {
      final store = SecureHermesEndpointStore();
      String digest(String value) =>
          sha256.convert(utf8.encode(value)).toString();
      if (phase == 'write') {
        final random = Random.secure();
        String credential() =>
            base64Url.encode(List.generate(32, (_) => random.nextInt(256)));
        final agent = credential();
        final link = credential();
        await store.save(
          profileId: 'linux-keyring-regression',
          baseUrl: 'http://127.0.0.1:18642',
          apiKey: agent,
          wingLinkOrigin: 'http://127.0.0.1:18643',
          wingLinkToken: link,
        );
        // Only high-entropy credential digests cross the process boundary outside
        // secure storage; plaintext credentials never enter ordinary preferences.
        await File(receipt).writeAsString(
          jsonEncode({'agent': digest(agent), 'link': digest(link)}),
        );
        final prefs = await SharedPreferences.getInstance();
        final values = prefs
            .getKeys()
            .map((key) => prefs.get(key).toString())
            .join('\n');
        expect(values.contains(agent) || values.contains(link), isFalse);
      } else {
        final expected = jsonDecode(await File(receipt).readAsString()) as Map;
        final saved = await store.load();
        expect(saved != null, isTrue);
        expect(saved!.apiKey != null && saved.wingLinkToken != null, isTrue);
        expect(digest(saved.apiKey!) == expected['agent'], isTrue);
        expect(digest(saved.wingLinkToken!) == expected['link'], isTrue);
        expect(saved.apiKey != saved.wingLinkToken, isTrue);
        await store.clear();
        expect(await SecureHermesEndpointStore().load() == null, isTrue);
      }
    },
  );
}
