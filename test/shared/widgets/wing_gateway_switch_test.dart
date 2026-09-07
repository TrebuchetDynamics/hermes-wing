import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/shared/widgets/wing_gateway_switch.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';
import '../../features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  for (final fails in [false, true]) {
    for (final disposeBeforeCompletion in [false, true]) {
      testWidgets('switch failure=$fails disposed=$disposeBeforeCompletion', (
        tester,
      ) async {
        late BuildContext screenContext;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              screenContext = context;
              return const SizedBox();
            },
          ),
        );
        final channel = FakeHermesChannel.disconnected();
        final directory = _PendingGatewayDirectory(channel);
        addTearDown(channel.dispose);
        addTearDown(directory.dispose);
        final events = <String>[];
        final switching = completeWingGatewaySwitch(
          context: screenContext,
          directory: directory,
          gatewayId: 'selected-host',
          onFailure: () => events.add('failure'),
          onFinished: () => events.add('finished'),
        );
        expect(directory.requestedId, 'selected-host');
        expect(events, isEmpty);
        if (disposeBeforeCompletion) {
          await tester.pumpWidget(const SizedBox());
        }
        if (fails) {
          directory.activation.completeError(StateError('activation failed'));
        } else {
          directory.activation.complete();
        }
        await switching;
        expect(
          events,
          disposeBeforeCompletion
              ? <String>[]
              : [if (fails) 'failure', 'finished'],
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

class _PendingGatewayDirectory extends HermesGatewayDirectory {
  _PendingGatewayDirectory(FakeHermesChannel channel)
    : super(
        store: FakeHermesEndpointStore(),
        cache: FakeGatewayContactCache(),
        loader: FakeGatewaySummaryLoader({}),
        activeChannel: channel,
      );

  final activation = Completer<void>();
  String? requestedId;

  @override
  Future<void> activateGateway(String gatewayId) {
    requestedId = gatewayId;
    return activation.future;
  }
}
