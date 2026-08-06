import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package scripts expose Hermes and platform closeout helpers', () {
    final serveWeb = File('serve_web.mjs').readAsStringSync();
    expect(
      serveWeb,
      contains('const relativePath = path.relative(root, filePath)'),
    );
    expect(serveWeb, contains(r'relativePath.startsWith(`..${path.sep}`)'));
    expect(serveWeb, isNot(contains('filePath.startsWith(root)')));
    expect(serveWeb, contains('Invalid JSON request body'));
    expect(serveWeb, contains('server.listen(port, "127.0.0.1"'));

    final packageJson =
        jsonDecode(File('package.json').readAsStringSync())
            as Map<String, Object?>;
    final scripts = (packageJson['scripts'] as Map).cast<String, Object?>();

    const expectedScripts = {
      'hermes:live-smoke': './scripts/run_live_hermes_smoke.sh',
      'hermes:provider-smoke': './scripts/run_provider_hermes_smoke.sh',
      'hermes:provider-smoke:local':
          './scripts/run_local_configured_hermes_provider_smoke.sh',
      'hermes:server-audio-receipt':
          './scripts/record_hermes_server_audio_receipt.sh',
      'hermes:readiness-audit': './scripts/audit_hermes_readiness.sh',
      'android:voice-smoke': './scripts/run_android_voice_smoke.sh',
      'android:hermes-voice-loop-smoke':
          './scripts/run_android_hermes_voice_loop_smoke.sh',
      'android:durable-key-smoke': './scripts/run_android_durable_key_smoke.sh',
      'android:live-mic-prep': './scripts/prepare_android_live_mic_smoke.sh',
      'android:live-mic-receipt':
          './scripts/record_android_live_mic_receipt.sh',
      'platform:workflow-smoke': './scripts/run_hermes_platform_workflow.sh',
      'linux:release-build': './scripts/run_linux_release_build.sh',
    };

    for (final entry in expectedScripts.entries) {
      expect(scripts[entry.key], entry.value, reason: entry.key);
      final helperPath = entry.value.replaceFirst('./', '');
      final helper = File(helperPath);
      expect(helper.existsSync(), isTrue, reason: helperPath);
      expect(
        helper.readAsStringSync(),
        startsWith('#!/usr/bin/env bash\nset -euo pipefail'),
        reason: '$helperPath should fail closed as a bash helper',
      );
      expect(
        helper.statSync().mode & 0x49,
        isNonZero,
        reason: '$helperPath should be executable by at least one class',
      );
    }

    final androidVoiceSmoke = File(
      'scripts/run_android_voice_smoke.sh',
    ).readAsStringSync();
    final androidLoopSmoke = File(
      'scripts/run_android_hermes_voice_loop_smoke.sh',
    ).readAsStringSync();
    final androidDurableKeySmoke = File(
      'scripts/run_android_durable_key_smoke.sh',
    ).readAsStringSync();
    final androidLiveMicPrep = File(
      'scripts/prepare_android_live_mic_smoke.sh',
    ).readAsStringSync();
    final androidLiveMicReceipt = File(
      'scripts/record_android_live_mic_receipt.sh',
    ).readAsStringSync();
    final serverAudioReceipt = File(
      'scripts/record_hermes_server_audio_receipt.sh',
    ).readAsStringSync();
    for (final helperText in [
      androidVoiceSmoke,
      androidLoopSmoke,
      androidDurableKeySmoke,
      androidLiveMicPrep,
      androidLiveMicReceipt,
      serverAudioReceipt,
    ]) {
      expect(helperText, contains('not whole-goal completion evidence'));
      expect(
        helperText,
        contains('WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
      );
    }
    expect(androidVoiceSmoke, contains('Manual continuous-voice closeout'));
    expect(androidLoopSmoke, contains('not physical microphone\naudio input'));
    expect(androidLoopSmoke, contains('provider-backed replies'));
    expect(
      androidDurableKeySmoke,
      contains('not part of active pure-Hermes readiness'),
    );
    expect(
      androidDurableKeySmoke,
      contains(
        'does not prove\nHermes chat, voice, provider, platform, or realtime/server-audio readiness',
      ),
    );
    expect(
      androidLiveMicPrep,
      contains('does not\nprove physical microphone capture'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_PHYSICAL_DEVICE_OBSERVED=true'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_PHYSICAL_MIC_OBSERVED=true'),
    );
    expect(androidLiveMicReceipt, contains('physical_device_observed'));
    expect(androidLiveMicReceipt, contains('physical_mic_observed'));
    expect(androidLiveMicReceipt, contains('WING_ANDROID_TTS_OBSERVED=true'));
    expect(androidLiveMicReceipt, contains('WING_ANDROID_REARM_OBSERVED=true'));
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_NO_SECRET_LEAKS=true'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_SYNTHETIC_AUDIO_USED=false'),
    );
    expect(androidLiveMicReceipt, contains('synthetic_audio_used'));
    expect(androidLiveMicReceipt, contains('android_target_type'));
    expect(androidLiveMicReceipt, contains('physical_device'));
    expect(androidLiveMicReceipt, contains('is_emulator'));
    expect(androidLiveMicReceipt, contains('audio_input_path'));
    expect(androidLiveMicReceipt, contains('physical_android_microphone'));
    expect(androidLiveMicReceipt, contains('local_device_stt_to_hermes_text'));
    expect(
      androidLiveMicReceipt,
      contains('provider_backed_hermes_text_reply'),
    );
    expect(androidLiveMicReceipt, contains('tts_observed_before_rearm'));
    expect(
      androidLiveMicReceipt,
      contains('must contain a short observed non-sensitive excerpt'),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_SECOND_SPOKEN_PHRASE must be a different'),
    );
    expect(
      androidLiveMicReceipt,
      contains(
        'WING_ANDROID_PROVIDER_REPLY must be an observed assistant reply excerpt',
      ),
    );
    expect(
      androidLiveMicReceipt,
      contains('WING_ANDROID_HERMES_URL must be a valid http(s) Hermes origin'),
    );
    expect(androidLiveMicReceipt, contains('distinct_rearmed_turn_observed'));
    expect(androidLiveMicReceipt, contains('hermes_url_sanitized'));
    expect(androidLiveMicReceipt, contains('head_sha'));
    expect(androidLiveMicReceipt, contains('git'));
    expect(androidLiveMicReceipt, contains('rev-parse'));
    expect(androidLiveMicReceipt, contains('device_properties'));
    expect(androidLiveMicReceipt, contains('package_info'));
    expect(androidLiveMicReceipt, contains('pm_path_output'));
    expect(androidLiveMicReceipt, contains('dumpsys'));
    expect(androidLiveMicReceipt, contains('versionName'));
    expect(androidLiveMicReceipt, contains('versionCode'));
    expect(androidLiveMicReceipt, contains('record_audio_granted'));
    expect(
      androidLiveMicReceipt,
      contains(r'android\.permission\.RECORD_AUDIO'),
    );
    expect(androidLiveMicReceipt, contains('ro.product.model'));
    expect(androidLiveMicReceipt, contains('ro.build.fingerprint'));
    expect(androidLiveMicReceipt, contains('urlsplit'));
    expect(androidLiveMicReceipt, contains("rsplit('@', 1)[-1]"));
    expect(
      androidLiveMicReceipt,
      contains("urlunsplit((parts.scheme, netloc, '', '', ''))"),
    );
    expect(androidLiveMicReceipt, contains('SECRET_PATTERN'));
    expect(androidLiveMicReceipt, contains('basic\\s+\\S+'));
    expect(androidLiveMicReceipt, contains('cookie|set-cookie'));
    expect(androidLiveMicReceipt, contains('://[^/\\s@]+@'));
    expect(androidLiveMicReceipt, contains('gh[pousr]_'));
    expect(androidLiveMicReceipt, contains('xox[abprs]-'));
    expect(androidLiveMicReceipt, contains('eyJ[a-z0-9_-]'));
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_TRANSPORT_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_PROVIDER_REPLY_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_PLAYBACK_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_ROUND_TRIP_OBSERVED=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_NO_SECRET_LEAKS=true'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_DEVICE_STT_USED=false'),
    );
    expect(
      serverAudioReceipt,
      contains('WING_HERMES_SERVER_AUDIO_LOCAL_TTS_ONLY=false'),
    );
    expect(serverAudioReceipt, contains('device_stt_used'));
    expect(serverAudioReceipt, contains('local_tts_only'));
    expect(serverAudioReceipt, contains('hermes_server_audio_smoke'));
    expect(serverAudioReceipt, contains('hermes_realtime_or_audio_api'));
    expect(serverAudioReceipt, contains('client_audio_to_hermes_server_audio'));
    expect(
      serverAudioReceipt,
      contains('hermes_server_audio_to_client_playback'),
    );
    expect(serverAudioReceipt, contains('provider_reply_observed'));
    expect(serverAudioReceipt, contains('server_audio_playback_observed'));
    expect(serverAudioReceipt, contains('round_trip_observed'));
    expect(
      serverAudioReceipt,
      contains('short non-sensitive observed excerpt'),
    );
    expect(
      serverAudioReceipt,
      contains('PROVIDER_REPLY must differ from the prompt excerpt'),
    );
    expect(serverAudioReceipt, contains('not Android physical-mic'));
    expect(serverAudioReceipt, contains('whole-goal completion evidence'));
    expect(androidLiveMicReceipt, contains('len(value) > 240'));
    expect(androidLiveMicReceipt, contains('short non-sensitive excerpt'));
    expect(androidLiveMicReceipt, contains('record a non-sensitive excerpt'));
    expect(androidLiveMicReceipt, contains('whole-goal completion'));

    final liveSmoke = File(
      'scripts/run_live_hermes_smoke.sh',
    ).readAsStringSync();
    expect(liveSmoke, contains('lsof -ti:8767'));
    expect(
      liveSmoke,
      contains('stop its owner before running the live Hermes smoke'),
    );
    expect(liveSmoke, contains('API connect/session rendering only'));
    expect(liveSmoke, contains('not provider/model evidence'));
    expect(liveSmoke, contains('not a chat/voice provider smoke'));
    expect(liveSmoke, contains('not physical microphone evidence'));
    expect(liveSmoke, contains('not whole-goal completion evidence'));
    expect(
      liveSmoke,
      contains('WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
    );

    final providerSmoke = File(
      'scripts/run_provider_hermes_smoke.sh',
    ).readAsStringSync();
    expect(
      providerSmoke,
      contains('deterministic transcript voice only'),
      reason: 'provider smoke must not be mistaken for physical mic evidence',
    );
    expect(providerSmoke, contains('not physical microphone evidence'));
    expect(providerSmoke, contains('provider-backed Hermes typed text turn'));
    expect(providerSmoke, contains('deterministic transcript voice turn'));
    expect(providerSmoke, contains('safe_receipt_base_url'));
    expect(providerSmoke, contains('lsof -ti:8767'));
    expect(
      providerSmoke,
      contains('stop its owner before running the provider smoke'),
    );
    expect(providerSmoke, contains('urlsplit'));
    expect(
      providerSmoke,
      contains("urlunsplit((parts.scheme, host, '', '', ''))"),
    );
    expect(providerSmoke, contains('head_sha'));
    expect(providerSmoke, contains('git rev-parse HEAD'));
    expect(providerSmoke, contains('platform workflow publication'));
    expect(providerSmoke, contains('deferred Hermes Desktop parity surfaces'));
    expect(
      providerSmoke,
      contains('does not prove Hermes realtime/server audio'),
    );
    expect(providerSmoke, contains('not whole-goal completion evidence'));
    expect(
      providerSmoke,
      contains('WING_FAIL_ON_BLOCKERS=1 npm run hermes:readiness-audit'),
    );
  });

  test('wing-cli keeps token output explicit', () async {
    const token = 'test-superuser-token';
    final environment = {
      ...Platform.environment,
      'WING_HERMES_URL': 'https://hermes.example',
      'WING_HERMES_TOKEN': token,
    };

    final info = await Process.run('./wing-cli', [
      'info',
    ], environment: environment);
    expect(info.exitCode, 0);
    expect(info.stdout, contains('Hermes Wing connection'));
    expect(info.stdout, contains('https://hermes.example'));
    expect(info.stdout, contains('configured (hidden)'));
    expect(info.stdout, contains('wing-cli qr'));
    expect(info.stdout, contains('wing-cli token'));
    expect(info.stdout, isNot(contains(token)));

    final reveal = await Process.run('./wing-cli', [
      'token',
    ], environment: environment);
    expect(reveal.exitCode, 0);
    expect((reveal.stdout as String).trim(), token);
    expect(reveal.stderr, contains('Hermes Wing access token'));
    expect(reveal.stderr, contains('superuser'));
  });

  test('wing-cli creates a pairing link without exposing the token', () async {
    const token = 'test-superuser-token';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final origin = 'http://${server.address.address}:${server.port}';
    final requestHandled = server.first.then((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/operator/enrollments');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer $token',
      );
      final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map;
      expect(body['label'], 'test-phone');
      expect(body['origin'], origin);

      request.response
        ..statusCode = HttpStatus.created
        ..write(
          jsonEncode({
            'pairing_uri':
                'navivox://connect?origin=${Uri.encodeQueryComponent(origin)}&code=one-time',
          }),
        );
      await request.response.close();
    });

    final link = await Process.run(
      './wing-cli',
      ['link', '--origin', origin, '--label', 'test-phone'],
      environment: {...Platform.environment, 'WING_HERMES_TOKEN': token},
    );
    await requestHandled;

    expect(link.exitCode, 0, reason: link.stderr as String);
    expect(link.stderr, contains('Creating Hermes Wing pairing link'));
    expect(link.stderr, contains('test-phone'));
    expect(link.stderr, contains('short-lived, single-use'));
    final pairing = Uri.parse((link.stdout as String).trim());
    expect(pairing.scheme, 'wing');
    expect(pairing.host, 'connect');
    expect(pairing.queryParameters['origin'], origin);
    expect(pairing.queryParameters['code'], 'one-time');
    expect(link.stdout, isNot(contains(token)));
  });

  test('wing-cli brokers one token once and renders its QR locally', () async {
    const token = 'test-superuser-token';
    const origin = 'http://127.0.0.1:8642';
    final process = await Process.start(
      './wing-cli',
      ['qr', '--origin', origin, '--label', 'test-phone'],
      environment: {
        ...Platform.environment,
        'WING_HERMES_TOKEN': token,
        'WING_CLI_BROKER_HOST': '127.0.0.1',
        'WING_CLI_BROKER_TIMEOUT': '30',
        'WING_CLI_SHOW_LINK': 'true',
      },
    );
    final output = StringBuffer();
    final error = StringBuffer();
    final pairingReady = Completer<Uri>();
    process.stdout.transform(utf8.decoder).listen((chunk) {
      output.write(chunk);
      if (!pairingReady.isCompleted) {
        final match = RegExp(
          r'wing://connect\?[^\s]+',
        ).firstMatch(output.toString());
        if (match != null) pairingReady.complete(Uri.parse(match.group(0)!));
      }
    });
    process.stderr.transform(utf8.decoder).listen(error.write);

    final pairing = await pairingReady.future.timeout(
      const Duration(seconds: 10),
    );
    expect(pairing.queryParameters['origin'], origin);
    final broker = Uri.parse(pairing.queryParameters['broker']!);
    final code = pairing.queryParameters['code']!;
    final client = HttpClient();
    addTearDown(client.close);

    Future<Map<String, Object?>> post(String path) async {
      final request = await client.postUrl(broker.replace(path: path));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'origin': origin, 'code': code}));
      final response = await request.close();
      expect(response.statusCode, HttpStatus.ok);
      return (jsonDecode(await utf8.decoder.bind(response).join()) as Map)
          .cast<String, Object?>();
    }

    final preview = await post('/v1/operator/enrollments/inspect');
    expect(preview['origin'], origin);
    expect(preview['scopes'], ['*']);
    expect(preview.values, isNot(contains(token)));
    final issued = await post('/v1/operator/enrollments/exchange');
    expect(issued['token'], token);

    expect(await process.exitCode, 0, reason: error.toString());
    expect(output.toString(), contains('Hermes Wing QR pairing'));
    expect(output.toString(), contains('Device label'));
    expect(output.toString(), contains('Expires in'));
    expect(output.toString(), contains('\x1b[40m'));
    expect(output.toString(), contains('\x1b[47m'));
    expect(output.toString(), isNot(contains(token)));
  });

  test('Maestro fixtures use the documented canonical paths', () {
    final audit = File(
      'docs/runbooks/hermes-readiness-audit.md',
    ).readAsStringSync();
    for (final path in [
      'scripts/maestro/chat_ux_qa.yaml',
      'scripts/maestro/multi_gateway_chat.yaml',
      'scripts/maestro/gateway_profiles_unsupported_qa.yaml',
      'scripts/maestro/providers_models_unsupported_qa.yaml',
      'scripts/maestro/tools_inventory_qa.yaml',
      'scripts/maestro/office_workspace_qa.yaml',
      'scripts/maestro/schedules_unsupported_qa.yaml',
      'scripts/maestro/gateway_status_qa.yaml',
      'scripts/maestro/gateway_connection_settings_qa.yaml',
      'scripts/maestro/session_metadata_qa.yaml',
      'scripts/maestro/session_bulk_selection_qa.yaml',
      'scripts/maestro/session_branch_qa.yaml',
      'scripts/maestro/chat_concurrent_sessions_qa.yaml',
      'scripts/maestro/chat_process_recovery_qa.yaml',
    ]) {
      final flow = File(path);
      final command = 'maestro check-syntax $path';
      expect(flow.existsSync(), isTrue, reason: path);
      expect(flow.readAsStringSync(), contains(command), reason: path);
      expect(audit, contains('`$command`'), reason: path);
    }
  });

  test('Maestro fixtures omit environment-specific sensitive data', () {
    final flows = Directory(
      'scripts/maestro',
    ).listSync().whereType<File>().where((file) => file.path.endsWith('.yaml'));
    for (final flow in flows) {
      final content = flow.readAsStringSync();
      final forbidden = [
        RegExp(r'(?:https?|wing)://'),
        RegExp(
          r'(api[_-]?key|authorization|bearer|password|token|secret)\s*[:=]',
          caseSensitive: false,
        ),
        RegExp(
          r'(?<![\d.])(?:10\.|192\.168\.|172\.(?:1[6-9]|2\d|3[01])\.|100\.)',
        ),
        RegExp(r'\beyJ[A-Za-z0-9_-]{12,}\.[A-Za-z0-9_-]{8,}'),
      ];
      for (final pattern in forbidden) {
        expect(content, isNot(matches(pattern)), reason: flow.path);
      }
      expect(
        content,
        isNot(matches(RegExp(r'assertVisible:.*·\s*(online|offline)'))),
        reason: '${flow.path} must not bind to a local gateway label',
      );

      var isolatedChat = false;
      for (final line in content.split('\n')) {
        if (line.contains('tapOn:') && line.contains('New session')) {
          isolatedChat = true;
        }
        final safeNonChatScreenshot =
            line.contains('contacts') ||
            line.contains('inventory') ||
            line.contains('status') ||
            line.contains('fail_closed');
        if (line.contains('takeScreenshot:') &&
            !safeNonChatScreenshot &&
            !isolatedChat) {
          fail('${flow.path} captures a live transcript before isolation');
        }
      }
    }
  });

  test('wing-link installer creates a runnable global command', () async {
    final installDir = await Directory.systemTemp.createTemp(
      'wing-link-install-',
    );
    addTearDown(() => installDir.delete(recursive: true));

    final install = await Process.run('./install-wing-link.sh', [
      '--prefix',
      installDir.path,
    ]);
    expect(install.exitCode, 0, reason: install.stderr as String);

    final installed = File('${installDir.path}/wing-link');
    expect(installed.existsSync(), isTrue);
    expect(installed.statSync().mode & 0x49, isNonZero);

    final version = await Process.run(installed.path, ['version']);
    expect(version.exitCode, 0);
    expect(version.stdout, contains('dev'));
  });
}
