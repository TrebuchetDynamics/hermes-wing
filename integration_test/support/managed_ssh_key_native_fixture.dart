import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
// The plugin's platform seam is intentionally test-only; no production dependency
// or connected-state substitute is introduced.
// ignore: depend_on_referenced_packages
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

/// Generated assets exist only in the disposable snapshot, never in the repo.
/// Do not print this object or use secret-bearing values in expectation messages.
class ManagedSshKeyNativeFixture {
  ManagedSshKeyNativeFixture._(this._runtime);
  final Map<String, dynamic> _runtime;
  static const asset = 'integration_test/managed_ssh_key_native_runtime.json';

  static Future<ManagedSshKeyNativeFixture> load() async {
    final runtime =
        jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
    if (runtime['host'] != '127.0.0.1' ||
        runtime['picker'] != 'BOUNDED_DOCUMENT_SUBSTITUTE') {
      throw StateError('Disposable launcher metadata required');
    }
    return ManagedSshKeyNativeFixture._(runtime);
  }

  String get host => _runtime['host'] as String;
  String get username => _runtime['username'] as String;
  String get fingerprint => _runtime['fingerprint'] as String;
  int get sshPort => _runtime['ssh_port'] as int;
  int get agentPort => _runtime['agent_port'] as int;
  String get agentToken => _runtime['agent_token'] as String;

  XFile document(String mode) {
    if (!{'valid', 'wrong', 'invalid'}.contains(mode)) {
      throw StateError('Unknown owned document');
    }
    final bytes = utf8.encode(_runtime['${mode}_key'] as String);
    if (bytes.length > 65536) throw StateError('Document bound exceeded');
    return XFile.fromData(
      Uint8List.fromList(bytes),
      name: 'disposable-key',
      mimeType: 'application/octet-stream',
    );
  }

  Future<Map<String, dynamic>> control(String action) async {
    if (!{'stats', 'hold', 'release'}.contains(action)) {
      throw StateError('Unknown fixture control');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.openUrl(
        action == 'stats' ? 'GET' : 'POST',
        Uri.parse('http://$host:${_runtime['control_port']}/$action'),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) {
        throw StateError('Fixture control rejected');
      }
      final bytes = await response.fold<List<int>>([], (value, chunk) {
        if (value.length + chunk.length > 16384) {
          throw StateError('Fixture receipt bound exceeded');
        }
        return value..addAll(chunk);
      });
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } finally {
      client.close(force: true);
    }
  }

  void dispose() => _runtime.clear();
}

/// Only selected-document acquisition is substituted. Production key parsing,
/// form, controller, SSH authentication, host review and HTTP remain real.
/// Actual Linux chooser / Android SAF and persisted URI access: NOT_CHECKED.
class ManagedSshKeyDocumentSelector extends FileSelectorPlatform {
  XFile? next;
  Completer<XFile?>? pending;
  int selections = 0;

  Completer<XFile?> hold() {
    if (pending != null) throw StateError('A selection is already held');
    return pending = Completer<XFile?>();
  }

  @override
  Future<XFile?> openFile({
    List<XTypeGroup>? acceptedTypeGroups,
    String? initialDirectory,
    String? confirmButtonText,
  }) async {
    selections++;
    final held = pending;
    pending = null;
    if (held != null) return held.future;
    final selected = next;
    next = null;
    return selected;
  }
}

FileSelectorPlatform installManagedSshDocumentSelector(
  ManagedSshKeyDocumentSelector selector,
) {
  final original = FileSelectorPlatform.instance;
  FileSelectorPlatform.instance = selector;
  return original;
}

void restoreManagedSshDocumentSelector(FileSelectorPlatform original) =>
    FileSelectorPlatform.instance = original;
