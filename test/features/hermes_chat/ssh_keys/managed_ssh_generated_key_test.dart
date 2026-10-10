import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:pinenacl/ed25519.dart' show VerifyKey, Signature;
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/ssh_keys/managed_ssh_generated_key.dart';

void main() {
  test('rejects public/private mismatch rather than trusting PEM fields', () {
    final key = ManagedSshGeneratedKey.generate();
    final other =
        SSHKeyPair.fromPem(ManagedSshGeneratedKey.generate().privatePem).single
            as OpenSSHEd25519KeyPair;
    final original =
        SSHKeyPair.fromPem(key.privatePem).single as OpenSSHEd25519KeyPair;
    final mismatch = OpenSSHEd25519KeyPair(
      other.publicKey,
      original.privateKey,
      'hermes-wing',
    ).toPem();
    expect(
      () => ManagedSshGeneratedKey.fromPrivatePem(mismatch),
      throwsFormatException,
    );
    final damaged = Uint8List.fromList(original.privateKey)..[63] ^= 1;
    final invalid = OpenSSHEd25519KeyPair(
      original.publicKey,
      damaged,
      'hermes-wing',
    ).toPem();
    expect(
      () => ManagedSshGeneratedKey.fromPrivatePem(invalid),
      throwsFormatException,
    );
    expect(
      () => ManagedSshGeneratedKey.fromPrivatePem('not a key'),
      throwsFormatException,
    );
    final oversized = List.filled(65537, 'a').join();
    expect(
      () => ManagedSshGeneratedKey.fromPrivatePem(oversized),
      throwsFormatException,
    );
  });
  test('generated key signs and verifies through OpenSSH roundtrip', () {
    final key = ManagedSshGeneratedKey.generate();
    final pair =
        SSHKeyPair.fromPem(key.privatePem).single as OpenSSHEd25519KeyPair;
    final public = SSHRawHostKey(base64.decode(key.publicKey.split(' ')[1]));
    expect(
      base64.encode(public.encode()) ==
          base64.encode(pair.toPublicKey().encode()),
      isTrue,
    );
    final message = Uint8List.fromList(utf8.encode('Wing key roundtrip'));
    expect(
      VerifyKey(pair.publicKey).verify(
        message: message,
        signature: Signature(pair.sign(message).signature),
      ),
      isTrue,
    );
    expect(key.publicKey.split(' ').first, 'ssh-ed25519');
    expect(key.publicKey.split(' ').last, 'hermes-wing');
    expect(key.publicKey.contains('\n'), isFalse);
    expect(
      key.fingerprint ==
          'SHA256:${base64.encode(sha256.convert(public.encode()).bytes).replaceAll('=', '')}',
      isTrue,
    );
    expect(key.toString(), 'ManagedSshGeneratedKey(redacted)');
    expect(
      ManagedSshGeneratedKey.generate().publicKey == key.publicKey,
      isFalse,
    );
  });
}
