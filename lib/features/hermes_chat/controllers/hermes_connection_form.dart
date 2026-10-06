// ignore_for_file: prefer_initializing_formals

import 'package:flutter/widgets.dart';

/// One in-flight connect attempt, captured before the await so the result can
/// be checked against what the operator had typed at the time.
@immutable
class HermesConnectionAttempt {
  const HermesConnectionAttempt({
    required this.id,
    required this.baseUrl,
    required this.apiKey,
    required this.label,
  });

  /// Monotonic id; a newer attempt supersedes this one.
  final int id;

  /// Normalized origin this attempt connected to.
  final String baseUrl;

  /// Trimmed credential, or null when the operator left it blank.
  final String? apiKey;

  /// Sanitized, trimmed profile label.
  final String label;

  /// The credential as the endpoint store expects it: blank becomes absent.
  String? get storedApiKey => apiKey == null || apiKey!.isEmpty ? null : apiKey;

  /// The label as the endpoint store expects it: blank becomes absent.
  String? get storedLabel => label.isEmpty ? null : label;
}

/// Owns the Hermes connect form's fields and its attempt-staleness rule.
///
/// Connecting awaits the network, and during that await the operator can edit
/// any field, pick a saved profile, or start a newer attempt. [isStale] is the
/// single place that decides whether a finished attempt still describes what
/// they want, so a slow connect cannot persist a superseded endpoint.
///
/// The controllers are exposed directly because the form fields bind to them
/// and callers already set text; wrapping them in pass-throughs would add
/// indirection without removing any.
class HermesConnectionForm extends ChangeNotifier {
  HermesConnectionForm({
    required String Function(String value) normalizeBaseUrl,
    required String Function(String value) sanitizeLabel,
    String initialBaseUrl = '',
  }) : _normalizeBaseUrl = normalizeBaseUrl,
       _sanitizeLabel = sanitizeLabel,
       baseUrl = TextEditingController(text: initialBaseUrl) {
    for (final field in [baseUrl, apiKey, label]) {
      var previousText = field.text;
      field.addListener(() {
        if (field.text == previousText) return;
        previousText = field.text;
        _hasFieldIntent = true;
        _intentGeneration++;
      });
    }
  }

  final String Function(String value) _normalizeBaseUrl;
  final String Function(String value) _sanitizeLabel;

  final TextEditingController baseUrl;
  final TextEditingController apiKey = TextEditingController();
  final TextEditingController label = TextEditingController();

  bool _obscureApiKey = true;
  int _attemptId = 0;
  bool _hasFieldIntent = false;
  int _intentGeneration = 0;

  /// Invalidates awaited reads even after edit-and-return or same-value actions.
  /// Selection and credential masking alone do not supersede connection intent.
  int get intentGeneration => _intentGeneration;

  /// Saved reads may autofill only until the first edit or explicit selection.
  /// Unlike connect staleness, this remembers edit-and-return and same-value
  /// presets. Focus, selection and credential visibility are not field intent.
  bool get hasFieldIntent => _hasFieldIntent;

  /// Whether the credential field is masked.
  bool get obscureApiKey => _obscureApiKey;

  void toggleApiKeyVisibility() {
    _obscureApiKey = !_obscureApiKey;
    notifyListeners();
  }

  /// Current origin, normalized the way a connect would send it.
  String get normalizedBaseUrl => _normalizeBaseUrl(baseUrl.text);

  /// Current credential, trimmed.
  String get trimmedApiKey => apiKey.text.trim();

  /// Current profile label, sanitized and trimmed.
  String get sanitizedLabel => _sanitizeLabel(label.text).trim();

  /// Opens a new attempt, superseding any earlier one.
  HermesConnectionAttempt beginAttempt({
    required String baseUrl,
    String? apiKey,
  }) {
    _intentGeneration++;
    return HermesConnectionAttempt(
      id: ++_attemptId,
      baseUrl: _normalizeBaseUrl(baseUrl),
      apiKey: apiKey?.trim(),
      label: sanitizedLabel,
    );
  }

  /// Supersedes any in-flight attempt without opening a new one.
  void abandonAttempt() {
    _attemptId += 1;
    _intentGeneration++;
  }

  /// Whether [attempt] no longer matches the operator's current intent.
  ///
  /// True when a newer attempt started, or when any field changed while this
  /// one was awaiting the network.
  bool isStale(HermesConnectionAttempt attempt) =>
      attempt.id != _attemptId ||
      normalizedBaseUrl != attempt.baseUrl ||
      trimmedApiKey != (attempt.apiKey ?? '') ||
      sanitizedLabel != attempt.label;

  /// Fills the form from a saved endpoint profile.
  void applyProfile({required String baseUrl, String? apiKey, String? label}) {
    _hasFieldIntent = true;
    _intentGeneration++;
    this.baseUrl.text = baseUrl;
    this.apiKey.text = apiKey ?? '';
    this.label.text = label ?? '';
  }

  /// Resets every field, keeping [baseUrl] when one is supplied.
  void clear({String? keepBaseUrl}) {
    _hasFieldIntent = true;
    _intentGeneration++;
    baseUrl.text = keepBaseUrl ?? '';
    apiKey.clear();
    label.clear();
  }

  @override
  void dispose() {
    baseUrl.dispose();
    apiKey.dispose();
    label.dispose();
    super.dispose();
  }
}
