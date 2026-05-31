import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../protocol/navivox_json.dart';

class AppInstallIdentityService {
  AppInstallIdentityService({Random? random})
    : _random = random ?? Random.secure();

  static const identityKey = 'navivox.app_install_identity';

  final Random _random;
  SharedPreferences? _preferences;

  Future<String> getOrCreate() async {
    final preferences = await _prefs();
    final existing = preferences.getString(identityKey);
    final normalized = navivoxOptionalStringFromJson(existing);
    if (normalized != null) return normalized;

    final created = _newIdentity();
    await preferences.setString(identityKey, created);
    return created;
  }

  Future<void> clearForTesting() async {
    final preferences = await _prefs();
    await preferences.remove(identityKey);
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  String _newIdentity() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return 'navi-install-$hex';
  }
}
