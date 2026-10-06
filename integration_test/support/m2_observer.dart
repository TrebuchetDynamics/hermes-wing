export 'm2_metadata.dart';

/// Sanitized terminal outcome. Metadata never conveys storage or launch rights.
final class M2BootstrapResult {
  const M2BootstrapResult._();
  String get code => 'not_admitted';
  String get continuation => 'continuation_unavailable';
  bool get qualifies => false;
}

/// No installed issuer has been admitted. There are deliberately no public
/// authority, journal, provider, sink, environment or launch inputs.
Future<M2BootstrapResult> m2Bootstrap() => _bootstrap(_UnavailableRuntime());

Future<M2BootstrapResult> _bootstrap(_RuntimeBoundary runtime) async {
  if (!runtime.admitted) return const M2BootstrapResult._();
  return runtime.launch();
}

abstract interface class _RuntimeBoundary {
  bool get admitted;
  Future<M2BootstrapResult> launch();
}

final class _UnavailableRuntime implements _RuntimeBoundary {
  @override
  bool get admitted => false;

  // Even a removed admission gate cannot select a fallback or secure factory.
  @override
  Future<M2BootstrapResult> launch() =>
      throw StateError('continuation_unavailable');
}
