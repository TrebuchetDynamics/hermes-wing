import 'dart:convert';

/// A new metadata-only format; never a legacy pairing URI or credential carrier.
class HermesGatewayInvite {
  HermesGatewayInvite({required this.origin, required this.profile}) {
    if (origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/') ||
        !RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(profile)) {
      throw const FormatException('Invalid gateway invitation');
    }
  }

  final Uri origin;
  final String profile;

  String encode() => jsonEncode({
    'type': 'hermes-wing-gateway',
    'version': 1,
    'origin': origin.replace(path: '').toString(),
    'profile': profile,
  });

  factory HermesGatewayInvite.decode(String text) {
    try {
      if (text.length > 2048) throw const FormatException();
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic> ||
          data.length != 4 ||
          data['type'] != 'hermes-wing-gateway' ||
          data['version'] is! int ||
          data['version'] != 1 ||
          data['origin'] is! String ||
          data['profile'] is! String) {
        throw const FormatException();
      }
      return HermesGatewayInvite(
        origin: Uri.parse(data['origin'] as String),
        profile: data['profile'] as String,
      );
    } catch (_) {
      // Input may contain retired credential-bearing URLs; never echo it.
      throw const FormatException('Invalid gateway invitation');
    }
  }
}
