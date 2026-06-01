/// Parsed outer URI contract for a `navivox://connect` pairing descriptor.
///
/// The descriptor envelope is intentionally closed: all connection state must
/// live in explicit query fields so it can be replayed, validated, and tested.
class PairingDescriptorEnvelope {
  const PairingDescriptorEnvelope._(this.uri);

  factory PairingDescriptorEnvelope.parse(String descriptor) {
    final uri = Uri.parse(descriptor.trim());
    final address = PairingDescriptorEnvelopeAddress.fromUri(uri);
    if (!address.isConnectDescriptor) {
      throw FormatException(
        'Expected navivox://connect descriptor',
        descriptor,
      );
    }
    if (uri.path.isNotEmpty || uri.hasFragment) {
      throw FormatException(
        'Pairing descriptor must not include path or fragment state',
        descriptor,
      );
    }
    if (uri.userInfo.isNotEmpty) {
      throw FormatException(
        'Pairing descriptor must not include userinfo',
        descriptor,
      );
    }
    return PairingDescriptorEnvelope._(uri);
  }

  final Uri uri;

  Map<String, List<String>> get queryParametersAll => uri.queryParametersAll;

  String get rawQuery => uri.query;
}

/// Case-normalized descriptor envelope address.
///
/// URI scheme and host casing are transport syntax, not pairing state. Keeping
/// that normalization replayable prevents the envelope gate from drifting into
/// case-sensitive string checks while path, fragment, and userinfo remain hard
/// failures because they can hide non-query connection state.
class PairingDescriptorEnvelopeAddress {
  const PairingDescriptorEnvelopeAddress({
    required this.scheme,
    required this.host,
  });

  factory PairingDescriptorEnvelopeAddress.fromUri(Uri uri) {
    return PairingDescriptorEnvelopeAddress(
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
    );
  }

  final String scheme;
  final String host;

  bool get isConnectDescriptor => scheme == 'navivox' && host == 'connect';
}
