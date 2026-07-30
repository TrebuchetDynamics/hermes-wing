import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/providers/models/model_preset.dart';
import 'package:wing/features/providers/models/model_preset_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saving an existing name overwrites that preset in place', () async {
    final store = ModelPresetStore();
    await store.save(
      const ModelPreset(
        name: 'Drafts',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5-mini',
      ),
    );
    await store.save(
      const ModelPreset(
        name: 'Reviews',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5',
      ),
    );
    final updated = await store.save(
      const ModelPreset(
        name: 'Drafts',
        slot: 'vision',
        provider: 'anthropic',
        model: 'claude-sonnet',
      ),
    );

    expect(updated, await store.load());
    expect(updated, const [
      ModelPreset(
        name: 'Drafts',
        slot: 'vision',
        provider: 'anthropic',
        model: 'claude-sonnet',
      ),
      ModelPreset(
        name: 'Reviews',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5',
      ),
    ]);
  });

  test('remove deletes only the named preset', () async {
    final store = ModelPresetStore();
    await store.save(
      const ModelPreset(
        name: 'Drafts',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5-mini',
      ),
    );
    await store.save(
      const ModelPreset(
        name: 'Reviews',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5',
      ),
    );

    final remaining = await store.remove('Drafts');

    expect(remaining, await store.load());
    expect(remaining, const [
      ModelPreset(
        name: 'Reviews',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5',
      ),
    ]);
  });

  test('malformed or hostile stored data loads as no presets', () async {
    for (final hostile in ['not json', '{"a":1}', '[1,2,3]', '"text"']) {
      SharedPreferences.setMockInitialValues({
        'flutter.wing.hermes.model_presets.v1': hostile,
      });
      expect(await ModelPresetStore().load(), isEmpty, reason: hostile);
    }
  });

  test('entries missing a name or model are dropped on load', () async {
    SharedPreferences.setMockInitialValues({
      'flutter.wing.hermes.model_presets.v1':
          '[{"name":"","slot":"main","provider":"openai","model":"gpt-5"},'
          '{"name":"Drafts","slot":"main","provider":"openai","model":""},'
          '{"name":"Keep","slot":"main","provider":"openai","model":"gpt-5"}]',
    });

    expect(await ModelPresetStore().load(), const [
      ModelPreset(
        name: 'Keep',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5',
      ),
    ]);
  });

  test('saving past the cap drops the oldest preset', () async {
    final store = ModelPresetStore();
    for (var i = 0; i < ModelPresetStore.maxPresets; i++) {
      await store.save(
        ModelPreset(
          name: 'Preset $i',
          slot: 'main',
          provider: 'openai',
          model: 'gpt-5',
        ),
      );
    }

    final presets = await store.save(
      const ModelPreset(
        name: 'One more',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5',
      ),
    );

    expect(presets, hasLength(ModelPresetStore.maxPresets));
    expect(presets.first.name, 'Preset 1');
    expect(presets.last.name, 'One more');
  });

  test('saved presets round-trip through load', () async {
    final store = ModelPresetStore();
    await store.save(
      const ModelPreset(
        name: 'Fast drafts',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5-mini',
      ),
    );

    expect(await store.load(), const [
      ModelPreset(
        name: 'Fast drafts',
        slot: 'main',
        provider: 'openai',
        model: 'gpt-5-mini',
      ),
    ]);
  });
}
