import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart';

/// App-owned key material. Only [publicKey] may be copied or shared.
class ManagedSshGeneratedKey {
  ManagedSshGeneratedKey._(this.privatePem, OpenSSHEd25519KeyPair pair)
    : publicKey =
          'ssh-ed25519 ${base64.encode(pair.toPublicKey().encode())} hermes-wing',
      fingerprint =
          'SHA256:${base64.encode(sha256.convert(pair.toPublicKey().encode()).bytes).replaceAll('=', '')}';

  final String privatePem;
  final String publicKey;
  final String fingerprint;

  static ManagedSshGeneratedKey generate() {
    final signing = SigningKey.generate();
    final pair = OpenSSHEd25519KeyPair(
      signing.verifyKey.asTypedList,
      signing.asTypedList,
      'hermes-wing',
    );
    return ManagedSshGeneratedKey._(pair.toPem(), pair);
  }

  static ManagedSshGeneratedKey fromPrivatePem(String pem) {
    try {
      if (pem.length > 64 * 1024) throw const FormatException();
      final decoded = SSHPem.decode(pem);
      if (decoded.type != 'OPENSSH PRIVATE KEY') throw const FormatException();
      final envelope = OpenSSHKeyPairs.decode(decoded.content);
      if (envelope.isEncrypted || envelope.publicKeys.length != 1) {
        throw const FormatException();
      }
      final pair = SSHKeyPair.fromPem(pem).single;
      if (pair is! OpenSSHEd25519KeyPair ||
          pair.publicKey.length != 32 ||
          pair.privateKey.length != 64 ||
          pair.comment != 'hermes-wing') {
        throw const FormatException();
      }
      // dartssh2 parses embedded public fields; independently derive from seed.
      final derived = SigningKey.fromSeed(pair.privateKey.sublist(0, 32));
      if (!_equal(derived.asTypedList, pair.privateKey) ||
          !_equal(derived.verifyKey.asTypedList, pair.publicKey) ||
          !_equal(envelope.publicKeys.single, pair.toPublicKey().encode())) {
        throw const FormatException();
      }
      return ManagedSshGeneratedKey._(pem, pair);
    } catch (_) {
      // Parser failures may include payload fragments; never propagate them.
      throw const FormatException('Invalid app-managed SSH key');
    }
  }

  static bool _equal(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }

  @override
  String toString() => 'ManagedSshGeneratedKey(redacted)';
}
