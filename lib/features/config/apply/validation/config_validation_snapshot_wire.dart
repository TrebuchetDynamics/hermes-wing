import '../../form/config_wire_fields.dart';

class ConfigValidationSnapshotWire {
  const ConfigValidationSnapshotWire(this.snapshot);

  final Map<String, Object?> snapshot;

  Object? get validationErrors => configWirePopulatedValueFromAliases(
    snapshot,
    const ['validation_errors'],
  );

  Object? get genericErrors => configWirePopulatedValueFromAliases(
    snapshot,
    const ['errors', 'generic_errors'],
  );

  Object? get fieldErrors =>
      configWirePopulatedValueFromAliases(snapshot, const ['field_errors']);
}
