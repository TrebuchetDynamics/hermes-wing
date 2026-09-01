/// Builds a Hermes API endpoint URI from the configured origin and a path.
///
/// Endpoint builders intentionally strip userinfo, query, and fragment from the
/// configured base URL so copied setup URLs cannot leak stale API keys or route
/// state into every request.
Uri hermesApiEndpointUri(Uri baseUri, String path) {
  final baseSegments = baseUri.pathSegments
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);
  final prefix = baseSegments.length == 2 && baseSegments.first == 'p'
      ? baseSegments
      : const <String>[];
  final endpoint = Uri.parse(
    path,
  ).pathSegments.where((segment) => segment.isNotEmpty);
  return Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : null,
    pathSegments: [...prefix, ...endpoint],
  );
}

String hermesApiRequiredTrimmedValue(String value, String name) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return trimmed;
}

String hermesApiTrimmedPathSegment(String value, {String name = 'value'}) {
  return Uri.encodeComponent(hermesApiRequiredTrimmedValue(value, name));
}
