import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/features/voice_commands/models/voice_command.dart';
import 'package:wing/features/voice_commands/services/voice_command_catalog.dart';

void main() {
  test('catalog exposes nine tools whose names round-trip to ids', () {
    final decoded = jsonDecode(VoiceCommandCatalog.toolsJson) as List<dynamic>;
    expect(decoded, hasLength(9));
    for (final tool in decoded) {
      final name = ((tool as Map)['function'] as Map)['name'] as String;
      expect(
        VoiceCommandCatalog.byWireName(name),
        isNotNull,
        reason: 'unmapped tool $name',
      );
    }
    expect(VoiceCommandCatalog.byWireName('send_message'), isNull);
    expect(VoiceCommandId.navigateToScreen.wireName, 'navigate_to_screen');
  });

  test('describe renders a human-readable action line', () {
    const result = VoiceRouteResult(
      command: VoiceCommandId.switchSession,
      args: {'session_name': 'groceries'},
      tier: VoiceCommandTier.confirm,
      transcript: 'switch to my groceries session',
    );
    expect(result.describe(), 'Switch to session "groceries"?');
    const nav = VoiceRouteResult(
      command: VoiceCommandId.navigateToScreen,
      args: {'screen': 'settings'},
      tier: VoiceCommandTier.instant,
      transcript: 'open the settings screen',
    );
    expect(nav.describe(), 'Opening Settings');
  });
}
