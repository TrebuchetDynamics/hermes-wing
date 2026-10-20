import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presentation only: retained across Chat remounts in this window's scope,
/// never persisted or synchronized with Agent configuration.
final transcriptTimestampsProvider =
    NotifierProvider<TranscriptTimestamps, bool>(TranscriptTimestamps.new);

class TranscriptTimestamps extends Notifier<bool> {
  @override
  bool build() => false;

  void setVisible(bool visible) => state = visible;
}
