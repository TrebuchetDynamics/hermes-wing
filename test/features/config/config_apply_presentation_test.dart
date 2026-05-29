import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/apply/config_apply_flow_model.dart';
import 'package:navivox/features/config/apply/config_apply_presentation.dart';
import 'package:navivox/features/config/form/config_form_model.dart';

void main() {
  test('builds stable pending and confirmation copy', () {
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {
            'path': 'navivox.exposure_mode',
            'label': 'Exposure mode',
            'risk_level': 'high',
            'restart_required': true,
          },
        ],
      },
      values: const {'navivox.exposure_mode': 'local'},
    );
    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {'navivox.exposure_mode': 'public'},
    );

    final presentation = ConfigApplyPresentation.fromFlow(flow);

    expect(presentation.hasChanges, isTrue);
    expect(presentation.canApply, isTrue);
    expect(presentation.requiresConfirmation, isTrue);
    expect(presentation.title, 'Pending config changes');
    expect(presentation.applyButtonLabel, 'Apply pending changes');
    expect(presentation.confirmationTitle, 'Confirm high-risk config changes');
    expect(
      presentation.confirmationIntro,
      'Review before/after values before applying.',
    );
    expect(presentation.changes, hasLength(1));
    expect(
      presentation.changes.single.summaryLabel,
      'Exposure mode: local -> public',
    );
    expect(presentation.changes.single.hasRestartLabel, isTrue);
    expect(presentation.changes.single.restartLabel, 'Restart required');
    expect(presentation.changes.single.validationMessages, isEmpty);
  });

  test('carries validation copy and disabled apply state', () {
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
      validationSnapshot: const {
        'field_errors': {
          'providers.default': ['Provider is not available.'],
        },
      },
    );

    final presentation = ConfigApplyPresentation.fromFlow(flow);

    expect(presentation.hasChanges, isTrue);
    expect(presentation.canApply, isFalse);
    expect(presentation.requiresConfirmation, isFalse);
    expect(
      presentation.changes.single.summaryLabel,
      'Default provider: openai -> local',
    );
    expect(presentation.changes.single.hasRestartLabel, isFalse);
    expect(presentation.changes.single.restartLabel, isNull);
    expect(presentation.changes.single.hasValidationMessages, isTrue);
    expect(presentation.changes.single.validationMessages, [
      'Provider is not available.',
    ]);
  });

  test('marks empty apply flows as non-displayable', () {
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
      draftValues: const {'providers.default': 'openai'},
    );

    final presentation = ConfigApplyPresentation.fromFlow(flow);

    expect(presentation.hasChanges, isFalse);
    expect(presentation.canApply, isFalse);
    expect(presentation.requiresConfirmation, isFalse);
    expect(presentation.changes, isEmpty);
  });
}
