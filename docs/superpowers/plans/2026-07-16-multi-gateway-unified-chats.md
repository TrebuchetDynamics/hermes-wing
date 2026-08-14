# Multi-Gateway Unified Chats Implementation Plan

> **Status: foundation implemented; preserved execution history.** The current
> gateway directory and secure endpoint store implement the one-active-channel
> contact model. Current profile discovery may also come from Wing Link's fixed
> compatibility adapter; this plan's unchecked boxes are not a current backlog.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Present the Hermes profiles from every saved Hermes Agent endpoint as one Telegram-style contact list while keeping only the open contact on a full streaming channel.

**Architecture:** A `HermesGatewayDirectory` privately owns saved endpoint configs and lightweight API clients, projects non-secret `GatewayContact` rows, caches those rows, and refreshes at most three gateways concurrently. The existing `HermesApiChannel` remains the sole full channel and is reconfigured only when a contact is opened; generation checks already present in that channel reject stale transport events.

**Tech Stack:** Flutter 3.44.2, Dart 3.12, Riverpod 3 legacy `ChangeNotifierProvider`, existing `HermesApiClient`/`HermesApiChannel`, `SharedPreferences`, `FlutterSecureStorage`, Flutter widget/unit tests.

**Terminology and evidence boundary (2026-07-17):** In this plan, a **gateway** is one saved Hermes Agent endpoint, not a Hermes messaging-platform gateway. Current local evidence and device/fixture deferrals are reconciled in the [Hermes Wing readiness audit](../../runbooks/hermes-readiness-audit.md). The unchecked boxes preserve the original execution sequence rather than reporting current completion; static, unit, and widget checks do not prove physical-device behavior or a real SSE socket count.

## Global Constraints

- Contact identity is the stable `(gatewayId, agentProfileId)` pair; profile/session IDs are never globally unique.
- Gateways without profile support expose one fallback default-agent contact.
- Contacts sort by descending latest session activity; missing activity sorts last with deterministic gateway/profile tie-breaking.
- Refresh at most three gateways concurrently on launch, foreground resume, pull-to-refresh, and every 60 seconds while foregrounded.
- Inactive gateways use lightweight HTTP only; exactly one active contact owns SSE/run streaming.
- Offline gateways retain cached contacts and cannot block healthy gateways.
- Opening an empty contact never creates a session until the user explicitly sends or creates one.
- Credentials remain in platform secure storage/private endpoint configs and never enter contact models, cache JSON, UI text, logs, diagnostics, or analytics; cached contacts also omit transcript previews.
- Switching away from an active run, pending approval, or in-flight submission requires confirmation.
- QR enrollment appends or updates one gateway without replacing unrelated saved gateways.

## File Structure

- Create `lib/features/hermes_chat/gateways/gateway_contact.dart` — immutable gateway/contact IDs, status, latest-session projection, ordering, and cache JSON.
- Create `lib/features/hermes_chat/gateways/gateway_contact_cache.dart` — non-secret SharedPreferences cache.
- Create `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart` — bounded lightweight refresh, failure isolation, private endpoint configs, and active-contact selection.
- Create `lib/features/hermes_chat/gateways/gateway_contacts_view.dart` — Telegram-style contact list widget.
- Modify `lib/features/hermes_chat/providers/hermes_channel_provider.dart` — provide the one channel plus directory; remove single-endpoint auto-connect.
- Modify `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart` — stop creating sessions during connect.
- Modify `lib/features/hermes_chat/screens/hermes_chat_screen.dart` and its `state/` parts — list/chat navigation, switch guard, and gateway-aware header.
- Modify `lib/features/enrollment/providers/hermes_enrollment_provider.dart` — reload the directory after QR enrollment.
- Modify `lib/features/settings/screens/settings_screen.dart` — list, rename, reconnect, and remove saved gateways without reading credentials into widgets.
- Add focused tests under `test/features/hermes_chat/gateways/`, and update existing channel, enrollment, provider, and screen tests.

---

### Task 1: Stop Implicit Session Creation on Connect

**Files:**
- Modify: `lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart`
- Modify: `test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart`

**Interfaces:**
- Consumes: existing `HermesApiChannel.connect({required String baseUrl, String? apiKey})`.
- Produces: a connected `HermesChannelState` with `sessions == []` and `activeSessionId == null` when the server has no sessions, even when `session_create` is advertised.

- [ ] **Step 1: Replace the implicit-create test with the required failing behavior**

```dart
test('connect never creates a session merely by viewing an empty gateway', () async {
  final posts = <String>[];
  final channel = HermesApiChannel(
    clientBuilder: (config) => HermesApiClient(
      config: config,
      get: (uri, headers) async => switch (uri.path) {
        '/health' => '{"status":"ok"}',
        '/v1/capabilities' => _sessionCreateCapabilitiesFixture,
        '/api/sessions' => '{"object":"list","data":[]}',
        _ => throw StateError('unexpected GET $uri'),
      },
      post: (uri, headers, body) async {
        posts.add(uri.path);
        return '{}';
      },
    ),
  );

  await channel.connect(baseUrl: 'http://127.0.0.1:8642');

  expect(channel.state.status, HermesConnectionStatus.connected);
  expect(channel.state.sessions, isEmpty);
  expect(channel.state.activeSessionId, isNull);
  expect(channel.state.messages, isEmpty);
  expect(posts, isEmpty);
});
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart --plain-name "connect never creates a session merely by viewing an empty gateway"
```

Expected: FAIL because `connect()` posts to `/api/sessions`.

- [ ] **Step 3: Remove the implicit create branch**

Replace the `if (sessions.isEmpty) { ... createSession ... } else { ... }` block with:

```dart
final sessions = await client.listSessions();
if (!_isCurrentConnection(generation, client)) return;
final activeId = sessions.firstOrNull?.id;
List<HermesChatTurn>? messages;
if (activeId != null) {
  messages = await _fetchTurns(client, activeId);
}
```

Retain the existing generation check and `_setState()` call immediately after this block.

- [ ] **Step 4: Run connection tests and verify GREEN**

```bash
flutter test --concurrency=1 test/core/hermes/channel/hermes_api_channel_test.dart
```

Expected: all channel tests pass; no test expects a session POST during connect.

- [ ] **Step 5: Commit**

```bash
git add lib/core/hermes/channel/api_channel/hermes_api_channel_connection.dart test/core/hermes/channel/hermes_api_channel_tests/connection_tests.dart
git commit -m "fix(chat): keep empty gateways sessionless"
```

---

### Task 2: Add Non-Secret Gateway Contact Models and Cache

