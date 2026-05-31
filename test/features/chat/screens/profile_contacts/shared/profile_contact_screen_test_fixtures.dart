import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/core/channel/navivox_channel.dart';

import '../../../../../support/test_navivox_channel.dart';
import '../../../../shared/app/test_router_app.dart';
import '../../../../shared/fixtures/profile_contact_fixtures.dart';

/// Shared server list for chat Profile contact screen tests.
final chatProfileListServers = localOfficeServers();

/// Shared contacts for chat Profile contact list and scoped-chat tests.
final chatProfileListContacts = [
  mineruBuilderProfile(latestAt: DateTime(2026, 5, 16, 9, 41)),
  supportTriageProfile(latestAt: DateTime(2026, 5, 16, 9, 22)),
  personalProfile(latestAt: DateTime(2026, 5, 15, 18)),
];

/// Builds the default populated channel for Profile contact screen tests.
TestNavivoxChannel profileContactListChannel({String? selectedKey}) {
  return TestNavivoxChannel()
    ..seedServers(chatProfileListServers, activeServerId: 'local')
    ..seedProfileContacts(chatProfileListContacts, selectedKey: selectedKey);
}

/// Pumps the profile contact list through the shared router app harness.
Future<void> pumpProfileContactList(
  WidgetTester tester, {
  required TestNavivoxChannel channel,
}) async {
  await tester.pumpWidget(TestNavivoxRouterApp(channel: channel));
  await tester.pumpAndSettle();
}
