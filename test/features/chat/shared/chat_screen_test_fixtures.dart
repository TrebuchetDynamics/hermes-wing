import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/features/chat/screens/chat_screen.dart';

import '../../../support/test_navivox_channel.dart';
import '../../shared/app/test_material_app.dart';

/// Pumps the chat screen in the standard chat feature material app harness.
Future<void> pumpChatScreen(
  WidgetTester tester, {
  required TestNavivoxChannel channel,
  String? serverId,
  String? profileId,
}) {
  return tester.pumpWidget(
    TestNavivoxMaterialApp(
      channel: channel,
      home: ChatScreen(serverId: serverId, profileId: profileId),
    ),
  );
}