**Files:**
- Create: `lib/features/hermes_chat/gateways/gateway_contact.dart`
- Create: `lib/features/hermes_chat/gateways/gateway_contact_cache.dart`
- Create: `test/features/hermes_chat/gateways/gateway_contact_test.dart`
- Create: `test/features/hermes_chat/gateways/gateway_contact_cache_test.dart`

**Interfaces:**
- Produces: `GatewayContactId`, `GatewayAvailability`, `GatewayOverview`, `GatewayContact`, `sortGatewayContacts`, `GatewayContactCache.load/save/removeGateway`.
- Security: none of these types has an `apiKey`, `token`, `authorization`, or credential field.

- [ ] **Step 1: Write failing model tests**

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wing/core/hermes/models/hermes_session.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';

void main() {
  test('identity includes gateway and profile', () {
    expect(
      const GatewayContactId(gatewayId: 'a', profileId: 'default'),
      isNot(const GatewayContactId(gatewayId: 'b', profileId: 'default')),
    );
  });

  test('contacts sort by latest activity then stable identity', () {
    final contacts = [
      GatewayContact(
        id: const GatewayContactId(gatewayId: 'b', profileId: 'p2'),
        gatewayLabel: 'Beta',
        profileName: 'Two',
        latestSession: const HermesSession(
          id: 's2', source: 'test', lastActive: '2026-07-16T10:00:00Z',
        ),
        sessionCount: 1,
        availability: GatewayAvailability.online,
      ),
      GatewayContact(
        id: const GatewayContactId(gatewayId: 'a', profileId: 'p1'),
        gatewayLabel: 'Alpha',
        profileName: 'One',
        latestSession: const HermesSession(
          id: 's1', source: 'test', lastActive: '2026-07-16T11:00:00Z',
        ),
        sessionCount: 1,
        availability: GatewayAvailability.online,
      ),
    ];

    expect(sortGatewayContacts(contacts).map((c) => c.id.gatewayId), ['a', 'b']);
  });

  test('cache JSON contains no credential-shaped keys', () {
    final json = GatewayContact(
      id: const GatewayContactId(gatewayId: 'a', profileId: 'p1'),
      gatewayLabel: 'Alpha',
      profileName: 'One',
      latestSession: const HermesSession(
        id: 's1', source: 'test', preview: 'private transcript sentinel',
      ),
      sessionCount: 1,
      availability: GatewayAvailability.offline,
    ).toJson();

    expect(
      json.keys.where({'apiKey', 'token', 'authorization'}.contains),
      isEmpty,
    );
    expect(jsonEncode(json), isNot(contains('private transcript sentinel')));
  });
}
```

- [ ] **Step 2: Run model tests and verify RED**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/gateway_contact_test.dart
```

Expected: compilation fails because `gateway_contact.dart` does not exist.

- [ ] **Step 3: Implement the immutable contact model**

Create `gateway_contact.dart` with these public signatures and behavior:

```dart
import 'package:flutter/foundation.dart';

import '../../../../core/hermes/models/hermes_session.dart';

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
  });

  final GatewayContactId id;
  final String gatewayLabel;
  final String profileName;
  final HermesSession? latestSession;
  final int sessionCount;
  final GatewayAvailability availability;
  final DateTime? lastRefreshedAt;
  final bool isFallbackProfile;

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
    if (latestSession case final session?) 'latestSession': {
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
      sessionCount: int.tryParse('${json['sessionCount'] ?? 0}') ?? 0,
      availability: GatewayAvailability.values.firstWhere(
        (value) => value.name == json['availability'],
        orElse: () => GatewayAvailability.offline,
      ),
      lastRefreshedAt: DateTime.tryParse(
        json['lastRefreshedAt']?.toString() ?? '',
      )?.toUtc(),
      isFallbackProfile: json['isFallbackProfile'] == true,
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
```

- [ ] **Step 4: Write the failing cache round-trip test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact_cache.dart';

void main() {
  test('cache restores contacts offline and removes one gateway only', () async {
    SharedPreferences.setMockInitialValues({});
    final cache = GatewayContactCache();
    final contacts = [
      const GatewayContact(
        id: GatewayContactId(gatewayId: 'a', profileId: 'p1'),
        gatewayLabel: 'Alpha', profileName: 'One', sessionCount: 0,
        availability: GatewayAvailability.online,
      ),
      const GatewayContact(
        id: GatewayContactId(gatewayId: 'b', profileId: 'p2'),
        gatewayLabel: 'Beta', profileName: 'Two', sessionCount: 0,
        availability: GatewayAvailability.online,
      ),
    ];

    await cache.save(contacts);
    await cache.removeGateway('a');
    final restored = await cache.load();

    expect(restored, hasLength(1));
    expect(restored.single.id.gatewayId, 'b');
    expect(restored.single.availability, GatewayAvailability.offline);
  });
}
```

- [ ] **Step 5: Implement the cache**

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_contact.dart';

class GatewayContactCache {
  static const _key = 'wing.hermes.gateway_contacts.v1';

  Future<List<GatewayContact>> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return sortGatewayContacts([
        for (final item in decoded)
          if (item is Map)
            GatewayContact.fromJson(item.cast<String, Object?>()).copyWith(
              availability: GatewayAvailability.offline,
            ),
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
```

- [ ] **Step 6: Run model/cache tests and verify GREEN**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/gateway_contact_test.dart test/features/hermes_chat/gateways/gateway_contact_cache_test.dart
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/hermes_chat/gateways/gateway_contact.dart lib/features/hermes_chat/gateways/gateway_contact_cache.dart test/features/hermes_chat/gateways/gateway_contact_test.dart test/features/hermes_chat/gateways/gateway_contact_cache_test.dart
git commit -m "feat(chat): model and cache gateway contacts"
```

---

### Task 3: Build Bounded Lightweight Gateway Refresh

**Files:**
- Create: `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`
- Create: `test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart`
- Create: `test/features/hermes_chat/support/fake_hermes_gateway_directory.dart`

**Interfaces:**
- Consumes: `HermesEndpointStore.loadProfiles()`, `HermesApiClient.health/capabilities/listProfiles/listSessions`, `GatewayContactCache`.
- Produces: `GatewaySummaryLoader`, `HermesApiGatewaySummaryLoader`, `HermesGatewayDirectory.start/refresh/contacts/gateways` and app-lifecycle-owned foreground refresh.
- Private invariant: endpoint configs, including `apiKey`, stay in `_configsById` and are not exposed through public state.

- [ ] **Step 1: Write failing merge/fallback/failure tests using a fake loader**

Define these fakes in `test/features/hermes_chat/support/fake_hermes_gateway_directory.dart` with `dart:async` and `dart:math` imports, import that support file from the directory test, then add the four cases below:

```dart
class FakeGatewayContactCache extends GatewayContactCache {
  FakeGatewayContactCache([List<GatewayContact> initial = const []])
      : stored = [...initial];
  List<GatewayContact> stored;

