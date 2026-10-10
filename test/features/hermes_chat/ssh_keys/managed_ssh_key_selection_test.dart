import 'dart:convert';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/hermes_chat/ssh_keys/managed_ssh_key_selection.dart';
import 'synthetic_ssh_keys.dart';

class GrowingDocument extends XFile {
  GrowingDocument() : super.fromData(Uint8List(0));
  bool cancelled = false;
  int chunks = 0;
  @override
  Future<int> length() async => 1;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    try {
      for (var i = 0; i < 10; i++) {
        chunks++;
        yield Uint8List(32768);
      }
    } finally {
      cancelled = true;
    }
  }
}

void main() {
  test('bounds streamed bytes even when document length is stale', () async {
    final document = GrowingDocument();
    await expectLater(
      SelectedManagedSshKey.read(document),
      throwsA(
        isA<ManagedSshKeyException>().having(
          (e) => e.failure,
          'reason',
          ManagedSshKeyFailure.tooLarge,
        ),
      ),
    );
    expect(document.cancelled, isTrue);
    expect(document.chunks, 3);
  });
  test(
    'unsafe and unbounded display names are replaced, never rendered as paths',
    () async {
      for (final name in [
        '\u202esecret',
        'a' * 129,
        '-----BEGIN PRIVATE KEY-----',
        '..',
        '/',
      ]) {
        final key = await SelectedManagedSshKey.read(
          XFile.fromData(utf8.encode(syntheticSshKey()), path: name),
        );
        expect(
          key.filename,
          isEmpty,
          reason: 'Unsafe display name must use localized fallback.',
        );
        expect(key.toString(), 'SelectedManagedSshKey(redacted)');
      }
    },
  );
  test(
    'encrypted OpenSSH key exposes only public fingerprint before unlocking',
    () async {
      final encrypted = await SelectedManagedSshKey.read(
        XFile.fromData(
          utf8.encode(syntheticSshKey(passphrase: 'synthetic-passphrase')),
          path: 'fixture',
        ),
      );
      final plain = await SelectedManagedSshKey.read(
        XFile.fromData(utf8.encode(syntheticSshKey()), path: 'fixture'),
      );
      expect(encrypted.fingerprint, plain.fingerprint);
      expect(encrypted.fingerprint, startsWith('SHA256:'));
    },
  );
  test(
    'rejects unsupported encrypted public-key algorithms before forwarding',
    () async {
      final pairs = OpenSSHKeyPairs.decode(
        SSHPem.decode(
          syntheticSshKey(passphrase: 'synthetic-passphrase'),
        ).content,
      );
      final unsupported = OpenSSHKeyPairs(
        cipherName: pairs.cipherName,
        kdfName: pairs.kdfName,
        kdfOptions: pairs.kdfOptions,
        publicKeys: [
          Uint8List.fromList([0, 0, 0, 7, ...ascii.encode('ssh-dss')]),
        ],
        privateKeyBlob: pairs.privateKeyBlob,
      ).toPem();
      await expectLater(
        SelectedManagedSshKey.read(XFile.fromData(utf8.encode(unsupported))),
        throwsA(
          isA<ManagedSshKeyException>().having(
            (e) => e.failure,
            'reason',
            ManagedSshKeyFailure.unsupported,
          ),
        ),
      );
    },
  );
  test(
    'rejects excessive encrypted-key KDF work before requesting passphrase',
    () async {
      final text = syntheticSshKey(passphrase: 'synthetic-passphrase');
      final pairs = OpenSSHKeyPairs.decode(SSHPem.decode(text).content);
      final options = pairs.kdfOptions as OpenSSHBcryptKdfOptions;
      final dangerous = OpenSSHKeyPairs(
        cipherName: pairs.cipherName,
        kdfName: pairs.kdfName,
        kdfOptions: OpenSSHBcryptKdfOptions(options.salt, 1000000000),
        publicKeys: pairs.publicKeys,
        privateKeyBlob: pairs.privateKeyBlob,
      ).toPem();
      await expectLater(
        SelectedManagedSshKey.read(XFile.fromData(utf8.encode(dangerous))),
        throwsA(
          isA<ManagedSshKeyException>().having(
            (e) => e.failure,
            'reason',
            ManagedSshKeyFailure.unsupported,
          ),
        ),
      );
    },
  );
}
