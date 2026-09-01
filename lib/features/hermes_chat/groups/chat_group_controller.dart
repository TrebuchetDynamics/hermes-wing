import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../gateways/gateway_contact.dart';

@immutable
class ChatGroup {
  const ChatGroup({required this.id, required this.name});

  final String id;
  final String name;
}

class ChatGroupController extends ChangeNotifier {
  ChatGroupController({String Function()? idFactory})
    : _idFactory = idFactory ?? _defaultId;

  static const _key = 'wing.hermes.chat_groups.v1';
  final String Function() _idFactory;
  List<ChatGroup> _groups = const [];
  Map<GatewayContactId, String> _assignments = const {};

  List<ChatGroup> get groups => List.unmodifiable(_groups);

  String? groupIdFor(GatewayContactId contactId) => _assignments[contactId];

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final data = decoded.cast<String, Object?>();
      final rawGroups = data['groups'];
      final rawAssignments = data['assignments'];
      if (rawGroups is! List || rawAssignments is! List) return;
      final groups = <ChatGroup>[];
      for (final value in rawGroups) {
        if (value is! Map) continue;
        final row = value.cast<String, Object?>();
        final id = row['id'];
        final name = row['name'];
        if (id is String &&
            id.isNotEmpty &&
            name is String &&
            name.isNotEmpty) {
          groups.add(ChatGroup(id: id, name: name));
        }
      }
      final groupIds = groups.map((group) => group.id).toSet();
      final assignments = <GatewayContactId, String>{};
      for (final value in rawAssignments) {
        if (value is! Map) continue;
        final row = value.cast<String, Object?>();
        final gatewayId = row['gatewayId'];
        final profileId = row['profileId'];
        final groupId = row['groupId'];
        if (gatewayId is String &&
            gatewayId.isNotEmpty &&
            profileId is String &&
            profileId.isNotEmpty &&
            groupId is String &&
            groupIds.contains(groupId)) {
          assignments[GatewayContactId(
                gatewayId: gatewayId,
                profileId: profileId,
              )] =
              groupId;
        }
      }
      _groups = groups;
      _assignments = assignments;
      notifyListeners();
    } catch (_) {
      _groups = const [];
      _assignments = const {};
    }
  }

  Future<String> createGroup(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError.value(name, 'name');
    final id = _idFactory();
    _groups = [..._groups, ChatGroup(id: id, name: normalized)];
    notifyListeners();
    await _save();
    return id;
  }

  Future<void> renameGroup(String groupId, String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ArgumentError.value(name, 'name');
    if (!_groups.any((group) => group.id == groupId)) {
      throw ArgumentError.value(groupId, 'groupId');
    }
    _groups = [
      for (final group in _groups)
        group.id == groupId ? ChatGroup(id: group.id, name: normalized) : group,
    ];
    notifyListeners();
    await _save();
  }

  Future<void> deleteGroup(String groupId) async {
    _groups = [
      for (final group in _groups)
        if (group.id != groupId) group,
    ];
    _assignments = {
      for (final entry in _assignments.entries)
        if (entry.value != groupId) entry.key: entry.value,
    };
    notifyListeners();
    await _save();
  }

  Future<void> moveContact(GatewayContactId contactId, String? groupId) async {
    if (groupId != null && !_groups.any((group) => group.id == groupId)) {
      throw ArgumentError.value(groupId, 'groupId');
    }
    _assignments = {..._assignments};
    if (groupId == null) {
      _assignments.remove(contactId);
    } else {
      _assignments[contactId] = groupId;
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode({
        'groups': [
          for (final group in _groups) {'id': group.id, 'name': group.name},
        ],
        'assignments': [
          for (final entry in _assignments.entries)
            {
              'gatewayId': entry.key.gatewayId,
              'profileId': entry.key.profileId,
              'groupId': entry.value,
            },
        ],
      }),
    );
  }

  static String _defaultId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
