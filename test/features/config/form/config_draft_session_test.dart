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

    final editing = ConfigDraftSession().beginEditing(field);
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

    final withSecret = ConfigDraftSession()
        .stageEdit(field, 'rotated-secret')
        .beginEditing(field);
    expect(withSecret.draftValues, {
      'providers.openai.api_key': 'rotated-secret',
    });

    final cleared = withSecret.stageEdit(field, '   ');
    expect(cleared.editingField, isNull);
    expect(cleared.draftValues, isEmpty);
  });

  test('staging another field keeps the active edit session open', () {
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
    final providerField = ConfigFieldPresentation.fromRow(form.rows.first);
    final temperatureField = ConfigFieldPresentation.fromRow(form.rows.last);

    final session = ConfigDraftSession(
      draftValues: const {'model.temperature': 0.7},
      editingField: 'model.temperature',
    );

    final staged = session.stageEdit(providerField, 'local');

    expect(staged.editingField, 'model.temperature');
    expect(staged.draftValues, {
      'model.temperature': 0.7,
      'providers.default': 'local',
    });
    expect(staged.isEditing(temperatureField), isTrue);
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
    final session = ConfigDraftSession(
      draftValues: const {
        'providers.default': 'local',
        'model.temperature': 0.9,
      },
      editingField: 'model.temperature',
    );

    final cleaned = session.clearApplied(flow);
    expect(cleaned.editingField, 'model.temperature');
    expect(cleaned.draftValues, {'model.temperature': 0.9});
  });

  test('keeps drafts changed after an apply flow snapshot was created', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
        ],
      },
      values: const {'providers.default': 'openai'},
    );
    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {'providers.default': 'local'},
    );
    final session = ConfigDraftSession(
      draftValues: const {'providers.default': 'anthropic'},
      editingField: 'providers.default',
    );

    final cleaned = session.clearApplied(flow);

    expect(cleaned.editingField, 'providers.default');
    expect(cleaned.draftValues, {'providers.default': 'anthropic'});
  });

  test('snapshots draft values at session boundaries', () {
    final nestedMap = <String, Object?>{'provider': 'local'};
    final nestedList = <Object?>['fast'];
    final mutable = <String, Object?>{
      'providers.default': 'local',
      'providers.options': nestedMap,
      'model.tags': nestedList,
    };
    final session = ConfigDraftSession(draftValues: mutable);

    mutable['providers.default'] = 'openai';
    mutable['model.temperature'] = 0.9;
    nestedMap['provider'] = 'openai';
    nestedList.add('slow');

    expect(session.draftValues, {
      'providers.default': 'local',
      'providers.options': {'provider': 'local'},
      'model.tags': ['fast'],
    });
    expect(
      () => session.draftValues['providers.default'] = 'anthropic',
      throwsUnsupportedError,
    );
    expect(
      () => (session.draftValues['providers.options']! as Map)['provider'] =
          'anthropic',
      throwsUnsupportedError,
    );
    expect(
      () => (session.draftValues['model.tags']! as List).add('debug'),
      throwsUnsupportedError,
    );
  });

  test('cancels editing without changing draft values', () {
    final session = ConfigDraftSession(
      draftValues: const {'providers.default': 'local'},
      editingField: 'providers.default',
    );

    final cancelled = session.cancelEditing();
    expect(cancelled.editingField, isNull);
    expect(cancelled.draftValues, {'providers.default': 'local'});
  });
}
