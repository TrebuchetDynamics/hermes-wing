import 'package:flutter/foundation.dart';

import 'hermes_approval_request.dart';
import '../models/hermes_approval_decision.dart';
import '../models/hermes_profile.dart';
import '../models/hermes_provider.dart';
import 'hermes_channel_state.dart';

export 'hermes_approval_request.dart';
export '../models/hermes_approval_decision.dart';
export '../models/hermes_model_assignment.dart';
export '../models/hermes_profile.dart';
export '../models/hermes_provider.dart';
export 'hermes_channel_state.dart';

/// Native Hermes Agent channel: sessions, streamed chat turns, and the
/// device-transcript voice-run lifecycle. Deliberately does not implement
/// `NavivoxChannel` — see docs/adr/0007-native-hermes-channel-not-navivox-channel-adapter.md.
abstract interface class HermesChannel implements Listenable {
  HermesChannelState get state;

  Future<void> connect({required String baseUrl, String? apiKey});
  Future<void> disconnect();

  Future<void> selectSession(String sessionId);
  Future<void> createSession({String? title});
  Future<void> renameSession({
    required String sessionId,
    required String title,
  });
  Future<void> deleteSession(String sessionId);
  Future<void> forkSession(String sessionId, {String? title});

  /// Selects [profileId] as the client-local active profile. This never calls
  /// a server active-profile endpoint; it refreshes the profile list and the
  /// profile-owned sessions/inventory using the mandatory `profile` query.
  Future<void> selectProfile(String profileId);

  Future<void> createProfile({required String name, String? cloneFrom});
  Future<void> renameProfile({
    required String profileId,
    required String name,
    required String revision,
  });
  Future<void> deleteProfile({
    required String profileId,
    required String revision,
  });
  Future<HermesProfileSoul> readProfileSoul(String profileId);
  Future<void> writeProfileSoul({
    required String profileId,
    required String soul,
    required String revision,
  });

  /// Loads the provider list + write-only credential presence for the selected
  /// profile into `state.providers`. All requests carry the mandatory
  /// `profile` query; no field ever holds a raw key.
  Future<void> loadProviders();

  /// Sets a provider credential (write-only). [value] is sent to the server but
  /// is never stored in state or returned — only presence is reconciled.
  Future<void> setProviderCredential({
    required String slug,
    required String envVar,
    required String value,
  });

  Future<void> removeProviderCredential({
    required String slug,
    required String envVar,
  });

  Future<HermesCredentialProbe> validateProviderCredential({
    required String slug,
  });

  /// Loads the cached model catalog + assignment into `state.modelInventory`.
  Future<void> loadModels();

  /// Triggers the one gated outbound catalog refresh, replacing the catalog in
  /// `state.modelInventory` while preserving the current assignment.
  Future<void> refreshModels();

  /// Assigns a model to a slot with an `If-Match` precondition on [revision].
  Future<void> assignModel({
    required String scope,
    String? task,
    required String provider,
    required String model,
    required String revision,
  });

  Future<void> sendText(String text);

  /// Cancels the in-flight streaming turn on the client side only. Prefer
  /// [stopActiveTurn] when `/v1/runs` transport is active so the server
  /// actually stops the run.
  void cancelActiveTurn();

  /// Stops the active turn on the server (`/v1/runs/{run_id}/stop`) when run
  /// transport is active, and always cancels the local stream subscription.
  void stopActiveTurn();

  /// Emits approval requests raised by an active run
  /// (`/v1/runs/{run_id}/events` `approval.request`). Empty when run
  /// transport isn't in use.
  Stream<HermesApprovalRequest> get approvalRequests;

  Future<void> respondToApproval({
    required String approvalId,
    required HermesApprovalDecision decision,
  });

  String startVoiceRun();
  void stageVoiceRunTranscript({
    required String voiceRunId,
    required String transcript,
    required Duration duration,
    required double confidence,
  });
  void submitVoiceRun(String voiceRunId);
  void cancelVoiceRun(String voiceRunId, {String reason = 'cancelled'});
  void failVoiceRun(String voiceRunId, {required String reason});
}
