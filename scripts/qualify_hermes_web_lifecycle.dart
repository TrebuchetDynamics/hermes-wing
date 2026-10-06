import 'dart:convert';
import 'dart:io';
import 'package:wing/core/hermes/client/hermes_web_read_client.dart';

/// Native no-inference lifecycle only. Generated owned auth arrives on stdin.
Future<void> main() async {
  final input =
      jsonDecode(await stdin.transform(utf8.decoder).join())
          as Map<String, dynamic>;
  final origin = Uri.parse(input['origin'] as String);
  final credential = input['credential'] as String;
  final assertions = <String, bool>{};
  final blockers = <String, int?>{};
  final clients = <HermesWebReadClient>[];
  HermesWebReadClient client(String? auth, {String profile = 'default'}) {
    final value = HermesWebReadClient.forQualification(
      origin: origin,
      credential: auth,
      profile: profile,
      timeout: const Duration(seconds: 30),
    );
    clients.add(value);
    return value;
  }

  void check(String name, bool condition) {
    assertions[name] = condition;
    if (!condition) throw StateError('qualification assertion failed');
  }

  Future<void> rejection(
    String name,
    Future<Object?> Function() action,
    HermesWebFailureKind kind, {
    int? code,
  }) async {
    try {
      await action();
      throw StateError('rejection absent');
    } on HermesWebReadException catch (error) {
      check(
        name,
        error.kind == kind && (code == null || error.rpcCode == code),
      );
    }
  }

  Future<void> interruptProbe(String name, HermesWebLifecycle adapter) async {
    try {
      assertions[name] = await adapter.interrupt();
    } on HermesWebReadException catch (error) {
      assertions[name] = false;
      blockers[name] = error.rpcCode;
    }
  }

  try {
    final owned = client(credential);
    final lifecycle = await owned.connectLifecycleForQualification();
    await lifecycle.createSession();
    check(
      'native_clean_create_distinct_runtime_stored_ids',
      lifecycle.runtimeSessionId != lifecycle.storedSessionId &&
          lifecycle.turns.isEmpty,
    );
    final draft = lifecycle.recovery;
    await interruptProbe('native_exact_idle_interrupt', lifecycle);
    final reconnected = await owned.connectLifecycleForQualification();
    await reconnected.recover(draft);
    check(
      'native_fresh_ticket_reconnect_live_draft_resume_history',
      reconnected.storedSessionId == draft.storedSessionId &&
          reconnected.turns.isEmpty,
    );
    await reconnected.resumeSession('wing-lifecycle-empty-durable');
    check(
      'native_durable_agentless_resume_canonical_empty_history',
      reconnected.storedSessionId == 'wing-lifecycle-empty-durable' &&
          reconnected.turns.isEmpty,
    );
    await interruptProbe('native_durable_exact_idle_interrupt', reconnected);
    final persisted = reconnected.recovery;
    final again = await owned.connectLifecycleForQualification();
    await again.recover(persisted);
    check(
      'native_durable_reconnect_and_authorization_stays_unsupported',
      again.storedSessionId == persisted.storedSessionId &&
          again.productAuthorization ==
              HermesWebProductAuthorization.unsupportedAuthorization,
    );
    final missing = await client(
      credential,
      profile: 'missing-qualification-profile',
    ).connectLifecycleForQualification();
    await rejection(
      'native_missing_profile_create_4064',
      missing.createSession,
      HermesWebFailureKind.rpc,
      code: 4064,
    );
    await rejection(
      'native_missing_profile_resume_4064',
      () => missing.resumeSession('wing-lifecycle-empty-durable'),
      HermesWebFailureKind.rpc,
      code: 4064,
    );
    for (final entry in {
      'anonymous': null,
      'wrong': 'invalid-qualification',
    }.entries) {
      await rejection(
        'native_${entry.key}_lifecycle_ticket_rejected',
        client(entry.value).connectLifecycleForQualification,
        HermesWebFailureKind.authentication,
      );
    }
    stdout.writeln(
      jsonEncode({
        'assertions': assertions,
        'blockers': blockers,
        'inference_exercised': false,
        'prompt_events_approvals_exercised_live': false,
      }),
    );
    if (assertions.values.any((value) => !value)) exitCode = 1;
  } catch (error) {
    stdout.writeln(
      jsonEncode({
        'assertions': assertions,
        'blockers': blockers,
        'failure': error is HermesWebReadException
            ? error.kind.name
            : 'qualification',
        if (error is HermesWebReadException) 'rpc_code': error.rpcCode,
      }),
    );
    exitCode = 1;
  } finally {
    for (final value in clients) {
      value.disconnect();
    }
  }
}
