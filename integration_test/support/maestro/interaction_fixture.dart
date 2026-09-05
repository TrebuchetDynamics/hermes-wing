import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:wing/features/hermes_chat/groups/chat_group_controller.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';

/// Only synthetic picker data and bounded assertions are exposed to Maestro.
class InteractionFixture {
  String pickerMode = 'text';
  Completer<XFile?>? pendingPick;
  int pickerCalls = 0;
  bool textExportMatches = false;
  bool markdownExportMatches = false;
  bool groupSaved = false;
  bool groupMoved = false;
  bool groupDeleted = false;

  static const textContent = 'Fixture attachment content';
  static final imageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a5ZkAAAAASUVORK5CYII=',
  );

  static XFile textFile() => XFile.fromData(
    Uint8List.fromList(utf8.encode(textContent)),
    name: 'fixture-note.txt',
    path: 'fixture-note.txt',
    mimeType: 'text/plain',
  );

  Future<XFile?> pick() async {
    pickerCalls++;
    return switch (pickerMode) {
      'cancel' => null,
      'deferred' => (pendingPick = Completer<XFile?>()).future,
      'image' => XFile.fromData(
        imageBytes,
        name: 'fixture-image.png',
        path: 'fixture-image.png',
      ),
      'binary' => XFile.fromData(
        Uint8List.fromList([0, 1, 2]),
        name: 'fixture.bin',
        path: 'fixture.bin',
      ),
      'oversize' => XFile.fromData(
        Uint8List(256 * 1024 + 1),
        name: 'fixture-big.txt',
        path: 'fixture-big.txt',
      ),
      'invalid' => XFile.fromData(
        Uint8List.fromList([255]),
        name: 'fixture-invalid.txt',
        path: 'fixture-invalid.txt',
      ),
      _ => textFile(),
    };
  }

  void completePick() {
    final pending = pendingPick;
    if (pending == null || pending.isCompleted) {
      throw StateError('No pending fixture pick');
    }
    pending.complete(textFile());
    pendingPick = null;
  }

  Future<void> checkExport() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    textExportMatches =
        text == 'You:\nFixture export\n\nHermes:\nFixture decision once';
    markdownExportMatches =
        text ==
        '## You\n\nFixture export\n\n## Hermes\n\nFixture decision once';
  }

  Future<void> checkGroups() async {
    final groups = ChatGroupController();
    try {
      await groups.load();
      groupSaved = groups.groups.any((g) => g.name == 'Fixture renamed');
      groupMoved =
          groups.groupIdFor(
            const GatewayContactId(gatewayId: 'fixture', profileId: 'default'),
          ) !=
          null;
      groupDeleted = groups.groups.isEmpty && !groupMoved;
    } finally {
      groups.dispose();
    }
  }
}
