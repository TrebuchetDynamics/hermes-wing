import 'dart:async';
import 'dart:math';

import 'package:wing/core/hermes/models/hermes_profile.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/core/hermes/setup/hermes_endpoint_store.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';
import 'package:wing/features/hermes_chat/gateways/hermes_gateway_directory.dart';

import 'fake_hermes_channel.dart';
import 'fake_hermes_endpoint_store.dart';

class FakeGatewayContactCache extends GatewayContactCache {
  FakeGatewayContactCache([List<GatewayContact> initial = const []])
    : stored = [...initial];

  List<GatewayContact> stored;

  @override
  Future<List<GatewayContact>> load() async => [...stored];

  @override
  Future<void> save(List<GatewayContact> contacts) async {
    stored = [...contacts];
  }

  @override
  Future<void> removeGateway(String gatewayId) async {
    stored.removeWhere((contact) => contact.id.gatewayId == gatewayId);
  }
}

class FakeGatewaySummaryLoader implements GatewaySummaryLoader {
  FakeGatewaySummaryLoader(this.results, {this.gate});

  final Map<String, Object> results;
  final Completer<void>? gate;
  int active = 0;
  int maxActive = 0;
  final List<String> calls = [];

  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async {
    calls.add(config.id!);
    active++;
    maxActive = max(maxActive, active);
    try {
      if (gate != null) await gate!.future;
      final result = results[config.id];
      if (result is Error) throw result;
      return result! as GatewaySummary;
    } finally {
      active--;
    }
  }
}

GatewaySummary gatewaySummary(List<String> profileIds) => GatewaySummary(
  profileContextAvailable: profileIds.isNotEmpty,
  profiles: [
    for (final id in profileIds)
      HermesProfile(id: id, displayName: id.toUpperCase(), revision: 'r-$id'),
  ],
  sessionsByProfile: {
    for (var index = 0; index < profileIds.length; index++)
      profileIds[index]: [
        HermesSession(
          id: 'session-${profileIds[index]}',
          source: 'test',
          lastActive:
              '2026-07-16T${(10 + index).toString().padLeft(2, '0')}:00:00Z',
        ),
      ],
  },
);

HermesGatewayDirectory directoryFor({
  required List<HermesEndpointConfig> configs,
  required GatewaySummaryLoader loader,
  GatewayContactCache? cache,
  FakeHermesChannel? activeChannel,
}) => HermesGatewayDirectory(
  store: FakeHermesEndpointStore(profiles: configs),
  cache: cache ?? FakeGatewayContactCache(),
  loader: loader,
  activeChannel: activeChannel ?? FakeHermesChannel.disconnected(),
  now: () => DateTime.utc(2026, 7, 16),
);
