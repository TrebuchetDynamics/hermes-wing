import 'dart:typed_data';

import 'durable_credential_key_alias.dart';
import 'public_json_web_key.dart';

abstract interface class DurableCredentialKeyStore {
  Future<bool> isAvailable();

  Future<PublicJsonWebKey> createEs256KeyPair({
    required DurableCredentialKeyAlias alias,
  });

  Future<Uint8List> sign({
    required DurableCredentialKeyAlias alias,
    required Uint8List canonicalPayload,
  });

  Future<void> deleteKey({required DurableCredentialKeyAlias alias});
}
