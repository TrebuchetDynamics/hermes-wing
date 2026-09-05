// Runs the complete feature, app, routing, and shared UI regression inventory
// inside the Linux engine. Service and credential seams remain deterministic;
// this does not qualify live Agent APIs, keyring persistence, or physical audio.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:integration_test/integration_test.dart';

import '../test/app/desktop_host_command_listener_test.dart' as suite_0;
import '../test/app/wing_app_connect_intent_test.dart' as suite_1;
import '../test/features/enrollment/hermes_enrollment_flow_test.dart'
    as suite_2;
import '../test/features/enrollment/hermes_enrollment_payload_test.dart'
    as suite_3;
import '../test/features/gateway/gateway_screen_test.dart' as suite_4;
import '../test/features/hermes_chat/composer/attachments/hermes_attachment_content_test.dart'
    as suite_5;
import '../test/features/hermes_chat/composer/attachments/hermes_image_attachment_normalizer_test.dart'
    as suite_6;
import '../test/features/hermes_chat/composer/attachments/staged_attachment_test.dart'
    as suite_7;
import '../test/features/hermes_chat/composer/hermes_composer_draft_store_test.dart'
    as suite_8;
import '../test/features/hermes_chat/controllers/hermes_channel_observation_test.dart'
    as suite_9;
import '../test/features/hermes_chat/controllers/hermes_connection_form_test.dart'
    as suite_10;
import '../test/features/hermes_chat/controllers/hermes_follow_up_queue_test.dart'
    as suite_11;
import '../test/features/hermes_chat/diagnostics/hermes_diagnostics_export_test.dart'
    as suite_12;
import '../test/features/hermes_chat/diagnostics/hermes_diagnostics_redaction_test.dart'
    as suite_13;
import '../test/features/hermes_chat/gateways/gateway_contact_cache_test.dart'
    as suite_14;
import '../test/features/hermes_chat/gateways/gateway_contact_test.dart'
    as suite_15;
import '../test/features/hermes_chat/gateways/gateway_contacts_view_test.dart'
    as suite_16;
import '../test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart'
    as suite_17;
import '../test/features/hermes_chat/groups/chat_group_controller_test.dart'
    as suite_18;
import '../test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart'
    as suite_19;
import '../test/features/hermes_chat/presentation/hermes_transcript_viewport_test.dart'
    as suite_20;
import '../test/features/hermes_chat/presentation/hermes_turn_presentation_identity_test.dart'
    as suite_21;
import '../test/features/hermes_chat/presentation/inline_transcript_image_safety_test.dart'
    as suite_22;
import '../test/features/hermes_chat/providers/hermes_channel_provider_test.dart'
    as suite_23;
import '../test/features/hermes_chat/providers/hermes_tts_provider_test.dart'
    as suite_24;
import '../test/features/hermes_chat/providers/hermes_voice_capture_provider_test.dart'
    as suite_25;
import '../test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart'
    as suite_26;
import '../test/features/hermes_chat/screens/hermes_chat_completion_sound_test.dart'
    as suite_27;
import '../test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart'
    as suite_28;
import '../test/features/hermes_chat/screens/hermes_chat_disposal_test.dart'
    as suite_29;
import '../test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart'
    as suite_30;
import '../test/features/hermes_chat/screens/hermes_chat_message_actions_a11y_test.dart'
    as suite_31;
import '../test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart'
    as suite_32;
import '../test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart'
    as suite_33;
import '../test/features/hermes_chat/screens/hermes_chat_screen_android_endpoint_test.dart'
    as suite_34;
import '../test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart'
    as suite_35;
import '../test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart'
    as suite_36;
import '../test/features/hermes_chat/screens/hermes_chat_tips_test.dart'
    as suite_37;
import '../test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart'
    as suite_38;
import '../test/features/hermes_chat/session/hermes_session_pin_store_test.dart'
    as suite_39;
import '../test/features/hermes_chat/voice/hermes_continuous_voice_reply_policy_test.dart'
    as suite_40;