  @override
  Future<List<GatewayContact>> load() async => [...stored];

  @override
  Future<void> save(List<GatewayContact> contacts) async =>
      stored = [...contacts];

  @override
  Future<void> removeGateway(String gatewayId) async =>
      stored.removeWhere((contact) => contact.id.gatewayId == gatewayId);
}

class FakeGatewaySummaryLoader implements GatewaySummaryLoader {
  FakeGatewaySummaryLoader(this.results, {this.gate});
  final Map<String, Object> results;
  final Completer<void>? gate;
  int active = 0;
  int maxActive = 0;
  final List<String> calls = [];

  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async {
    calls.add(config.id!);
    active++;
    maxActive = max(maxActive, active);
    try {
      if (gate != null) await gate!.future;
      final result = results[config.id];
      if (result is Error) throw result;
      return result! as GatewaySummary;
    } finally {
      active--;
    }
  }
}

GatewaySummary gatewaySummary(List<String> profileIds) => GatewaySummary(
  profiles: [
    for (final id in profileIds)
      HermesProfile(id: id, displayName: id.toUpperCase(), revision: 'r-$id'),
  ],
  sessionsByProfile: {
    for (var index = 0; index < profileIds.length; index++)
      profileIds[index]: [
        HermesSession(
          id: 'session-${profileIds[index]}',
          source: 'test',
          lastActive: '2026-07-16T${(10 + index).toString().padLeft(2, '0')}:00:00Z',
        ),
      ],
  },
);

HermesGatewayDirectory directoryFor({
  required List<HermesEndpointConfig> configs,
  required GatewaySummaryLoader loader,
  GatewayContactCache? cache,
}) => HermesGatewayDirectory(
  store: FakeHermesEndpointStore(profiles: configs),
  cache: cache ?? FakeGatewayContactCache(),
  loader: loader,
  activeChannel: FakeHermesChannel.disconnected(),
  now: () => DateTime.utc(2026, 7, 16),
);

test('merges three plus two profiles into five contacts', () async {
  final directory = directoryFor(
    configs: const [
      HermesEndpointConfig(id: 'a', label: 'Alpha', baseUrl: 'https://a', apiKey: 'secret-a'),
      HermesEndpointConfig(id: 'b', label: 'Beta', baseUrl: 'https://b', apiKey: 'secret-b'),
    ],
    loader: FakeGatewaySummaryLoader({
      'a': gatewaySummary(['a1', 'a2', 'a3']),
      'b': gatewaySummary(['b1', 'b2']),
    }),
  );

  await directory.refresh();

  expect(directory.contacts, hasLength(5));
  expect(directory.contacts.map((c) => c.id.gatewayId).toSet(), {'a', 'b'});
  expect(directory.contacts.map((c) => c.toJson()).toString(), isNot(contains('secret-')));
});

test('profile-less gateway produces one default contact', () async {
  final directory = directoryFor(
    configs: const [
      HermesEndpointConfig(id: 'legacy', label: 'Legacy', baseUrl: 'https://legacy'),
    ],
    loader: FakeGatewaySummaryLoader(const {
      'legacy': GatewaySummary(
        profiles: [], sessionsByProfile: {}, unscopedSessions: [],
      ),
    }),
  );

  await directory.refresh();

  expect(directory.contacts.single.isFallbackProfile, isTrue);
  expect(directory.contacts.single.id.profileId, 'default');
});

test('offline refresh retains cached contacts and healthy gateway results', () async {
  const cached = GatewayContact(
    id: GatewayContactId(gatewayId: 'a', profileId: 'a1'),
    gatewayLabel: 'Alpha', profileName: 'A1', sessionCount: 0,
    availability: GatewayAvailability.offline,
  );
  final directory = directoryFor(
    configs: const [
      HermesEndpointConfig(id: 'a', label: 'Alpha', baseUrl: 'https://a'),
      HermesEndpointConfig(id: 'b', label: 'Beta', baseUrl: 'https://b'),
    ],
    cache: FakeGatewayContactCache(const [cached]),
    loader: FakeGatewaySummaryLoader({
      'a': StateError('offline'),
      'b': gatewaySummary(['b1']),
    }),
  );

  await directory.start();

  expect(directory.contacts.where((c) => c.id.gatewayId == 'a').single.availability,
      GatewayAvailability.offline);
  expect(directory.contacts.where((c) => c.id.gatewayId == 'b').single.availability,
      GatewayAvailability.online);
});

test('refreshes at most three gateways concurrently', () async {
  final gate = Completer<void>();
  final loader = FakeGatewaySummaryLoader(
    {for (final id in ['a', 'b', 'c', 'd', 'e']) id: gatewaySummary([id])},
    gate: gate,
  );
  final directory = directoryFor(
    configs: [
      for (final id in ['a', 'b', 'c', 'd', 'e'])
        HermesEndpointConfig(id: id, label: id, baseUrl: 'https://$id'),
    ],
    loader: loader,
  );

  final refresh = directory.refresh();
  while (loader.maxActive < 3) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(loader.maxActive, 3);
  gate.complete();
  await refresh;
  expect(loader.maxActive, 3);
});
```

- [ ] **Step 2: Run directory tests and verify RED**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart
```

Expected: compilation fails because the directory interfaces do not exist.

- [ ] **Step 3: Implement summary types and real loader**

Use these exact interfaces in `hermes_gateway_directory.dart`:

```dart
class GatewaySummary {
  const GatewaySummary({
    required this.profiles,
    required this.sessionsByProfile,
    this.unscopedSessions = const [],
  });
  final List<HermesProfile> profiles;
  final Map<String, List<HermesSession>> sessionsByProfile;
  final List<HermesSession> unscopedSessions;
}

abstract interface class GatewaySummaryLoader {
  Future<GatewaySummary> load(HermesEndpointConfig config);
}

class HermesApiGatewaySummaryLoader implements GatewaySummaryLoader {
  const HermesApiGatewaySummaryLoader();

  @override
  Future<GatewaySummary> load(HermesEndpointConfig config) async {
    final client = HermesApiClient(
      config: HermesApiConfig.fromBaseUrl(config.baseUrl, apiKey: config.apiKey),
    );
    await client.health();
    final capabilities = await client.capabilities();
    final supportsProfiles = capabilities.advertisesEndpoint(
      'profiles', 'GET', '/api/profiles',
    );
    if (!supportsProfiles) {
      return GatewaySummary(
        profiles: const [],
        sessionsByProfile: const {},
        unscopedSessions: await client.listSessions(),
      );
    }
    final profiles = await client.listProfiles();
    return GatewaySummary(
      profiles: profiles,
      sessionsByProfile: {
        for (final profile in profiles)
          profile.id: await client.listSessions(profile: profile.id),
      },
    );
  }
}
```

