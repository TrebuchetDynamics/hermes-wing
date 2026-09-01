import '../../protocol/wing_json.dart';

const _maxModelOptionProviders = 64;
const _maxModelOptionModels = 256;

/// A selectable provider/model row from Hermes Agent's authoritative
/// `GET /api/model/options` picker inventory.
class HermesModelOptionProvider {
  const HermesModelOptionProvider({
    required this.slug,
    required this.label,
    required this.models,
    this.authenticated = false,
    this.isCurrent = false,
    this.isUserDefined = false,
    this.source = '',
  });

  factory HermesModelOptionProvider.fromJson(Map<String, Object?> json) {
    final models = <String>[];
    for (final value in wingStringListFromJson(json['models'])) {
      final model = _bounded(value, 200);
      if (model.isNotEmpty && !models.contains(model)) {
        models.add(model);
      }
      if (models.length == _maxModelOptionModels) break;
    }
    return HermesModelOptionProvider(
      slug: _bounded(
        wingStringFromJson(json['slug'] ?? json['provider'], fallback: ''),
        80,
      ),
      label: _bounded(
        wingStringFromJson(json['label'] ?? json['name'], fallback: ''),
        160,
      ),
      models: List.unmodifiable(models),
      authenticated: wingBoolFromJson(json['authenticated']),
      isCurrent: wingBoolFromJson(json['is_current']),
      isUserDefined: wingBoolFromJson(json['is_user_defined']),
      source: _bounded(wingStringFromJson(json['source'], fallback: ''), 80),
    );
  }

  final String slug;
  final String label;
  final List<String> models;
  final bool authenticated;
  final bool isCurrent;
  final bool isUserDefined;
  final String source;

  /// Matches Desktop's remote picker policy without treating the full
  /// unconfigured provider catalog as selectable.
  bool get selectable =>
      authenticated ||
      isCurrent ||
      isUserDefined ||
      source == 'user-config' ||
      source == 'custom';
}

/// The Agent-owned provider/model inventory used for session-scoped selection.
class HermesModelOptions {
  const HermesModelOptions({
    required this.providers,
    this.currentProvider = '',
    this.currentModel = '',
  });

  factory HermesModelOptions.fromJson(Map<String, Object?> json) {
    final providers = <HermesModelOptionProvider>[];
    for (final value in wingMapListFromJson(json['providers'])) {
      final provider = HermesModelOptionProvider.fromJson(value);
      if (provider.slug.isEmpty || provider.models.isEmpty) continue;
      providers.add(provider);
      if (providers.length == _maxModelOptionProviders) break;
    }
    return HermesModelOptions(
      providers: List.unmodifiable(providers),
      currentProvider: _bounded(
        wingStringFromJson(json['provider'], fallback: ''),
        80,
      ),
      currentModel: _bounded(
        wingStringFromJson(json['model'], fallback: ''),
        200,
      ),
    );
  }

  final List<HermesModelOptionProvider> providers;
  final String currentProvider;
  final String currentModel;

  List<HermesModelOptionProvider> get selectableProviders => providers
      .where((provider) => provider.selectable)
      .toList(growable: false);
}

/// Backend-confirmed session model lock returned by
/// `POST /api/sessions/{session_id}/model`.
class HermesSessionModelLock {
  const HermesSessionModelLock({
    required this.sessionId,
    required this.provider,
    required this.model,
    this.routeSource = '',
    this.accepted = false,
  });

  factory HermesSessionModelLock.fromJson(Map<String, Object?> json) {
    final runtime = wingMapFromJson(json['runtime']);
    return HermesSessionModelLock(
      sessionId: _bounded(
        wingStringFromJson(json['session_id'], fallback: ''),
        200,
      ),
      provider: _bounded(
        wingStringFromJson(runtime['provider'], fallback: ''),
        80,
      ),
      model: _bounded(wingStringFromJson(runtime['model'], fallback: ''), 200),
      routeSource: _bounded(
        wingStringFromJson(runtime['route_source'], fallback: ''),
        80,
      ),
      accepted:
          wingStringFromJson(runtime['model_lock'], fallback: '') ==
              'accepted' ||
          wingBoolFromJson(json['accepted']),
    );
  }

  final String sessionId;
  final String provider;
  final String model;
  final String routeSource;
  final bool accepted;
}

String _bounded(String value, int maxLength) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.length > maxLength) return '';
  if (trimmed.contains(RegExp(r'[\r\n\x00]'))) return '';
  return trimmed;
}
