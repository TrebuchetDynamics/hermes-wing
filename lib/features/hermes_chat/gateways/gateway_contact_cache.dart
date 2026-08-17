import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_contact.dart';

class GatewayContactSelection {
  const GatewayContactSelection({required this.contactId, this.sessionId});

  final GatewayContactId contactId;
  final String? sessionId;
}

class GatewayContactCache {
  static const _key = 'wing.hermes.gateway_contacts.v1';
  static const _selectionKey = 'wing.hermes.gateway_contact_selection.v1';

  Future<List<GatewayContact>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return sortGatewayContacts([
        for (final item in decoded)
          if (item is Map)
            GatewayContact.fromJson(
              item.cast<String, Object?>(),
            ).copyWith(availability: GatewayAvailability.offline),
      ]);
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<GatewayContact> contacts) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode([for (final contact in contacts) contact.toJson()]),
    );
  }

  Future<void> removeGateway(String gatewayId) async {
    await save([
      for (final contact in await load())
        if (contact.id.gatewayId != gatewayId) contact,
    ]);
    final selection = await loadSelection();
    if (selection?.contactId.gatewayId == gatewayId) await clearSelection();
  }

  Future<GatewayContactSelection?> loadSelection() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _selectionKey,
      );
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final data = decoded.cast<String, Object?>();
      final gatewayValue = data['gatewayId'];
      final profileValue = data['profileId'];
      final sessionValue = data['sessionId'];
      if (gatewayValue is! String ||
          profileValue is! String ||
          (sessionValue != null && sessionValue is! String)) {
        return null;
      }
      final gatewayId = gatewayValue.trim();
      final profileId = profileValue.trim();
      final sessionId = (sessionValue as String?)?.trim();
      if (gatewayId.isEmpty || profileId.isEmpty) return null;
      return GatewayContactSelection(
        contactId: GatewayContactId(gatewayId: gatewayId, profileId: profileId),
        sessionId: sessionId?.isEmpty == true ? null : sessionId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSelection(GatewayContactSelection selection) async {
    await (await SharedPreferences.getInstance()).setString(
      _selectionKey,
      jsonEncode({
        'gatewayId': selection.contactId.gatewayId,
        'profileId': selection.contactId.profileId,
        'sessionId': ?selection.sessionId,
      }),
    );
  }

  Future<void> clearSelection() async {
    await (await SharedPreferences.getInstance()).remove(_selectionKey);
  }
}
