import '../../form/config_form_model.dart';
import 'config_apply_flow_model.dart';

void main() {
  attachesValidationErrorListMessagesToDraftChanges();
  attachesCamelCaseValidationSnapshotMessagesToDraftChanges();
  fallsBackAcrossNullValidationSnapshotAliases();
  fallsBackAcrossEmptyValidationSnapshotAliases();
  fallsBackAcrossBlankStringValidationAliases();
  attachesNestedFieldErrorMessageObjectsToDraftChanges();
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

void attachesCamelCaseValidationSnapshotMessagesToDraftChanges() {
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
      'validationErrors': [
        {'field': 'feature.enabled', 'detail': 'Expected a boolean.'},
      ],
      'fieldErrors': {
        'feature.enabled': ['Still not a boolean.'],
      },
    },
  );

  _expect(
    flow.hasInvalidChanges,
    'camelCase validation snapshots should mark the draft invalid',
  );
  _expect(
    flow.validationMessagesFor('feature.enabled').join('|') ==
        'Expected a boolean.|Still not a boolean.',
    'camelCase validation snapshot messages should be attached to their field path',
  );
}

void fallsBackAcrossNullValidationSnapshotAliases() {
  final form = _singleBooleanFieldForm();

  final flow = ConfigApplyFlowModel.fromDraft(
    form: form,
    draftValues: {'feature.enabled': 'maybe'},
    validationSnapshot: {
      'validation_errors': null,
      'validationErrors': [
        {'field': 'feature.enabled', 'detail': 'Expected a boolean.'},
      ],
      'field_errors': null,
      'fieldErrors': {
        'feature.enabled': ['Still not a boolean.'],
      },
    },
  );

  _expect(
    flow.validationMessagesFor('feature.enabled').join('|') ==
        'Expected a boolean.|Still not a boolean.',
    'null snake_case validation snapshot aliases should not hide later camelCase aliases',
  );
}

void fallsBackAcrossEmptyValidationSnapshotAliases() {
  final form = _singleBooleanFieldForm();

  final flow = ConfigApplyFlowModel.fromDraft(
    form: form,
    draftValues: {'feature.enabled': 'maybe'},
    validationSnapshot: {
      'validation_errors': [],
      'validationErrors': [
        {'field': 'feature.enabled', 'detail': 'Expected a boolean.'},
      ],
      'field_errors': {},
      'fieldErrors': {
        'feature.enabled': ['Still not a boolean.'],
      },
    },
  );

  _expect(
    flow.validationMessagesFor('feature.enabled').join('|') ==
        'Expected a boolean.|Still not a boolean.',
    'empty snake_case validation snapshot aliases should not hide later populated camelCase aliases',
  );
}

void fallsBackAcrossBlankStringValidationAliases() {
  final form = _singleBooleanFieldForm();

  final flow = ConfigApplyFlowModel.fromDraft(
    form: form,
    draftValues: {'feature.enabled': 'maybe'},
    validationSnapshot: {
      'validation_errors': [
        {
          'path': ' ',
          'field': 'feature.enabled',
          'message': ' ',
          'detail': 'Expected a boolean.',
        },
      ],
    },
  );

  _expect(
    flow.validationMessagesFor('feature.enabled').single ==
        'Expected a boolean.',
    'blank validation aliases should not hide later non-empty field/detail aliases',
  );
}

void attachesNestedFieldErrorMessageObjectsToDraftChanges() {
  final form = _singleBooleanFieldForm();

  final flow = ConfigApplyFlowModel.fromDraft(
    form: form,
    draftValues: {'feature.enabled': 'maybe'},
    validationSnapshot: {
      'field_errors': {
        'feature.enabled': {'detail': 'Expected a boolean.'},
      },
    },
  );

  _expect(
    flow.validationMessagesFor('feature.enabled').single ==
        'Expected a boolean.',
    'field_errors map values with nested detail/message/error objects should attach to their field path',
  );
}

ConfigFormModel _singleBooleanFieldForm() {
  return ConfigFormModel.fromSchema(
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
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
