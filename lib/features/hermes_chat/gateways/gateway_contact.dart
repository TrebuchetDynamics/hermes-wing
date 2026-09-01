import 'package:flutter/foundation.dart';

import '../../../core/hermes/models/hermes_session.dart';

@immutable
class GatewayContactId {
  const GatewayContactId({required this.gatewayId, required this.profileId});

  final String gatewayId;
  final String profileId;

  @override
  bool operator ==(Object other) =>
      other is GatewayContactId &&
      other.gatewayId == gatewayId &&
      other.profileId == profileId;

  @override
  int get hashCode => Object.hash(gatewayId, profileId);
}

enum GatewayAvailability { refreshing, online, offline, authenticationFailed }

@immutable
class GatewayOverview {
  const GatewayOverview({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.availability,
    this.lastRefreshedAt,
  });

  final String id;
  final String label;
  final String baseUrl;
  final GatewayAvailability availability;
  final DateTime? lastRefreshedAt;
}

@immutable
class GatewayContact {
  const GatewayContact({
    required this.id,
    required this.gatewayLabel,
    required this.profileName,
    required this.sessionCount,
    required this.availability,
    this.latestSession,
    this.lastRefreshedAt,
    this.isFallbackProfile = false,
    this.chatAvailable = true,
  });

  final GatewayContactId id;
  final String gatewayLabel;
  final String profileName;
  final HermesSession? latestSession;
  final int sessionCount;
  final GatewayAvailability availability;
  final DateTime? lastRefreshedAt;
  final bool isFallbackProfile;
  final bool chatAvailable;

  DateTime? get latestActivity =>
      DateTime.tryParse(latestSession?.lastActive ?? '')?.toUtc();

  GatewayContact copyWith({
    String? gatewayLabel,
    GatewayAvailability? availability,
    DateTime? lastRefreshedAt,
  }) => GatewayContact(
    id: id,
    gatewayLabel: gatewayLabel ?? this.gatewayLabel,
    profileName: profileName,
    latestSession: latestSession,
    sessionCount: sessionCount,
    availability: availability ?? this.availability,
    lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    isFallbackProfile: isFallbackProfile,
    chatAvailable: chatAvailable,
  );

  Map<String, Object?> toJson() => {
    'gatewayId': id.gatewayId,
    'profileId': id.profileId,
    'gatewayLabel': gatewayLabel,
    'profileName': profileName,
    'sessionCount': sessionCount,
    'availability': availability.name,
    'lastRefreshedAt': lastRefreshedAt?.toUtc().toIso8601String(),
    'isFallbackProfile': isFallbackProfile,
    'chatAvailable': chatAvailable,
    if (latestSession case final session?)
      'latestSession': {
        'id': session.id,
        'title': session.title,
        'lastActive': session.lastActive,
      },
  };

  factory GatewayContact.fromJson(Map<String, Object?> json) {
    final latest = json['latestSession'];
    final latestMap = latest is Map ? latest.cast<String, Object?>() : null;
    return GatewayContact(
      id: GatewayContactId(
        gatewayId: json['gatewayId']?.toString() ?? '',
        profileId: json['profileId']?.toString() ?? '',
      ),
      gatewayLabel: json['gatewayLabel']?.toString() ?? '',
      profileName: json['profileName']?.toString() ?? '',
      sessionCount: _nonNegativeCount(json['sessionCount']),
      availability: GatewayAvailability.values.firstWhere(
        (value) => value.name == json['availability'],
        orElse: () => GatewayAvailability.offline,
      ),
      lastRefreshedAt: DateTime.tryParse(
        json['lastRefreshedAt']?.toString() ?? '',
      )?.toUtc(),
      isFallbackProfile: json['isFallbackProfile'] == true,
      chatAvailable: json['chatAvailable'] != false,
      latestSession: latestMap == null
          ? null
          : HermesSession(
              id: latestMap['id']?.toString() ?? '',
              source: 'contact_cache',
              title: latestMap['title']?.toString(),
              lastActive: latestMap['lastActive']?.toString(),
            ),
    );
  }
}

int _nonNegativeCount(Object? value) {
  final count = int.tryParse('$value') ?? 0;
  return count < 0 ? 0 : count;
}

List<GatewayContact> sortGatewayContacts(Iterable<GatewayContact> contacts) {
  final result = contacts.toList(growable: false);
  result.sort((a, b) {
    final activity = (b.latestActivity?.millisecondsSinceEpoch ?? -1).compareTo(
      a.latestActivity?.millisecondsSinceEpoch ?? -1,
    );
    if (activity != 0) return activity;
    final gateway = a.id.gatewayId.compareTo(b.id.gatewayId);
    return gateway != 0 ? gateway : a.id.profileId.compareTo(b.id.profileId);
  });
  return result;
}
