import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/config/apply/config_apply_dispatcher.dart';
import 'package:navivox/features/config/apply/config_apply_flow_model.dart';
import 'package:navivox/features/config/form/config_form_model.dart';

import '../../support/test_navivox_channel.dart';

void main() {
  test('dispatches plain and secret config changes to the channel', () {
    final channel = TestNavivoxChannel();
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'providers.default', 'label': 'Default provider'},
          {
            'path': 'providers.openai.api_key',
            'label': 'OpenAI API key',
            'type': 'secret',
            'secret': true,
          },
        ],
      },
      values: const {
        'providers.default': 'openai',
        'providers.openai.api_key': {'secret_status': 'configured'},
      },
    );
    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {
        'providers.default': 'local',
        'providers.openai.api_key': 'rotated-secret',
      },
    );

    final result = const ConfigApplyDispatcher().dispatch(
      flow: flow,
      channel: channel,
    );

    expect(result.wasDispatched, isTrue);
    expect(result.appliedPaths, [
      'providers.default',
      'providers.openai.api_key',
    ]);
    expect(channel.configSetCalls, [
      (field: 'providers.default', value: 'local'),
    ]);
    expect(channel.configSecretSetCalls, [
      (name: 'providers.openai.api_key', secret: 'rotated-secret'),
    ]);
  });

  test('skips invalid config changes without touching the channel', () {
    final channel = TestNavivoxChannel();
    final form = ConfigFormModel.fromSchema(
      schema: const {
        'fields': [
          {'path': 'navivox.exposure_mode', 'label': 'Exposure mode'},
        ],
      },
      values: const {'navivox.exposure_mode': 'local'},
    );
    final flow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: const {'navivox.exposure_mode': 'public'},
      validationSnapshot: const {
        'field_errors': {
          'navivox.exposure_mode': ['Public exposure is not allowed.'],
        },
      },
    );

    final result = const ConfigApplyDispatcher().dispatch(
      flow: flow,
      channel: channel,
    );

    expect(result.wasDispatched, isFalse);
    expect(result.skippedReason, 'Config changes are invalid.');
    expect(channel.configSetCalls, isEmpty);
    expect(channel.configSecretSetCalls, isEmpty);
  });

  test('skips empty apply flows without touching the channel', () {
    final channel = TestNavivoxChannel();
    final flow = ConfigApplyFlowModel.fromDraft(
      form: ConfigFormModel.fromSchema(
        schema: const {
          'fields': [
            {'path': 'providers.default', 'label': 'Default provider'},
          ],
        },
        values: const {'providers.default': 'openai'},
      ),
      draftValues: const {'providers.default': 'openai'},
    );

    final result = const ConfigApplyDispatcher().dispatch(
      flow: flow,
      channel: channel,
    );

    expect(result.wasDispatched, isFalse);
    expect(result.skippedReason, 'No pending config changes.');
    expect(channel.configSetCalls, isEmpty);
    expect(channel.configSecretSetCalls, isEmpty);
  });
}
