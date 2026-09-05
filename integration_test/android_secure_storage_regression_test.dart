import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/core/hermes/setup/secure_hermes_endpoint_store.dart';
import 'package:wing/features/voice/services/platform/device_speech_recognition_availability.dart';

// Run write, rotate, then verify in separate processes, using the isolated QA
// application ID and --no-uninstall. No credential travels in build defines.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment('WING_DEVICE_STORAGE_PHASE');
  if (!Platform.isAndroid || !{'write', 'rotate', 'verify'}.contains(phase)) {
    throw StateError('Android and an explicit storage phase are required.');
  }
  final processName = File(
    '/proc/self/cmdline',
  ).readAsStringSync().split('\x00').first;
  if (processName != 'com.trebuchetdynamics.hermes.wing.qa') {
    throw StateError('Storage regression requires the isolated QA package.');
  }
  testWidgets('Android secure storage $phase across app processes', (
    tester,
  ) async {
    final store = SecureHermesEndpointStore();
    final prefs = await SharedPreferences.getInstance();
    const receiptKey = 'android-secure-storage-regression-digests';
    String digest(String value) =>
        sha256.convert(utf8.encode(value)).toString();
    String credential() {
      final random = Random.secure();
      return base64Url.encode(List.generate(32, (_) => random.nextInt(256)));
    }

    if (phase == 'write') {
      expect(
        await store.load() == null,
        isTrue,
        reason: 'Use a fresh, isolated QA installation.',
      );
      final agent = credential();
      final link = credential();
      await store.save(
        profileId: 'android-storage-regression',
        baseUrl: 'http://127.0.0.1:18642',
        apiKey: agent,
        wingLinkOrigin: 'http://127.0.0.1:18643',
        wingLinkToken: link,
      );
      await prefs.setString(
        receiptKey,
        jsonEncode({'agent': digest(agent), 'link': digest(link)}),
      );
    } else {
      final receipt = prefs.getString(receiptKey);
      expect(receipt != null, isTrue);
      final expected = jsonDecode(receipt!) as Map;
      final saved = await store.load();
      expect(saved != null, isTrue);
      expect(saved!.apiKey != null && saved.wingLinkToken != null, isTrue);
      // Boolean comparisons prevent a failing test from printing credentials.
      expect(digest(saved.apiKey!) == expected['agent'], isTrue);
      expect(digest(saved.wingLinkToken!) == expected['link'], isTrue);
      expect(saved.apiKey != saved.wingLinkToken, isTrue);
      expect(saved.baseUrl == 'http://127.0.0.1:18642', isTrue);
      expect(saved.wingLinkOrigin == 'http://127.0.0.1:18643', isTrue);
      if (phase == 'rotate') {
        final rotated = credential();
        await store.save(
          profileId: saved.id,
          baseUrl: saved.baseUrl,
          apiKey: rotated,
          wingLinkOrigin: saved.wingLinkOrigin,
          wingLinkToken: saved.wingLinkToken,
        );
        await prefs.setString(
          receiptKey,
          jsonEncode({'agent': digest(rotated), 'link': expected['link']}),
        );
      }
    }

    final saved = (await store.load())!;
    final ordinaryValues = prefs
        .getKeys()
        .map((key) => prefs.get(key).toString())
        .join('\n');
    expect(ordinaryValues.contains(saved.apiKey!), isFalse);
    expect(ordinaryValues.contains(saved.wingLinkToken!), isFalse);
    if (phase == 'verify') {
      await store.clear();
      expect(await SecureHermesEndpointStore().load() == null, isTrue);
      await prefs.remove(receiptKey);
    }
  });
  testWidgets('Android native voice readiness with permission $phase', (
    tester,
  ) async {
    const probe = MethodChannelDeviceSpeechRecognitionDiagnosticsProbe();
    final diagnostics = await probe.read();
    expect(diagnostics.microphonePermissionGranted, phase == 'rotate');
    expect(diagnostics.recognitionServiceCount, greaterThan(0));
    final readiness = await checkDefaultVoiceCaptureReadiness();
    expect(
      readiness.available,
      phase == 'rotate' && diagnostics.onDeviceRecognitionAvailable == true,
    );
    // Report capabilities only; this test never starts recognition or recording.
    debugPrint(
      'Native voice: onDevice=${diagnostics.onDeviceRecognitionAvailable}, '
      'permission=${diagnostics.microphonePermissionGranted}, '
      'ready=${readiness.available}',
    );
  });
  testWidgets('Android native TTS enumerates an installed voice', (
    tester,
  ) async {
    final tts = FlutterTts();
    final languages = await tts.getLanguages;
    expect(languages is List && languages.isNotEmpty, isTrue);
    await tts.stop();
  });
}