- [ ] **Step 4: Implement directory refresh and projection**

Start the class with this exact constructor and public state surface:

```dart
class HermesGatewayDirectory extends ChangeNotifier with WidgetsBindingObserver {
  HermesGatewayDirectory({
    required HermesEndpointStore store,
    required GatewayContactCache cache,
    required GatewaySummaryLoader loader,
    required HermesChannel activeChannel,
    DateTime Function()? now,
    this.maxConcurrent = 3,
  }) : _store = store,
       _cache = cache,
       _loader = loader,
       _activeChannel = activeChannel,
       _now = now ?? DateTime.now;

  final HermesEndpointStore _store;
  final GatewayContactCache _cache;
  final GatewaySummaryLoader _loader;
  final HermesChannel _activeChannel;
  final DateTime Function() _now;
  final int maxConcurrent;
  final Map<String, HermesEndpointConfig> _configsById = {};
  List<GatewayContact> _contacts = const [];
  List<GatewayOverview> _gateways = const [];
  GatewayContactId? _activeContactId;
  bool _refreshing = false;
  bool _started = false;
  int _refreshGeneration = 0;
  int _activationGeneration = 0;
  Timer? _foregroundTimer;

  List<GatewayContact> get contacts => List.unmodifiable(_contacts);
  List<GatewayOverview> get gateways => List.unmodifiable(_gateways);
  GatewayContactId? get activeContactId => _activeContactId;
  GatewayContact? get activeContact => _activeContactId == null
      ? null
      : _contacts.where((contact) => contact.id == _activeContactId).firstOrNull;
  bool get refreshing => _refreshing;
  bool get hasSavedGateways => _configsById.isNotEmpty;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _contacts = await _cache.load();
    notifyListeners();
    await refresh();
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      _startForegroundRefresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startForegroundRefresh();
      unawaited(refresh());
    } else {
      _foregroundTimer?.cancel();
      _foregroundTimer = null;
    }
  }

  void _startForegroundRefresh() {
    if (_foregroundTimer != null) return;
    _foregroundTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => unawaited(refresh()),
    );
  }

  @override
  void dispose() {
    _foregroundTimer?.cancel();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
```

Add `dart:async`, `dart:math`, `package:flutter/foundation.dart`, `package:flutter/widgets.dart`, endpoint/client/channel/model imports, and the two gateway model/cache imports. The implementation must:

- keep `_configsById` private;
- load cached contacts before network in `start()`;
- project one contact per profile or one fallback contact;
- use `DateTime.tryParse(session.lastActive)` to choose latest session;
- retain old contacts for a failed gateway with `offline` status;
- replace only the successful gateway's old rows;
- save the merged non-secret list after refresh;
- use three async workers over a shared integer index;
- expose an immutable sorted `List<GatewayContact> get contacts`;
- use a monotonically increasing `_refreshGeneration` and ignore stale completions;
- classify errors containing `HTTP 401` or `HTTP 403` as `authenticationFailed`, all other request failures as `offline`, and never copy the raw error into contact state;
- project one non-secret `GatewayOverview` per saved config and update its availability alongside that gateway's contacts;
- mark existing rows and overview for a gateway `refreshing` before its request starts;
- register itself once with `WidgetsBinding.instance.addObserver(this)` in `start()`, start the timer only while lifecycle state is resumed, stop it for every other lifecycle state, and remove the observer in `dispose()`.

Use this worker shape:

```dart
var nextIndex = 0;
Future<void> worker() async {
  while (nextIndex < configs.length) {
    final index = nextIndex++;
    await _refreshGateway(configs[index], generation);
  }
}
await Future.wait(
  List.generate(min(maxConcurrent, configs.length), (_) => worker()),
);
```

Use `Timer.periodic(const Duration(seconds: 60), (_) => unawaited(refresh()))` in a private `_startForegroundRefresh()` that returns early when `_foregroundTimer != null`. `didChangeAppLifecycleState(resumed)` starts the timer and calls `unawaited(refresh())`; all other states cancel and clear it. `dispose()` cancels the timer and removes the observer.

- [ ] **Step 5: Run directory tests and verify GREEN**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart
```

Expected: merge, fallback, partial failure, stale generation, secret absence, and max-concurrency tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/hermes_chat/gateways/hermes_gateway_directory.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/support/fake_hermes_gateway_directory.dart
git commit -m "feat(chat): refresh multiple gateway summaries"
```

---

### Task 4: Activate Exactly One Gateway Contact

**Files:**
- Modify: `lib/features/hermes_chat/gateways/hermes_gateway_directory.dart`
- Modify: `lib/features/hermes_chat/providers/hermes_channel_provider.dart`
- Modify: `test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart`
- Modify: `test/features/hermes_chat/providers/hermes_channel_provider_test.dart`

**Interfaces:**
- Produces: `GatewayContactId? get activeContactId`, `GatewayContact? get activeContact`, `Future<void> activate(GatewayContactId id)`, `Future<void> showDirectory()`.
- Keeps: `hermesChannelProvider` as the only full channel.
- Removes: `hermesAutoConnect`; launch starts at the unified directory instead of connecting the first endpoint.

- [ ] **Step 1: Write failing activation tests**

```dart
test('activate connects correct gateway, profile, and latest session', () async {
  final channel = FakeHermesChannel.disconnected();
  final directory = seededDirectory(activeChannel: channel);
  await directory.refresh();

  await directory.activate(
    const GatewayContactId(gatewayId: 'beta', profileId: 'agent-2'),
  );

  expect(channel.connectCalls.single.baseUrl, 'https://beta.example');
  expect(channel.connectCalls.single.apiKey, 'beta-secret');
  expect(channel.selectProfileCalls, ['agent-2']);
  expect(channel.selectSessionCalls, ['beta-latest']);
  expect(directory.activeContactId,
      const GatewayContactId(gatewayId: 'beta', profileId: 'agent-2'));
});

test('fallback contact skips profile selection', () async {
  await directory.activate(
    const GatewayContactId(gatewayId: 'legacy', profileId: 'default'),
  );
  expect(channel.selectProfileCalls, isEmpty);
});

test('second activation disconnects previous channel first', () async {
  await directory.activate(contactA);
  await directory.activate(contactB);
  expect(channel.disconnectCalls, 1);
  expect(channel.connectCalls, hasLength(2));
});
```

