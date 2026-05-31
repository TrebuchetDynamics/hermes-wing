import '../form/config_form_model.dart';
import 'config_apply_flow_model.dart';

void main() {
  attachesValidationErrorListMessagesToDraftChanges();
}

void attachesValidationErrorListMessagesToDraftChanges() {
  final form = ConfigFormModel.fromSchema(
    schema: {
      'fields': [
        {
          'path': 'feature.enabled',
          'type': 'boolean',
          'label': 'Feature enabled',
        },
      ],
    },
    values: {'feature.enabled': false},
  );

  final flow = ConfigApplyFlowModel.fromDraft(
    form: form,
    draftValues: {'feature.enabled': 'maybe'},
    validationSnapshot: {
      'validation_errors': [
        {'path': 'feature.enabled', 'message': 'Expected a boolean.'},
      ],
    },
  );

  _expect(
    flow.hasInvalidChanges,
    'validation errors should mark the draft invalid',
  );
  _expect(
    flow.validationMessagesFor('feature.enabled').single ==
        'Expected a boolean.',
    'validation error message should be attached to its field path',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
