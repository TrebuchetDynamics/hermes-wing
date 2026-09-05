import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../integration_test/hermes_profile_lifecycle_maestro_main.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'created clone and persona persist, deletion does not resurrect it',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final first = ProfileLifecycleFixtureChannel(prefs);
      addTearDown(first.dispose);
      await first.createProfile(name: 'fixture-child', cloneFrom: 'mineru');
      final created = ProfileLifecycleFixtureChannel(prefs);
      addTearDown(created.dispose);
      expect(
        created.state.profiles.any((p) => p.id == 'fixture-child'),
        isTrue,
      );
      expect(
        (await first.readProfileSoul('fixture-child')).soul,
        (await first.readProfileSoul('mineru')).soul,
      );
      final child = first.state.profiles.firstWhere(
        (p) => p.id == 'fixture-child',
      );
      await first.renameProfile(
        profileId: child.id,
        name: 'Fixture child',
        revision: child.revision,
      );
      final soul = await first.readProfileSoul(child.id);
      await first.writeProfileSoul(
        profileId: child.id,
        soul: 'Fixture custom persona',
        revision: soul.revision,
      );
      final restored = ProfileLifecycleFixtureChannel(prefs);
      addTearDown(restored.dispose);
      final saved = restored.state.profiles.firstWhere((p) => p.id == child.id);
      expect(saved.displayName, 'Fixture child');
      expect(saved.model, child.model);
      expect(
        (await restored.readProfileSoul(child.id)).soul,
        'Fixture custom persona',
      );
      expect(
        (await restored.readProfileSoul('mineru')).soul,
        'persona-initial-mineru',
      );
      await restored.selectProfile(child.id);
      await restored.deleteProfile(
        profileId: child.id,
        revision: saved.revision,
      );
      expect(restored.state.selectedProfileId, 'default');
      expect(restored.state.activeSessionId, 'session-default');
      final afterDelete = ProfileLifecycleFixtureChannel(prefs);
      addTearDown(afterDelete.dispose);
      expect(afterDelete.state.profiles.any((p) => p.id == child.id), isFalse);
      expect(afterDelete.state.profiles, hasLength(9));
    },
  );

  test(
    'fixture rejects duplicate creation, stale mutation and default deletion',
    () async {
      final channel = ProfileLifecycleFixtureChannel(
        await SharedPreferences.getInstance(),
      );
      addTearDown(channel.dispose);
      await expectLater(
        channel.createProfile(name: 'mineru'),
        throwsStateError,
      );
      await expectLater(
        channel.renameProfile(
          profileId: 'mineru',
          name: 'Changed',
          revision: 'stale',
        ),
        throwsStateError,
      );
      await expectLater(
        channel.deleteProfile(
          profileId: 'default',
          revision: channel.state.profiles.first.revision,
        ),
        throwsStateError,
      );
      expect(channel.state.profiles, hasLength(9));
    },
  );

  test('profile switching preserves separate assistant histories', () async {
    final channel = ProfileLifecycleFixtureChannel(
      await SharedPreferences.getInstance(),
    );
    addTearDown(channel.dispose);
    await channel.selectProfile('default');
    await channel.sendText('fixture-one');
    await channel.selectProfile('mineru');
    expect(channel.state.activeMessages, isEmpty);
    await channel.sendText('fixture-two');
    expect(
      channel.state.activeMessages.last.text,
      'PROFILE_RECEIPT::mineru::session-mineru::fixture-two::assistant',
    );
    await channel.selectProfile('default');
    expect(
      channel.state.activeMessages.last.text,
      'PROFILE_RECEIPT::default::session-default::fixture-one::assistant',
    );
    await channel.sendText('fixture-three');
    expect(channel.state.activeMessages, hasLength(4));
  });

  test(
    'configured setup receipts match the typed callback and persist metadata',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final channel = ProfileLifecycleFixtureChannel(prefs);
      addTearDown(channel.dispose);
      await channel.configuredCreate(
        name: 'setup-qa',
        description: 'Fixture setup description',
        provider: 'openrouter',
        model: 'fixture-model',
      );
      expect(channel.setupCalls, 1);
      expect(channel.setupMatches, isTrue);
      final restored = ProfileLifecycleFixtureChannel(prefs);
      addTearDown(restored.dispose);
      final profile = restored.state.profiles.firstWhere(
        (p) => p.id == 'setup-qa',
      );
      expect(profile.description, 'Fixture setup description');
      expect(profile.model, 'fixture-model');
      await restored.selectProfile('setup-qa');
      await restored.sendText('fixture-model-check');
      expect(
        restored.state.activeMessages.last.text,
        contains(
          'MODEL_RECEIPT::setup-qa::openrouter::fixture-model::fixture-model-check::assistant',
        ),
      );
      await restored.selectProfile('default');
      await restored.sendText('fixture-default-check');
      expect(
        restored.state.activeMessages.last.text,
        isNot(contains('MODEL_RECEIPT')),
      );
      await restored.deleteProfile(
        profileId: profile.id,
        revision: profile.revision,
      );
      expect(prefs.getString('profile-provider-setup-qa'), isNull);
    },
  );
}
