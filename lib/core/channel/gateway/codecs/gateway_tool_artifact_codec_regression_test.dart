import 'gateway_tool_artifact_codec.dart';

void main() {
  syntheticMetadataArtifactRedactsAuthorizationLikeKeys();
  syntheticMetadataArtifactKeepsNonSensitiveMetadata();
}

void syntheticMetadataArtifactRedactsAuthorizationLikeKeys() {
  final artifacts = navivoxToolArtifactsFromGatewayMetadata(
    {
      'Authorization': 'Bearer secret-token',
      'credential': 'session-secret',
      'safe_label': 'visible',
    },
    toolCallId: 'tool-1',
  );

  _expect(artifacts.length == 1, 'metadata should produce one synthetic artifact');
  final summary = artifacts.single.summary ?? '';
  _expect(
    !summary.contains('Bearer secret-token'),
    'authorization bearer value should not leak into metadata summary',
  );
  _expect(
    !summary.contains('session-secret'),
    'credential value should not leak into metadata summary',
  );
}

void syntheticMetadataArtifactKeepsNonSensitiveMetadata() {
  final artifacts = navivoxToolArtifactsFromGatewayMetadata(
    {'safe_label': 'visible'},
    toolCallId: 'tool-1',
  );

  _expect(
    artifacts.single.summary == 'safe_label: visible',
    'non-sensitive metadata should remain visible',
  );
}

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}
