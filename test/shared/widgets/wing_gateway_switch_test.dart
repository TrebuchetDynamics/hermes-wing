import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/channel/hermes_channel.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';
import 'package:wing/shared/widgets/wing_gateway_switch.dart';

import '../../features/hermes_chat/support/fake_hermes_channel.dart';
import '../../features/hermes_chat/support/fake_hermes_endpoint_store.dart';
import '../../features/hermes_chat/support/fake_hermes_gateway_directory.dart';

void main() {
  for (final replacement in ['owner', 'activation', 'exception']) {
    testWidgets('does not misattribute failure after $replacement', (
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
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.error,
        connectionFailureKind: HermesConnectionFailureKind.authentication,
      );
      final directory = _PendingGatewayDirectory(channel);
      addTearDown(channel.dispose);
      addTearDown(directory.dispose);
      var ownerCurrent = true;
      final failures = <HermesConnectionFailureKind?>[];
      final switching = completeWingGatewaySwitch(
        context: screenContext,
        directory: directory,
        channel: channel,
        isCurrentOwner: () => ownerCurrent,
        gatewayId: 'host',
        onFailure: failures.add,
        onFinished: () {},
      );
      if (replacement == 'owner') ownerCurrent = false;
      if (replacement == 'activation') await directory.showDirectory();
      if (replacement == 'exception') {
        directory.activation.completeError(StateError('no profiles'));
      } else {
        directory.activation.complete();
      }
      await switching;
      expect(failures, replacement == 'exception' ? [null] : isEmpty);
    });
  }
  for (final kind in HermesConnectionFailureKind.values) {
    testWidgets('reports settled connection rejection: $kind', (tester) async {
      late BuildContext screenContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            screenContext = context;
            return const SizedBox();
          },
        ),
      );
      final channel = FakeHermesChannel(
        status: HermesConnectionStatus.disconnected,
        connectErrorMessage: 'private response must not be displayed',
        connectFailureKind: kind,
      );
      final directory = directoryFor(
        configs: const [
          HermesEndpointConfig(id: 'host', baseUrl: 'https://agent.example'),
        ],
        loader: FakeGatewaySummaryLoader({
          'host': gatewaySummary(['default']),
        }),
        activeChannel: channel,
      );
      addTearDown(channel.dispose);
      addTearDown(directory.dispose);
      await directory.refresh();
      final failures = <HermesConnectionFailureKind?>[];
      var finished = false;
      await completeWingGatewaySwitch(
        context: screenContext,
        directory: directory,
        channel: channel,
        isCurrentOwner: () => true,
        gatewayId: 'host',
        onFailure: failures.add,
        onFinished: () => finished = true,
      );
      expect(failures, [kind]);
      expect(finished, isTrue);
      expect(channel.connectCalls, hasLength(1));
      expect(directory.activeContactId, isNull);
      expect(tester.takeException(), isNull);
    });
  }
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
          channel: channel,
          isCurrentOwner: () => true,
          gatewayId: 'selected-host',
          onFailure: (_) => events.add('failure'),
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
