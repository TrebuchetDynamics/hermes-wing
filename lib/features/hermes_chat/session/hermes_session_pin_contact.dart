import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../gateways/gateway_contact.dart';

/// Pins are presentation state for one exact saved or direct connection owner.
/// Ambiguous legacy `direct` records are retained but cannot identify an origin.
GatewayContactId? hermesSessionPinContact({
  required GatewayContactId? savedContact,
  required String? baseUrl,
  required String? profileId,
}) {
  if (savedContact != null) return savedContact;
  final endpoint = baseUrl?.trim();
  if (endpoint == null || endpoint.isEmpty) return null;
  return GatewayContactId(
    gatewayId: 'direct-v2:${sha256.convert(utf8.encode(endpoint))}',
    profileId: profileId ?? 'default',
  );
}
