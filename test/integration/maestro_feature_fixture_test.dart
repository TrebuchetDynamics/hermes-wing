import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/policy/hermes_transport_policy.dart';

import '../../integration_test/hermes_features_maestro_main.dart';
import '../../integration_test/support/maestro/interaction_fixture.dart';
import '../../integration_test/support/maestro/feature_channel.dart';

void main() {
  test(
    'native picker fixtures preserve names, bytes, and deferred completion',
    () async {
      final fixture = InteractionFixture();
      final text = await fixture.pick();
      expect(text!.name, 'fixture-note.txt');
      expect(await text.readAsString(), InteractionFixture.textContent);
      fixture.pickerMode = 'image';
      final image = await fixture.pick();
      expect(image!.name, 'fixture-image.png');
      expect(await image.readAsBytes(), InteractionFixture.imageBytes);
      fixture.pickerMode = 'deferred';
      var completed = false;
      final pending = fixture.pick().then((file) {
        completed = true;
        return file;
      });
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      fixture.completePick();
      expect((await pending)!.name, 'fixture-note.txt');
    },
  );
  test(
    'trust fixture is accepted by the production response decoders',
    () async {
      final fixture = FeatureFixture();
      addTearDown(fixture.channel.dispose);
      addTearDown(fixture.scale.dispose);
      final client = fixture.trustClient();
      expect((await client.getCurrentDevice()).id, 'cred_fixture');
      expect((await client.getMetadata()).supportedProtocolGenerations, [1, 2]);
      await client.revokeCurrentDevice();
      expect(fixture.revoked, isTrue);
    },
  );

  test('fixture advertises the UI operations its flows require', () {
    final channel = MaestroFeatureChannel();
    addTearDown(channel.dispose);
    final policy = HermesTransportPolicy(channel.state.capabilities!);
    expect(policy.supportsAnyChatTransport, isTrue);
    expect(policy.supportsRunApprovalResponse, isTrue);
    expect(channel.state.canDeleteSessions, isTrue);
    expect(channel.state.canWriteProviders, isTrue);
    expect(channel.state.canWriteModels, isTrue);
    channel.revokeWrites();
    expect(channel.state.canWriteProviders, isFalse);
    expect(channel.state.canWriteModels, isFalse);
    expect(channel.state.canReadProviders, isTrue);
  });

  test(
    'fixture model conflict requires the refreshed revision to persist',
    () async {
      final channel = MaestroFeatureChannel();
      addTearDown(channel.dispose);
      final revision = channel.state.modelInventory!.assignment.revision;
      Future<void> assign(String revision) => channel.assignModel(
        scope: 'main',
        provider: 'fixture',
        model: 'fixture-large',
        revision: revision,
      );
      channel.conflictNext = true;
      await expectLater(
        assign(revision),
        throwsA(isA<FixtureStatusException>()),
      );
      expect(channel.assignModelCalls, isEmpty);
      await expectLater(
        assign(revision),
        throwsA(isA<FixtureStatusException>()),
      );
      await assign(channel.state.modelInventory!.assignment.revision);
      expect(channel.assignModelCalls, hasLength(1));
      expect(
        channel.state.modelInventory!.assignment.activeModel,
        'fixture-large',
      );
    },
  );

  test('fixture pagination adds a distinct server row', () async {
    final channel = MaestroFeatureChannel();
    addTearDown(channel.dispose);
    channel.setSessionPagination(hasMore: true);
    await channel.loadMoreSessions();
    expect(channel.state.sessions.map((session) => session.id).toSet(), {
      'sess_1',
      'sess_2',
      'sess_3',
    });
    expect(channel.state.hasMoreSessions, isFalse);
  });
}