Add `disconnectCalls` to `FakeHermesChannel` and increment it in `disconnect()`.

- [ ] **Step 2: Run tests and verify RED**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/providers/hermes_channel_provider_test.dart
```

Expected: activation methods are missing and provider test still expects auto-connect.

- [ ] **Step 3: Implement activation**

In `activate()`:

```dart
Future<void> activate(GatewayContactId id) async {
  final contact = _contacts.firstWhere((item) => item.id == id);
  final config = _configsById[id.gatewayId];
  if (config == null) throw StateError('Gateway is no longer saved.');
  final generation = ++_activationGeneration;

  if (_activeContactId != null) await _activeChannel.disconnect();
  if (generation != _activationGeneration) return;
  await _activeChannel.connect(baseUrl: config.baseUrl, apiKey: config.apiKey);
  if (generation != _activationGeneration || !_activeChannel.state.isConnected) return;
  if (!contact.isFallbackProfile) {
    await _activeChannel.selectProfile(contact.id.profileId);
  }
  if (generation != _activationGeneration) return;
  final latestId = contact.latestSession?.id;
  if (latestId != null &&
      _activeChannel.state.sessions.any((session) => session.id == latestId)) {
    await _activeChannel.selectSession(latestId);
  }
  if (generation != _activationGeneration) return;
  _activeContactId = id;
  notifyListeners();
}

Future<void> showDirectory() async {
  ++_activationGeneration;
  await _activeChannel.disconnect();
  _activeContactId = null;
  notifyListeners();
}
```

Do not expose `config` or its key from the directory.

- [ ] **Step 4: Replace provider wiring**

In `hermes_channel_provider.dart`:

```dart
final hermesChannelProvider = Provider<HermesChannel>((ref) {
  final channel = HermesApiChannel();
  ref.onDispose(channel.dispose);
  return channel;
});

final hermesGatewayDirectoryProvider =
    ChangeNotifierProvider<HermesGatewayDirectory>((ref) {
  final directory = HermesGatewayDirectory(
    store: ref.watch(hermesEndpointStoreProvider),
    cache: GatewayContactCache(),
    loader: const HermesApiGatewaySummaryLoader(),
    activeChannel: ref.watch(hermesChannelProvider),
  );
  unawaited(directory.start());
  return directory; // ChangeNotifierProvider owns directory.dispose().
});
```

Import `package:flutter_riverpod/legacy.dart` for `ChangeNotifierProvider`.

- [ ] **Step 5: Update provider tests**

Delete auto-connect expectations. Assert that constructing `hermesChannelProvider` leaves the channel disconnected and that starting the directory loads all profiles without calling `channel.connect()`.

- [ ] **Step 6: Run focused tests and verify GREEN**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/providers/hermes_channel_provider_test.dart
```

Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/hermes_chat/gateways/hermes_gateway_directory.dart lib/features/hermes_chat/providers/hermes_channel_provider.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/providers/hermes_channel_provider_test.dart test/features/hermes_chat/support/fake_hermes_channel.dart
git commit -m "feat(chat): activate one gateway contact at a time"
```

---

### Task 5: Render the Unified Telegram-Style Contact List

**Files:**
- Create: `lib/features/hermes_chat/gateways/gateway_contacts_view.dart`
- Create: `test/features/hermes_chat/gateways/gateway_contacts_view_test.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_layout.dart`

**Interfaces:**
- Produces: `GatewayContactsView({required contacts, required refreshing, required onRefresh, required onOpen, onConnect})`.
- Consumes: `hermesGatewayDirectoryProvider`, `GatewayContactId`, `HermesGatewayDirectory.activate()`.

- [ ] **Step 1: Write the failing five-contact widget test**

```dart
testWidgets('renders five contacts ordered across two gateways', (tester) async {
  final contacts = [
    contact('a', 'a1', 'Agent A1', 'Alpha', '2026-07-16T05:00:00Z'),
    contact('a', 'a2', 'Agent A2', 'Alpha', '2026-07-16T04:00:00Z'),
    contact('a', 'a3', 'Agent A3', 'Alpha', '2026-07-16T03:00:00Z'),
    contact('b', 'b1', 'Agent B1', 'Beta', '2026-07-16T02:00:00Z'),
    contact('b', 'b2', 'Agent B2', 'Beta', '2026-07-16T01:00:00Z'),
  ];
  GatewayContactId? opened;

  await tester.pumpWidget(MaterialApp(
    home: GatewayContactsView(
      contacts: contacts,
      refreshing: false,
      onRefresh: () async {},
      onOpen: (id) => opened = id,
    ),
  ));

  expect(find.byKey(const ValueKey('gateway-contact-row')), findsNWidgets(5));
  expect(find.text('Alpha'), findsNWidgets(3));
  expect(find.text('Beta'), findsNWidgets(2));
  await tester.tap(find.text('Agent B2'));
  expect(opened, const GatewayContactId(gatewayId: 'b', profileId: 'b2'));
});
```

Add a second test asserting an offline row remains visible and has semantics label containing `offline`.

- [ ] **Step 2: Run widget test and verify RED**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/gateway_contacts_view_test.dart
```

Expected: compilation fails because `GatewayContactsView` does not exist.

- [ ] **Step 3: Implement the list widget**

Build a `RefreshIndicator` + `ListView.separated`. Each row must use:

- `CircleAvatar` with the first profile-name grapheme fallback `?`;
- profile name as title;
- gateway label plus status as subtitle;
- latest preview (bounded to one line) and formatted timestamp;
- muted offline icon/text, progress indicator for refreshing, green dot for online;
- `ValueKey('gateway-contact-${gatewayId}-${profileId}')` on each `ListTile`;
- `Semantics(label: '$profileName, $gatewayLabel, ${availability.name}')`.

Declare `onRefresh` as `Future<void> Function()`, `onOpen` as `ValueChanged<GatewayContactId>`, and optional `onConnect` as `VoidCallback?`. The empty state must show `No Hermes gateways yet` and a `Connect gateway` action only when `onConnect != null`; it must not fabricate contacts.

- [ ] **Step 4: Route `HermesChatScreen` between list, chat, and first-connect form**

In `build()`:

```dart
final directory = ref.watch(hermesGatewayDirectoryProvider);
final channel = ref.watch(hermesChannelProvider);
final state = channel.state;
final hasGateways = directory.contacts.isNotEmpty || directory.hasSavedGateways;
final showingDirectory = directory.activeContactId == null;

final body = !hasGateways
    ? _buildConnectForm(context, channel, state)
    : showingDirectory
        ? GatewayContactsView(
            contacts: directory.contacts,
            refreshing: directory.refreshing,
            onRefresh: directory.refresh,
            onOpen: (id) => unawaited(_openGatewayContact(id)),
          )
        : state.isConnected
            ? _buildChat(context, channel, state)
            : const Center(child: CircularProgressIndicator());
```

