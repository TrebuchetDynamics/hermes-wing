import '../apply/config_apply_flow_model.dart';
import '../form/config_field_presentation.dart';
import '../form/config_form_model.dart';

class ConfigSectionPresentation {
  const ConfigSectionPresentation._({
    required this.id,
    required this.label,
    required this.description,
    required this.fields,
  });

  factory ConfigSectionPresentation.fromSection(
    ConfigFormSection section, {
    required ConfigApplyFlowModel applyFlow,
    String? editingField,
  }) {
    return ConfigSectionPresentation._(
      id: section.id,
      label: section.label,
      description: section.description,
      fields: [
        for (final row in section.rows)
          ConfigSectionFieldPresentation(
            field: ConfigFieldPresentation.fromRow(
              row,
              validationMessages: applyFlow.validationMessagesFor(row.field),
            ),
            isEditing: editingField == row.field,
          ),
      ],
    );
  }

  final String id;
  final String label;
  final String? description;
  final List<ConfigSectionFieldPresentation> fields;

  bool get hasDescription => description != null;
}

class ConfigSectionFieldPresentation {
  const ConfigSectionFieldPresentation({
    required this.field,
    required this.isEditing,
  });

  final ConfigFieldPresentation field;
  final bool isEditing;
}
