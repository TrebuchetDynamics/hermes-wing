import '../../protocol/wing_json.dart';

/// One auxiliary task-slot assignment from `GET /api/models`
/// (`auxiliary[]`). Each entry names the task slot and the provider/model
/// assigned to it; `provider` defaults to `auto` when unset.
class HermesAuxiliaryModel {
  const HermesAuxiliaryModel({
    required this.task,
    required this.provider,
    required this.model,
    this.baseUrl = '',
  });

  factory HermesAuxiliaryModel.fromJson(Map<String, Object?> json) {
    return HermesAuxiliaryModel(
      task: wingStringFromJson(json['task'], fallback: ''),
      provider: wingStringFromJson(json['provider'], fallback: ''),
      model: wingStringFromJson(json['model'], fallback: ''),
      baseUrl: wingStringFromJson(json['base_url'], fallback: ''),
    );
  }

  final String task;
  final String provider;
  final String model;
  final String baseUrl;
}

/// The active/auxiliary model assignment for a profile, returned by
/// `GET /api/models` and by `PUT /api/models/assignment`. [revision] is the
/// opaque optimistic-concurrency token echoed back as `If-Match` on writes.
class HermesModelAssignment {
  const HermesModelAssignment({
    this.activeProvider = '',
    this.activeModel = '',
    this.auxiliary = const [],
    this.revision = '',
  });

  /// Parses the `active`/`auxiliary`/`revision` fields present at the top level
  /// of both the `GET /api/models` body and the `PUT /api/models/assignment`
  /// response.
  factory HermesModelAssignment.fromJson(Map<String, Object?> json) {
    final active = wingMapFieldFromJson(json, 'active');
    return HermesModelAssignment(
      activeProvider: wingStringFromJson(active['provider'], fallback: ''),
      activeModel: wingStringFromJson(active['model'], fallback: ''),
      auxiliary: wingMapListFromJson(
        json['auxiliary'],
      ).map(HermesAuxiliaryModel.fromJson).toList(growable: false),
      revision: wingStringFromJson(json['revision'], fallback: ''),
    );
  }

  final String activeProvider;
  final String activeModel;
  final List<HermesAuxiliaryModel> auxiliary;
  final String revision;
}

/// A single curated model within a catalog provider block.
class HermesCatalogModel {
  const HermesCatalogModel({required this.id, this.description = ''});

  factory HermesCatalogModel.fromJson(Map<String, Object?> json) {
    return HermesCatalogModel(
      id: wingStringFromJson(json['id'], fallback: ''),
      description: wingStringFromJson(json['description'], fallback: ''),
    );
  }

  final String id;
  final String description;
}

/// A provider block within the model catalog manifest, with its curated
/// models.
class HermesCatalogProvider {
  const HermesCatalogProvider({required this.provider, this.models = const []});

  final String provider;
  final List<HermesCatalogModel> models;
}

/// The cached model catalog manifest from `GET /api/models` (`catalog`) and
/// the refreshed manifest from `POST /api/models/refresh`.
///
/// The wire shape is `{"providers": {"<name>": {"models": [{"id", ...}]}}}`;
/// parsing is defensive so a missing/renamed field yields an empty catalog
/// rather than throwing.
class HermesModelCatalog {
  const HermesModelCatalog({this.providers = const []});

  factory HermesModelCatalog.fromJson(Object? raw) {
    final providersJson = wingMapFieldFromJson(
      wingMapFromJson(raw),
      'providers',
    );
    final providers = <HermesCatalogProvider>[];
    for (final entry in providersJson.entries) {
      final block = wingMapFromJson(entry.value);
      final models = wingMapListFromJson(block['models'])
          .map(HermesCatalogModel.fromJson)
          .where((model) => model.id.isNotEmpty)
          .toList(growable: false);
      providers.add(HermesCatalogProvider(provider: entry.key, models: models));
    }
    return HermesModelCatalog(providers: providers);
  }

  final List<HermesCatalogProvider> providers;
}

/// The combined catalog + assignment returned by `GET /api/models`. Held in
/// channel state as the single model-selection surface.
class HermesModelInventory {
  const HermesModelInventory({
    this.catalog = const HermesModelCatalog(),
    this.assignment = const HermesModelAssignment(),
  });

  factory HermesModelInventory.fromJson(Map<String, Object?> json) {
    return HermesModelInventory(
      catalog: HermesModelCatalog.fromJson(json['catalog']),
      assignment: HermesModelAssignment.fromJson(json),
    );
  }

  final HermesModelCatalog catalog;
  final HermesModelAssignment assignment;

  /// Returns a copy with a new [assignment] but the existing [catalog]
  /// (used after `PUT /api/models/assignment`, which returns no catalog).
  HermesModelInventory withAssignment(HermesModelAssignment next) {
    return HermesModelInventory(catalog: catalog, assignment: next);
  }

  /// Returns a copy with a new [catalog] but the existing [assignment]
  /// (used after `POST /api/models/refresh`, which returns only the catalog).
  HermesModelInventory withCatalog(HermesModelCatalog next) {
    return HermesModelInventory(catalog: next, assignment: assignment);
  }
}