Use a plain `Hermes` app-bar title for the directory; active-chat header changes in Task 6.

- [ ] **Step 5: Run focused widget tests and verify GREEN**

```bash
flutter test --concurrency=1 test/features/hermes_chat/gateways/gateway_contacts_view_test.dart test/features/hermes_chat/screens/hermes_chat_screen_android_endpoint_test.dart
```

Expected: all pass, including the existing first-connect form.

- [ ] **Step 6: Commit**

```bash
git add lib/features/hermes_chat/gateways/gateway_contacts_view.dart lib/features/hermes_chat/screens/hermes_chat_screen.dart lib/features/hermes_chat/screens/state/hermes_chat_layout.dart test/features/hermes_chat/gateways/gateway_contacts_view_test.dart test/features/hermes_chat/screens/hermes_chat_screen_android_endpoint_test.dart
git commit -m "feat(chat): show unified gateway contacts"
```

---

### Task 6: Add Gateway-Aware Chat Header, Session History, and Safe Switching

**Files:**
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart`
- Modify: `lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart`
- Create: `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`

**Interfaces:**
- Produces: `_openGatewayContact(GatewayContactId)`, `_confirmGatewaySwitch()`, gateway-aware app-bar title/leading action.
- Consumes: existing `_isTurnActive`, `_pendingApprovals`, `_answeringApprovalId`, `_showSessionsPanel`.

- [ ] **Step 1: Write failing switch/header tests**

Use the shared fakes from Task 3 and this complete harness/cases:

```dart
Future<({
  HermesGatewayDirectory directory,
  FakeHermesChannel channel,
  FakeHermesEndpointStore store,
})> pumpGatewayChat(WidgetTester tester) async {
  final channel = FakeHermesChannel.disconnected();
  final store = FakeHermesEndpointStore(profiles: const [
    HermesEndpointConfig(id: 'a', label: 'Alpha', baseUrl: 'https://a', apiKey: 'a-secret'),
    HermesEndpointConfig(id: 'b', label: 'Beta', baseUrl: 'https://b', apiKey: 'b-secret'),
  ]);
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: FakeGatewaySummaryLoader({
      'a': gatewaySummary(['agent-a']),
      'b': gatewaySummary(['agent-b']),
    }),
    activeChannel: channel,
  );
  await directory.refresh();
  await directory.activate(
    const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'),
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [
      hermesChannelProvider.overrideWithValue(channel),
      hermesEndpointStoreProvider.overrideWithValue(store),
      hermesGatewayDirectoryProvider.overrideWith((ref) => directory),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HermesChatScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return (directory: directory, channel: channel, store: store);
}

testWidgets('active header shows agent and gateway and opens sessions', (tester) async {
  await pumpGatewayChat(tester);
  expect(find.text('AGENT-A'), findsOneWidget);
  expect(find.text('Alpha'), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('hermes-contact-header')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('hermes-sessions-panel')), findsOneWidget);
});

testWidgets('back returns to contacts without deleting gateway', (tester) async {
  final harness = await pumpGatewayChat(tester);
  await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
  await tester.pumpAndSettle();
  expect(harness.directory.activeContactId, isNull);
  expect(harness.store.deleteProfileCalls, isEmpty);
  expect(find.text('AGENT-A'), findsOneWidget);
  expect(find.text('AGENT-B'), findsOneWidget);
});

testWidgets('active run requires confirmation before leaving contact', (tester) async {
  final harness = await pumpGatewayChat(tester);
  harness.channel.beginStreamingTurn('work');
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('hermes-back-to-contacts')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('hermes-gateway-switch-confirm-dialog')),
      findsOneWidget);
  await tester.tap(find.text('Stay'));
  await tester.pumpAndSettle();
  expect(harness.directory.activeContactId,
      const GatewayContactId(gatewayId: 'a', profileId: 'agent-a'));
});
```

- [ ] **Step 2: Run tests and verify RED**

```bash
flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
```

Expected: header keys and switch guard do not exist.

- [ ] **Step 3: Implement the switch guard**

```dart
bool _hasActiveGatewayWork(HermesChannel channel) =>
    _isTurnActive(channel.state) ||
    _pendingApprovals.isNotEmpty ||
    _answeringApprovalId != null ||
    _queuedFollowUps.isNotEmpty;

