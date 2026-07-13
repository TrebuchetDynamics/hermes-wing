/// Compile-time gate for the Needle spike. Enable with
/// `--dart-define=NEEDLE_SPIKE=true`; default builds ship no spike UI.
const bool needleSpikeEnabled = bool.fromEnvironment('NEEDLE_SPIKE');
