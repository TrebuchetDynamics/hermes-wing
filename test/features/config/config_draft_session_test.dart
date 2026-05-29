import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/apply/config_apply_flow_model.dart';
import 'package:navivox/features/config/form/config_draft_session.dart';
import 'package:navivox/features/config/form/config_field_presentation.dart';
import 'package:navivox/features/config/form/config_form_model.dart';

void main() {
  test('tracks editing path and stages typed draft values', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'model.temperature',
            'label': 'Temperature',
            'type': 'number',
          },
        ],
      },
      values: const {'model.temperature': 0.4},
    );
    final field = ConfigFieldPresentation.fromRow(form.rows.single);

    final editing = const ConfigDraftSession().beginEditing(field);
    expect(editing.editingField, 'model.temperature');
    expect(editing.isEditing(field), isTrue);
    expect(editing.editInitialValueFor(field), '0.4');

    final staged = editing.stageEdit(field, '0.7');
    expect(staged.editingField, isNull);
    expect(staged.draftValues, {'model.temperature': 0.7});
    expect(editing.draftValues, isEmpty);
  });

  test('blank secret drafts clear existing draft values', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'providers.openai.api_key',
            'label': 'OpenAI API key',
            'type': 'secret',
            'secret': true,
          },
        ],
      },
      values: const {
        'providers.openai.api_key': {'secret_status': 'configured'},
      },
    );
    final field = ConfigFieldPresentation.fromRow(form.rows.single);

    final withSecret = const ConfigDraftSession()
        .stageEdit(field, 'rotated-secret')
        .beginEditing(field);
    expect(withSecret.draftValues, {
      'providers.openai.api_key': 'rotated-secret',
    });

    final cleared = withSecret.stageEdit(field, '   ');
    expect(cleared.editingField, isNull);
    expect(cleared.draftValues, isEmpty);
  });

  test('clears only applied draft values after apply flow succeeds', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
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
    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {'providers.default': 'local'},
    );
    final session = const ConfigDraftSession(
      draftValues: {'providers.default': 'local', 'model.temperature': 0.9},
      editingField: 'model.temperature',
    );

    final cleaned = session.clearApplied(flow);
    expect(cleaned.editingField, 'model.temperature');
    expect(cleaned.draftValues, {'model.temperature': 0.9});
  });

  test('cancels editing without changing draft values', () {
    final session = const ConfigDraftSession(
      draftValues: {'providers.default': 'local'},
      editingField: 'providers.default',
    );

    final cancelled = session.cancelEditing();
    expect(cancelled.editingField, isNull);
    expect(cancelled.draftValues, {'providers.default': 'local'});
  });
}
