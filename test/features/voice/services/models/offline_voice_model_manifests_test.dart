import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice/services/models/offline_voice_model_manifests.dart';

void main() {
  test('all Whisper tiers pin every runtime artifact', () {
    final expected = {
      OfflineSttModelTier.compact: (
        packId: 'whisper-tiny-int8-en-es',
        totalBytes: 105923004,
      ),
      OfflineSttModelTier.recommended: (
        packId: 'whisper-base-int8-en-es',
        totalBytes: 162922391,
      ),
      OfflineSttModelTier.quality: (
        packId: 'whisper-small-int8-en-es',
        totalBytes: 377798428,
      ),
    };

    for (final entry in expected.entries) {
      final manifest = offlineSttManifestForTier(entry.key);
      expect(manifest.packId, entry.value.packId);
      expect(manifest.artifactsByName.keys, {
        'encoder',
        'decoder',
        'tokens',
        'silero-vad',
      });
      expect(manifest.totalBytes, entry.value.totalBytes);
      for (final artifact in manifest.artifacts) {
        expect(artifact.uri.scheme, 'https');
        expect(artifact.sha256, hasLength(64));
        expect(artifact.expectedBytes, greaterThan(0));
      }
    }
  });
}