import '../test/features/hermes_chat/voice/hermes_spoken_text_test.dart'
    as suite_41;
import '../test/features/hermes_chat/voice/hermes_voice_capture_flow_test.dart'
    as suite_42;
import '../test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart'
    as suite_43;
import '../test/features/hermes_chat/widgets/hermes_profile_identity_test.dart'
    as suite_44;
import '../test/features/hermes_chat/widgets/session_model_picker_sheet_test.dart'
    as suite_45;
import '../test/features/local_setup/local_hermes_setup_test.dart' as suite_46;
import '../test/features/local_setup/termux_bootstrap_command_test.dart'
    as suite_47;
import '../test/features/local_setup/termux_hermes_setup_test.dart' as suite_48;
import '../test/features/office/office_screen_test.dart' as suite_49;
import '../test/features/profiles/profile_directory_browser_sheet_test.dart'
    as suite_50;
import '../test/features/profiles/profile_editor_sheet_test.dart' as suite_51;
import '../test/features/profiles/profiles_screen_test.dart' as suite_52;
import '../test/features/providers/model_picker_presets_test.dart' as suite_53;
import '../test/features/providers/model_picker_sheet_test.dart' as suite_54;
import '../test/features/providers/model_preset_store_test.dart' as suite_55;
import '../test/features/providers/provider_credential_sheet_test.dart'
    as suite_56;
import '../test/features/providers/providers_screen_test.dart' as suite_57;
import '../test/features/schedules/schedules_screen_test.dart' as suite_58;
import '../test/features/settings/providers/voice_settings_provider_test.dart'
    as suite_59;
import '../test/features/settings/settings_diagnostics_screen_test.dart'
    as suite_60;
import '../test/features/settings/settings_screen_test.dart' as suite_61;
import '../test/features/settings/settings_voice_screen_test.dart' as suite_62;
import '../test/features/settings/theme_settings_provider_test.dart'
    as suite_63;
import '../test/features/soul/soul_screen_test.dart' as suite_64;
import '../test/features/tools/tools_screen_test.dart' as suite_65;
import '../test/features/voice/services/platform/default_voice_capture_service_test.dart'
    as suite_66;
import '../test/features/voice/services/platform/device_speech_recognition_availability_test.dart'
    as suite_67;
import '../test/features/voice/services/speech/speech_to_text_language_reason_test.dart'
    as suite_68;
import '../test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart'
    as suite_69;
import '../test/features/voice/services/tts/hermes_agent_text_to_speech_service_test.dart'
    as suite_70;
