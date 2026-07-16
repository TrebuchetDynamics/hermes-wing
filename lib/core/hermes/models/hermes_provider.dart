import '../../protocol/wing_json.dart';

/// A provider row as advertised by `GET /api/providers`, plus write-only
/// credential presence.
///
/// Hermes Wing is a key-setter, never a key-reader: [keyHint] is the single
/// sanctioned derived disclosure (a masked last-4-only hint such as
/// `····ab12`) and is `null` when no credential is set. No field on this
/// model ever holds a full secret — the value written by
/// [HermesApiClient.setProviderCredential] is transmitted write-only and is
/// never echoed back by the server or stored on the client.
class HermesProvider {
  const HermesProvider({
    required this.slug,
    required this.label,
    required this.authType,
    this.envVars = const [],
    this.configured = false,
    this.keyHint,
  });

  /// Parses one provider row defensively. Rows whose [slug] is blank must be
  /// discarded by callers (see `HermesApiClient.listProviders`) because a
  /// provider without a stable slug cannot be addressed or scoped.
  factory HermesProvider.fromJson(Map<String, Object?> json) {
    return HermesProvider(
      slug: wingStringFromJson(json['slug'], fallback: ''),
      label: wingStringFromJson(json['label'], fallback: ''),
      authType: wingStringFromJson(json['auth_type'], fallback: ''),
      envVars: wingStringListFromJson(json['env_vars']),
      configured: wingBoolFromJson(json['configured']),
      keyHint: wingOptionalStringFromJson(json['key_hint']),
    );
  }

  final String slug;
  final String label;
  final String authType;
  final List<String> envVars;
  final bool configured;

  /// Masked last-4-only presence hint (e.g. `····ab12`) or `null` when unset.
  /// NEVER a full credential.
  final String? keyHint;
}

/// Outcome of `POST /api/providers/{slug}/credential/validate`. Carries only a
/// boolean result and a non-secret detail string — never the credential.
class HermesCredentialProbe {
  const HermesCredentialProbe({required this.ok, this.detail = ''});

  factory HermesCredentialProbe.fromJson(Map<String, Object?> json) {
    return HermesCredentialProbe(
      ok: wingBoolFromJson(json['ok']),
      detail: wingStringFromJson(json['detail'], fallback: ''),
    );
  }

  final bool ok;
  final String detail;
}
