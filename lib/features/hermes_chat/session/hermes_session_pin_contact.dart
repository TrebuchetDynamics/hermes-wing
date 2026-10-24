import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../gateways/gateway_contact.dart';

/// Pins are presentation state for one exact saved or direct connection owner.
/// Ambiguous legacy `direct` records are retained but cannot identify an origin.
GatewayContactId? hermesSessionPinContact({
  required GatewayContactId? savedContact,
  String? savedBaseUrl,
  required String? baseUrl,
  required String? profileId,
}) {
  final endpoint = baseUrl?.trim();
  if (endpoint == null || endpoint.isEmpty) return null;
  final profile = profileId ?? 'default';
  // A directory selection can outlive a manual connection or profile change.
  // Reuse its stable namespace only while the channel still names that owner.
  if (savedContact != null &&
      savedBaseUrl?.trim() == endpoint &&
      savedContact.profileId == profile) {
    return savedContact;
  }
  return GatewayContactId(
    gatewayId: 'direct-v2:${sha256.convert(utf8.encode(endpoint))}',
    profileId: profile,
  );
}
