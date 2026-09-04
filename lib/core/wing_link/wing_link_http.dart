final class WingLinkHttpException implements Exception {
  const WingLinkHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Wing Link request failed with HTTP $statusCode';
}
