import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/apply/config_apply_flow_model.dart';
import 'package:navivox/features/config/form/config_form_model.dart';
import 'package:navivox/features/config/presentation/config_section_presentation.dart';

void main() {
  test('presents section metadata fields validation and editing state', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'providers',
            'label': 'Provider and Models',
            'description': 'Model and provider defaults.',
            'fields': ['providers.default', 'model.temperature'],
          },
        ],
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
          {
            'path': 'model.temperature',
            'label': 'Temperature',
            'type': 'number',
          },
        ],
      },
      values: const {'providers.default': 'openai', 'model.temperature': 0.4},
    );
    final applyFlow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {
        'providers.default': 'local',
        'model.temperature': 0.8,
      },
      validationSnapshot: const {
        'field_errors': {
          'providers.default': ['Provider is not available.'],
        },
      },
    );

    final section = ConfigSectionPresentation.fromSection(
      form.sections.single,
      applyFlow: applyFlow,
      editingField: 'model.temperature',
    );

    expect(section.id, 'providers');
    expect(section.label, 'Provider and Models');
    expect(section.description, 'Model and provider defaults.');
    expect(section.hasDescription, isTrue);
    expect(section.fields, hasLength(2));

    final provider = section.fields[0];
    expect(provider.field.path, 'providers.default');
    expect(provider.field.label, 'Default provider');
    expect(provider.field.validationMessages, ['Provider is not available.']);
    expect(provider.isEditing, isFalse);

    final temperature = section.fields[1];
    expect(temperature.field.path, 'model.temperature');
    expect(temperature.field.label, 'Temperature');
    expect(temperature.isEditing, isTrue);
  });

  test('normalizes blank descriptions without leaking widget concerns', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'sections': [
          {
            'id': 'gateway',
            'label': 'Navivox Gateway',
            'description': '   ',
            'fields': ['navivox.exposure_mode'],
          },
        ],
        'fields': [
          {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
        ],
      },
      values: const {'navivox.exposure_mode': 'local'},
    );

    final section = ConfigSectionPresentation.fromSection(
      form.sections.single,
      applyFlow: ConfigApplyFlowModel.fromDraft(
        form: form,
        draftValues: const {},
      ),
    );

    expect(section.id, 'gateway');
    expect(section.label, 'Navivox Gateway');
    expect(section.description, isNull);
    expect(section.hasDescription, isFalse);
    expect(section.fields.single.field.path, 'navivox.exposure_mode');
    expect(section.fields.single.isEditing, isFalse);
  });
}
