import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_contact.dart';

class GatewayContactCache {
  static const _key = 'wing.hermes.gateway_contacts.v1';

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
  }
}
