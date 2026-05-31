import '../../models/connection_import.dart';
import '../../shared/connection_import_parser.dart';
import 'navivox_platform_connect_intent_payload.dart';

/// Parses the platform-channel shape used by Android connect intents.
///
/// Native code may deliver either a plain payload string or a map containing
/// the payload plus handoff provenance metadata.
SetupQrImageImport? parseNavivoxConnectIntentPayload(Object? payload) {
  final normalized = NavivoxPlatformConnectIntentPayload.from(payload);
  if (normalized == null) return null;

  final parsed = parseNavivoxConnectionImportPayload(normalized.text);
  if (parsed == null) return null;
  return parsed.withSource(normalized.source);
}
