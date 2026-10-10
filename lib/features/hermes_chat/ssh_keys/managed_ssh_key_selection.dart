import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart';

/// Deliberate native file/document selection; never supplies an initial path.
typedef ManagedSshKeyPicker = Future<XFile?> Function();
Future<XFile?> pickManagedSshKey() => openFile();

enum ManagedSshKeyFailure { unreadable, tooLarge, unsupported, invalid }

/// Carries only an allowlisted reason, never a path, PEM or plugin exception.
class ManagedSshKeyException implements Exception {
  const ManagedSshKeyException(this.failure);
  final ManagedSshKeyFailure failure;
  @override
  String toString() => 'Managed SSH key: ${failure.name}';
}

/// Attempt-scoped content, not a saved path or a credential-store record.
class SelectedManagedSshKey {
  SelectedManagedSshKey._(
    this.pem,
    this.filename,
    this.fingerprint,
    this.encrypted,
  );
  static const maxBytes = 64 * 1024;
  final String pem;
  final String filename;
  final String? fingerprint;
  final bool encrypted;

  void unlock(String passphrase) {
    SSHKeyPair.fromPem(pem, passphrase).single;
  }

  static Future<SelectedManagedSshKey> read(XFile file) async {
    final bytes = BytesBuilder(copy: false);
    try {
      if (await file.length() > maxBytes) {
        throw const ManagedSshKeyException(ManagedSshKeyFailure.tooLarge);
      }
      // Recheck actual streamed content: reported document size can be stale.
      await for (final chunk in file.openRead()) {
        if (bytes.length + chunk.length > maxBytes) {
          throw const ManagedSshKeyException(ManagedSshKeyFailure.tooLarge);
        }
        bytes.add(chunk);
      }
    } on ManagedSshKeyException {
      rethrow;
    } catch (_) {
      throw const ManagedSshKeyException(ManagedSshKeyFailure.unreadable);
    }
    try {
      final pem = utf8.decode(bytes.takeBytes());
      final encrypted = SSHKeyPair.isEncryptedPem(pem);
      final pair = encrypted ? null : SSHKeyPair.fromPem(pem).single;
      Uint8List? publicKey = pair?.toPublicKey().encode();
      final decoded = SSHPem.decode(pem);
      if (decoded.type == 'OPENSSH PRIVATE KEY') {
        final keys = OpenSSHKeyPairs.decode(decoded.content);
        publicKey = keys.publicKeys.single;
        if (!const {
          'ssh-ed25519',
          'ssh-rsa',
          'ecdsa-sha2-nistp256',
          'ecdsa-sha2-nistp384',
          'ecdsa-sha2-nistp521',
        }.contains(SSHHostKey.getType(publicKey))) {
          throw const ManagedSshKeyException(ManagedSshKeyFailure.unsupported);
        }
        final options = keys.kdfOptions;
        if (keys.isEncrypted &&
            (SSHCipherType.fromName(keys.cipherName) == null ||
                options is! OpenSSHBcryptKdfOptions ||
                options.rounds < 1 ||
                options.rounds > 64)) {
          throw const ManagedSshKeyException(ManagedSshKeyFailure.unsupported);
        }
      }
      final filename = file.name.replaceAll('\\', '/').split('/').last;
      final safeFilename =
          RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._ -]{0,127}$').hasMatch(filename) &&
              !filename.contains('PRIVATE KEY')
          ? filename
          : '';
      return SelectedManagedSshKey._(
        pem,
        safeFilename,
        publicKey == null
            ? null
            : 'SHA256:${base64.encode(sha256.convert(publicKey).bytes).replaceAll('=', '')}',
        encrypted,
      );
    } on ManagedSshKeyException {
      rethrow;
    } on UnsupportedError {
      throw const ManagedSshKeyException(ManagedSshKeyFailure.unsupported);
    } catch (_) {
      throw const ManagedSshKeyException(ManagedSshKeyFailure.invalid);
    }
  }

  @override
  String toString() => 'SelectedManagedSshKey(redacted)';
}
