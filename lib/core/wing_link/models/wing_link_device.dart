class WingLinkDevice {
  const WingLinkDevice({
    required this.id,
    required this.name,
    required this.scopes,
    required this.createdAt,
    required this.lastUsedAt,
    required this.expiresAt,
    required this.legacy,
  });

  factory WingLinkDevice.fromJson(Map<String, Object?> json) {
    final id = json['device_id'];
    final name = json['name'];
    final scopesValue = json['scopes'];
    final createdAt = DateTime.tryParse(json['created_at']?.toString() ?? '');
    if (id is! String ||
        !RegExp(r'^(cred|legacy)_[A-Za-z0-9_-]{1,91}$').hasMatch(id) ||
        name is! String ||
        name.runes.length > 80 ||
        scopesValue is! List ||
        scopesValue.length > 32 ||
        createdAt == null) {
      throw const FormatException('Invalid Wing Link device');
    }
    final scopes = <String>[];
    for (final scope in scopesValue) {
      if (scope is! String ||
          scope.isEmpty ||
          scope.length > 64 ||
          scopes.contains(scope)) {
        throw const FormatException('Invalid Wing Link device scopes');
      }
      scopes.add(scope);
    }
    return WingLinkDevice(
      id: id,
      name: name,
      scopes: List.unmodifiable(scopes),
      createdAt: createdAt.toUtc(),
      lastUsedAt: _optionalDate(json['last_used_at']),
      expiresAt: _optionalDate(json['expires_at']),
      legacy: json['legacy'] == true,
    );
  }

  final String id;
  final String name;
  final List<String> scopes;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final DateTime? expiresAt;
  final bool legacy;

  static DateTime? _optionalDate(Object? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      throw const FormatException('Invalid Wing Link device date');
    }
    return parsed.toUtc();
  }
}
