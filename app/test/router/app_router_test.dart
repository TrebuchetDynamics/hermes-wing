import 'package:flutter_test/flutter_test.dart';
import 'package:navivox/app.dart';

void main() {
  testWidgets('router starts at setup when no server is configured', (
    tester,
  ) async {
    await tester.pumpWidget(const NavivoxApp());
    await tester.pumpAndSettle();

    expect(find.text('Connect to Gormes'), findsOneWidget);
    expect(find.text('Connect and talk'), findsOneWidget);
  });

  // Deferred: a successful chat path through the HTTP gateway needs a
  // fixture WebSocket server. Tracked under 9.E in progress.json as a
  // follow-up integration row; the SSH-era fake-server flow was deleted
  // alongside the wire protocol.
}