import '../test/router/app_router_transitions_test.dart' as suite_71;
import '../test/router/gateway_route_test.dart' as suite_72;
import '../test/router/legacy_agents_route_test.dart' as suite_73;
import '../test/router/office_route_test.dart' as suite_74;
import '../test/router/schedules_route_test.dart' as suite_75;
import '../test/router/settings_routes_test.dart' as suite_76;
import '../test/router/tools_route_test.dart' as suite_77;
import '../test/shared/async/fire_and_forget_test.dart' as suite_78;
import '../test/shared/security/wing_redaction_test.dart' as suite_79;
import '../test/shared/tips/wing_tips_test.dart' as suite_80;
import '../test/shared/widgets/app_shell_test.dart' as suite_81;
import '../test/shared/widgets/sheet_presenter_test.dart' as suite_82;
import '../test/shared/widgets/wing_empty_state_test.dart' as suite_83;
import '../test/shared/widgets/wing_skeleton_test.dart' as suite_84;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Navigator cancels active pointers through the framework's device queue.
  // Dropping those cancellations leaves recognizers stuck after a popup opens.
  binding.shouldPropagateDevicePointerEvents = true;
  setUp(() {
    binding.testTextInput.register();
    addTearDown(binding.testTextInput.unregister);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final view = binding.platformDispatcher.implicitView!;
    view.physicalSize = const Size(800, 600);
    view.devicePixelRatio = 1;
  });
  group('test/app/desktop_host_command_listener_test.dart', suite_0.main);
  group('test/app/wing_app_connect_intent_test.dart', suite_1.main);
  group(
    'test/features/enrollment/hermes_enrollment_flow_test.dart',
    suite_2.main,
  );
  group(
    'test/features/enrollment/hermes_enrollment_payload_test.dart',
    suite_3.main,
  );
  group('test/features/gateway/gateway_screen_test.dart', suite_4.main);
  group(
    'test/features/hermes_chat/composer/attachments/hermes_attachment_content_test.dart',
    suite_5.main,
  );
  group(
    'test/features/hermes_chat/composer/attachments/hermes_image_attachment_normalizer_test.dart',
    suite_6.main,
  );
  group(
    'test/features/hermes_chat/composer/attachments/staged_attachment_test.dart',
    suite_7.main,
  );
  group(
    'test/features/hermes_chat/composer/hermes_composer_draft_store_test.dart',
    suite_8.main,
  );
  group(
    'test/features/hermes_chat/controllers/hermes_channel_observation_test.dart',
    suite_9.main,
  );
  group(
    'test/features/hermes_chat/controllers/hermes_connection_form_test.dart',
    suite_10.main,
  );
  group(
    'test/features/hermes_chat/controllers/hermes_follow_up_queue_test.dart',
    suite_11.main,
  );
  group(
    'test/features/hermes_chat/diagnostics/hermes_diagnostics_export_test.dart',
    suite_12.main,
  );
  group(
    'test/features/hermes_chat/diagnostics/hermes_diagnostics_redaction_test.dart',
    suite_13.main,
  );
  group(
    'test/features/hermes_chat/gateways/gateway_contact_cache_test.dart',
    suite_14.main,
  );
  group(
    'test/features/hermes_chat/gateways/gateway_contact_test.dart',
    suite_15.main,
  );
  group(
    'test/features/hermes_chat/gateways/gateway_contacts_view_test.dart',
    suite_16.main,
  );
  group(
    'test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart',
    suite_17.main,
  );
  group(
    'test/features/hermes_chat/groups/chat_group_controller_test.dart',
    suite_18.main,
  );
  group(
    'test/features/hermes_chat/messaging/approvals/hermes_approval_queue_test.dart',
    suite_19.main,
  );
  group(
    'test/features/hermes_chat/presentation/hermes_transcript_viewport_test.dart',
    suite_20.main,
  );
  group(
    'test/features/hermes_chat/presentation/hermes_turn_presentation_identity_test.dart',
    suite_21.main,
  );
  group(
    'test/features/hermes_chat/presentation/inline_transcript_image_safety_test.dart',
    suite_22.main,
  );
  group(
    'test/features/hermes_chat/providers/hermes_channel_provider_test.dart',
    suite_23.main,
  );
  group(
    'test/features/hermes_chat/providers/hermes_tts_provider_test.dart',
    suite_24.main,
  );
  group(
    'test/features/hermes_chat/providers/hermes_voice_capture_provider_test.dart',
    suite_25.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_approval_review_test.dart',
    suite_26.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_completion_sound_test.dart',
    suite_27.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_composer_focus_test.dart',
    suite_28.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_disposal_test.dart',
    suite_29.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart',
    suite_30.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_message_actions_a11y_test.dart',
    suite_31.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart',
    suite_32.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart',
    suite_33.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_screen_android_endpoint_test.dart',
    suite_34.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart',
    suite_35.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_slash_commands_test.dart',
    suite_36.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_tips_test.dart',
    suite_37.main,
  );
  group(
    'test/features/hermes_chat/screens/hermes_chat_voice_lifecycle_test.dart',
    suite_38.main,
  );
  group(
    'test/features/hermes_chat/session/hermes_session_pin_store_test.dart',
    suite_39.main,
  );
  group(
    'test/features/hermes_chat/voice/hermes_continuous_voice_reply_policy_test.dart',
    suite_40.main,
  );
  group(
    'test/features/hermes_chat/voice/hermes_spoken_text_test.dart',
    suite_41.main,
  );
  group(
    'test/features/hermes_chat/voice/hermes_voice_capture_flow_test.dart',
    suite_42.main,
  );
  group(
    'test/features/hermes_chat/voice/hermes_voice_input_controller_test.dart',
    suite_43.main,
  );
  group(
    'test/features/hermes_chat/widgets/hermes_profile_identity_test.dart',
    suite_44.main,
  );
  group(
    'test/features/hermes_chat/widgets/session_model_picker_sheet_test.dart',
    suite_45.main,
  );
  group(
    'test/features/local_setup/local_hermes_setup_test.dart',
    suite_46.main,
  );
  group(
    'test/features/local_setup/termux_bootstrap_command_test.dart',
    suite_47.main,
  );
  group(
    'test/features/local_setup/termux_hermes_setup_test.dart',
    suite_48.main,
  );
  group('test/features/office/office_screen_test.dart', suite_49.main);
  group(
    'test/features/profiles/profile_directory_browser_sheet_test.dart',
    suite_50.main,
  );
  group('test/features/profiles/profile_editor_sheet_test.dart', suite_51.main);
  group('test/features/profiles/profiles_screen_test.dart', suite_52.main);
  group(
    'test/features/providers/model_picker_presets_test.dart',
    suite_53.main,
  );
  group('test/features/providers/model_picker_sheet_test.dart', suite_54.main);
  group('test/features/providers/model_preset_store_test.dart', suite_55.main);
  group(
    'test/features/providers/provider_credential_sheet_test.dart',
    suite_56.main,
  );
  group('test/features/providers/providers_screen_test.dart', suite_57.main);
  group('test/features/schedules/schedules_screen_test.dart', suite_58.main);
  group(
    'test/features/settings/providers/voice_settings_provider_test.dart',
    suite_59.main,
  );
  group(
    'test/features/settings/settings_diagnostics_screen_test.dart',
    suite_60.main,
  );
  group('test/features/settings/settings_screen_test.dart', suite_61.main);
  group(
    'test/features/settings/settings_voice_screen_test.dart',
    suite_62.main,
  );
  group(
    'test/features/settings/theme_settings_provider_test.dart',
    suite_63.main,
  );
  group('test/features/soul/soul_screen_test.dart', suite_64.main);
  group('test/features/tools/tools_screen_test.dart', suite_65.main);
  group(
    'test/features/voice/services/platform/default_voice_capture_service_test.dart',
    suite_66.main,
  );
  group(
    'test/features/voice/services/platform/device_speech_recognition_availability_test.dart',
    suite_67.main,
  );
  group(
    'test/features/voice/services/speech/speech_to_text_language_reason_test.dart',
    suite_68.main,
  );
  group(
    'test/features/voice/services/speech/speech_to_text_voice_capture_service_test.dart',
    suite_69.main,
  );
  group(
    'test/features/voice/services/tts/hermes_agent_text_to_speech_service_test.dart',
    suite_70.main,
  );
  group('test/router/app_router_transitions_test.dart', suite_71.main);
  group('test/router/gateway_route_test.dart', suite_72.main);
  group('test/router/legacy_agents_route_test.dart', suite_73.main);
  group('test/router/office_route_test.dart', suite_74.main);
  group('test/router/schedules_route_test.dart', suite_75.main);
  group('test/router/settings_routes_test.dart', suite_76.main);
  group('test/router/tools_route_test.dart', suite_77.main);
  group('test/shared/async/fire_and_forget_test.dart', suite_78.main);
  group('test/shared/security/wing_redaction_test.dart', suite_79.main);
  group('test/shared/tips/wing_tips_test.dart', suite_80.main);
  group('test/shared/widgets/app_shell_test.dart', suite_81.main);
  group('test/shared/widgets/sheet_presenter_test.dart', suite_82.main);
  group('test/shared/widgets/wing_empty_state_test.dart', suite_83.main);
  group('test/shared/widgets/wing_skeleton_test.dart', suite_84.main);
}
