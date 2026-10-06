import 'support/m2_observer.dart';

/// Refuse before Flutter binding, providers, stores, channels or runApp exist.
/// Runtime custody requires a separately reviewed installed issuer; metadata and
/// the fake-only diagnostic oracle cannot activate this entrypoint.
Future<void> main() async {
  await m2Bootstrap();
}