Future<bool> _confirmLeaveActiveContact(HermesChannel channel) async {
  if (!_hasActiveGatewayWork(channel)) return true;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          key: const ValueKey('hermes-gateway-switch-confirm-dialog'),
          title: const Text('Switch chats?'),
          content: const Text(
            'This chat has active work or an approval. Switching closes its live stream; Hermes remains authoritative and will reconcile it when reopened.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Switch'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> _showGatewayContacts() async {
  final channel = ref.read(hermesChannelProvider);
  if (!await _confirmLeaveActiveContact(channel) || !mounted) return;
  _voiceInputController.pause('Closed Hermes contact.');
  _queuedFollowUps.clear();
  _pendingApprovals.clear();
  await ref.read(hermesGatewayDirectoryProvider).showDirectory();
}

Future<void> _openGatewayContact(GatewayContactId id) async {
  final channel = ref.read(hermesChannelProvider);
  final directory = ref.read(hermesGatewayDirectoryProvider);
  if (directory.activeContactId != null &&
      directory.activeContactId != id &&
      !await _confirmLeaveActiveContact(channel)) {
    return;
  }
  _voiceInputController.pause('Switched Hermes contact.');
  _queuedFollowUps.clear();
  _pendingApprovals.clear();
  await directory.activate(id);
}
```

- [ ] **Step 4: Implement active header and back behavior**

When active, render:

- leading `IconButton(key: ValueKey('hermes-back-to-contacts'))` calling `_showGatewayContacts()`;
- wrap the active-chat scaffold in `PopScope(canPop: false, onPopInvokedWithResult: (didPop, _) { if (!didPop) unawaited(_showGatewayContacts()); })` so Android system Back applies the same guard instead of exiting;
- title `TextButton(key: ValueKey('hermes-contact-header'))` showing profile name and gateway label in a two-line bounded column;
- header tap calling existing `_showSessionsPanel(context, channel)`;
- keep the explicit sessions icon for accessibility/desktop discoverability;
- remove the old profile switcher from the active app bar because profiles now live in the unified contact list.

Use existing session panel selection; it already calls `channel.selectSession` and therefore switches history only inside the active gateway/profile.

- [ ] **Step 5: Run screen tests and verify GREEN**

```bash
flutter test --concurrency=1 test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart test/features/hermes_chat/screens/hermes_chat_rich_transcript_test.dart
```

Expected: new gateway tests pass. Update old profile-switch expectations to assert contacts replace the profile-switcher only when the directory is active; agent administration tests remain unchanged.

- [ ] **Step 6: Commit**

```bash
git add lib/features/hermes_chat/screens/hermes_chat_screen.dart lib/features/hermes_chat/screens/state/hermes_chat_lifecycle.dart lib/features/hermes_chat/screens/widgets/hermes_chat_sessions.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_profile_switch_test.dart
git commit -m "feat(chat): switch gateway contacts safely"
```

---

### Task 7: Integrate Enrollment, Refresh Lifecycle, and Gateway Removal

**Files:**
- Modify: `lib/features/enrollment/providers/hermes_enrollment_provider.dart`
- Modify: `lib/features/hermes_chat/screens/hermes_chat_screen.dart`
- Modify: `lib/features/hermes_chat/screens/state/hermes_chat_connection.dart`
- Modify: `test/features/enrollment/hermes_enrollment_flow_test.dart`
- Modify: `test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart`
- Modify: `test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart`
- Modify: `lib/features/settings/screens/settings_screen.dart`
- Modify: `test/features/settings/settings_screen_test.dart`

**Interfaces:**
- Produces: `HermesGatewayDirectory.reload({GatewayContactId? activate})`, `renameGateway(String gatewayId, String? label)`, `reconnectGateway(String gatewayId)`, `removeGateway(String gatewayId)`.
- Enrollment success calls directory reload after secure save; it does not call removed `hermesAutoConnect`.

- [ ] **Step 1: Write failing enrollment-append and removal tests**

```dart
test('successful QR enrollment reloads without deleting gateways', () async {
  var reloadCalls = 0;
  final store = FakeHermesEndpointStore(
    initial: const HermesEndpointConfig(
      id: 'a', label: 'Alpha', baseUrl: 'https://a', apiKey: 'a-secret',
    ),
  );
  final controller = HermesEnrollmentController(
    inspectEnrollment: ({required origin, required code}) async =>
        const HermesEnrollmentPreview(
          label: 'Beta', origin: 'https://b', scopes: ['*'],
        ),
    exchangeEnrollment: ({required origin, required code}) async =>
        const HermesIssuedOperatorToken(token: 'b-secret'),
    endpointStore: store,
    connectSavedEndpoint: () async => reloadCalls++,
  );
  addTearDown(controller.dispose);

  await controller.inspect(HermesEnrollmentPayload.parse(
    'wing://connect?origin=https%3A%2F%2Fb&code=one-time',
  ));
  await controller.confirm();

  expect(await store.loadProfiles(), hasLength(2));
  expect(reloadCalls, 1);
  expect(store.deleteProfileCalls, isEmpty);
});

test('rename and reconnect update one gateway only', () async {
  final store = FakeHermesEndpointStore(profiles: const [
    HermesEndpointConfig(id: 'a', label: 'Alpha', baseUrl: 'https://a'),
    HermesEndpointConfig(id: 'b', label: 'Beta', baseUrl: 'https://b'),
  ]);
  final loader = FakeGatewaySummaryLoader({
    'a': gatewaySummary(['a1']),
    'b': gatewaySummary(['b1']),
  });
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: loader,
    activeChannel: FakeHermesChannel.disconnected(),
  );
  await directory.refresh();

  await directory.renameGateway('a', 'Work');
  await directory.reconnectGateway('a');

  expect(store.saveCalls.single.id, 'a');
  expect(store.saveCalls.single.label, 'Work');
  expect(loader.calls.where((id) => id == 'a'), hasLength(2));
  expect(loader.calls.where((id) => id == 'b'), hasLength(1));
});

test('remove gateway clears only its contacts and credential', () async {
  final store = FakeHermesEndpointStore(profiles: const [
    HermesEndpointConfig(id: 'a', label: 'Alpha', baseUrl: 'https://a'),
    HermesEndpointConfig(id: 'b', label: 'Beta', baseUrl: 'https://b'),
  ]);
  final directory = HermesGatewayDirectory(
    store: store,
    cache: FakeGatewayContactCache(),
    loader: FakeGatewaySummaryLoader({
      'a': gatewaySummary(['a1']),
      'b': gatewaySummary(['b1']),
    }),
    activeChannel: FakeHermesChannel.disconnected(),
  );
  await directory.refresh();

  await directory.removeGateway('a');

  expect(store.deleteProfileCalls, ['a']);
  expect(directory.contacts.every((c) => c.id.gatewayId != 'a'), isTrue);
  expect(directory.contacts.any((c) => c.id.gatewayId == 'b'), isTrue);
});
```

Add a screen test: removing the active gateway shows confirmation, returns to contacts, and preserves another gateway row.

- [ ] **Step 2: Run tests and verify RED**

```bash
flutter test --concurrency=1 test/features/enrollment/hermes_enrollment_flow_test.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
```

Expected: reload/rename/reconnect/remove methods are absent and enrollment still invokes old auto-connect wiring.

- [ ] **Step 3: Implement reload and gateway management**

```dart
Future<void> reload({GatewayContactId? activate}) async {
  await refresh();
  if (activate != null && _contacts.any((c) => c.id == activate)) {
    await this.activate(activate);
  }
}

Future<void> renameGateway(String gatewayId, String? label) async {
  final config = _configsById[gatewayId];
  if (config == null) throw StateError('Gateway is no longer saved.');
  final normalizedLabel = label?.trim().isEmpty ?? true ? null : label!.trim();
  await _store.save(
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
    label: normalizedLabel,
    profileId: gatewayId,
  );
  final displayLabel = normalizedLabel ?? config.baseUrl;
  _configsById[gatewayId] = HermesEndpointConfig(
    id: gatewayId,
    label: normalizedLabel,
    baseUrl: config.baseUrl,
    apiKey: config.apiKey,
  );
  _contacts = sortGatewayContacts([
    for (final contact in _contacts)
      contact.id.gatewayId == gatewayId
          ? contact.copyWith(gatewayLabel: displayLabel)
          : contact,
  ]);
  _gateways = [
    for (final gateway in _gateways)
      gateway.id == gatewayId
          ? GatewayOverview(
              id: gateway.id,
              label: displayLabel,
              baseUrl: gateway.baseUrl,
              availability: gateway.availability,
              lastRefreshedAt: gateway.lastRefreshedAt,
            )
          : gateway,
  ];
  notifyListeners();
}

Future<void> reconnectGateway(String gatewayId) async {
  final config = _configsById[gatewayId];
  if (config == null) throw StateError('Gateway is no longer saved.');
  await _refreshGateway(config, ++_refreshGeneration);
  await _cache.save(_contacts);
}

Future<void> removeGateway(String gatewayId) async {
  if (_activeContactId?.gatewayId == gatewayId) await showDirectory();
  await _store.deleteProfile(gatewayId);
  await _cache.removeGateway(gatewayId);
  _configsById.remove(gatewayId);
  _contacts = sortGatewayContacts(
    _contacts.where((contact) => contact.id.gatewayId != gatewayId),
  );
  notifyListeners();
}
```

Keep the store/cache fields private; expose no credential.

- [ ] **Step 4: Rewire enrollment success**

In `hermesEnrollmentControllerProvider`, replace `connectSavedEndpoint: () => hermesAutoConnect(channel, store)` with a callback that calls `ref.read(hermesGatewayDirectoryProvider).reload()` after the token is securely saved. The enrollment controller continues to own the secure save-before-callback order.

- [ ] **Step 5: Verify directory-owned lifecycle refresh**

In the directory test, call `start()` twice, send resumed twice through `didChangeAppLifecycleState`, and advance fake time by 60 seconds. Assert only one periodic refresh fires. Send paused, advance another 60 seconds, and assert no refresh. The chat screen retains its existing active-channel resume reconciliation and voice pause behavior; it does not own the directory timer.

- [ ] **Step 6: Route existing disconnect/delete actions through gateway removal**

The active disconnect dialog must name the gateway and state that other gateways remain. Confirmation calls `directory.removeGateway(activeContact.id.gatewayId)` rather than `HermesEndpointStore.clear()`. Endpoint-chip deletion on the first-connect form also calls directory reload after store deletion.

- [ ] **Step 7: Replace the single endpoint Settings tile with gateway management**

Watch `hermesGatewayDirectoryProvider` instead of `_savedHermesEndpointProvider`. In the Connection card, render one `ListTile` per `GatewayOverview` with label, public base URL, availability, and a popup menu containing `Rename`, `Reconnect`, and `Remove`. Rename prompts for a local label and calls `renameGateway`; reconnect calls `reconnectGateway`; remove requires confirmation and calls `removeGateway`. Never read or render `HermesEndpointConfig.apiKey` in Settings. Keep the existing `Open Hermes` button.

Update `settings_screen_test.dart` with a two-gateway directory override and assert both labels render, renaming A leaves B unchanged, reconnect calls only A, removal requires confirmation, and no sentinel API key appears in any `Text` widget.

- [ ] **Step 8: Run focused integration tests and verify GREEN**

```bash
flutter test --concurrency=1 test/features/enrollment/hermes_enrollment_flow_test.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/settings/settings_screen_test.dart
```

Expected: all pass; enrollment appends, lifecycle has one timer, and removal is gateway-scoped.

- [ ] **Step 9: Commit**

```bash
git add lib/features/enrollment/providers/hermes_enrollment_provider.dart lib/features/hermes_chat/gateways/hermes_gateway_directory.dart lib/features/hermes_chat/screens/hermes_chat_screen.dart lib/features/hermes_chat/screens/state/hermes_chat_connection.dart lib/features/settings/screens/settings_screen.dart test/features/enrollment/hermes_enrollment_flow_test.dart test/features/hermes_chat/gateways/hermes_gateway_directory_test.dart test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart test/features/hermes_chat/screens/hermes_chat_screen_auth_recovery_test.dart test/features/settings/settings_screen_test.dart
git commit -m "feat(chat): integrate multi-gateway lifecycle"
```

---

### Task 8: Full Validation, Documentation, and Android Receipt

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/runbooks/hermes-readiness-audit.md`
- Test: all files changed in Tasks 1–7

**Interfaces:**
- Produces: user-facing documentation and reproducible validation receipts.
- Does not change runtime behavior.

- [ ] **Step 1: Update user documentation with exact behavior**

Add a concise README section stating:

```markdown
### Multiple Hermes gateways

Hermes Wing treats each saved Hermes Agent endpoint as a gateway and shows its Hermes profiles in one activity-ordered contact list. Only the open contact owns the full streaming channel; inactive gateways refresh health and session summaries over lightweight requests. Opening a contact activates that endpoint, Hermes profile, and its latest session; older sessions remain available from the chat header. Offline gateways remain visible from cached non-secret summaries.
```

Add a changelog bullet and update the readiness-audit multi-endpoint row from “selectable endpoint chips” to unified contacts across saved Hermes endpoints and profiles with one active streaming channel.

- [ ] **Step 2: Run formatting and static analysis**

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
```

Expected: zero formatting changes and `No issues found!`.

- [ ] **Step 3: Run focused multi-gateway suites**

```bash
flutter test --concurrency=1 \
  test/core/hermes/channel/hermes_api_channel_test.dart \
  test/features/enrollment/hermes_enrollment_flow_test.dart \
  test/features/hermes_chat/gateways \
  test/features/hermes_chat/providers/hermes_channel_provider_test.dart \
  test/features/hermes_chat/screens/hermes_chat_gateway_switch_test.dart
```

Expected: all pass.

- [ ] **Step 4: Run the full Flutter suite**

```bash
flutter test --coverage --concurrency=1
coverage_percent=$(awk -F'[:,]' '/^DA:/{total++; if ($3 > 0) covered++} END {printf "%.0f", total ? covered * 100 / total : 0}' coverage/lcov.info)
echo "Line coverage: ${coverage_percent}%"
test "$coverage_percent" -ge 50
```

Expected: all tests pass and coverage is at least 50%.

- [ ] **Step 5: Build and install Android debug APK**

```bash
flutter build apk --debug
adb devices -l
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Expected: APK build succeeds and `adb install` prints `Success` for the selected physical device.

- [ ] **Step 6: Record a manual two-gateway receipt**

Using two non-production Hermes fixtures or trusted test gateways:

1. enroll gateway A with three profiles;
2. enroll gateway B with two profiles;
3. verify five rows appear in descending activity order;
4. open one contact from each gateway and verify only the active chat streams;
5. stop gateway A and verify its three contacts remain offline while gateway B still opens;
6. reopen an older session from the active chat header;
7. inspect diagnostics and screenshots for absence of access tokens.

Record only gateway labels, profile counts, statuses, commit SHA, and pass/fail. Never record endpoint credentials, raw authorization headers, private transcript text, or pairing codes.

- [ ] **Step 7: Run diff hygiene**

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; only intended documentation/receipt paths remain.

- [ ] **Step 8: Commit documentation**

```bash
git add README.md CHANGELOG.md docs/runbooks/hermes-readiness-audit.md
git commit -m "docs: explain multi-gateway unified chats"
```
