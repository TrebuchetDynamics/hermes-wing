# Navivox Route Design

Status: planning draft
Source: derived from navivox-prd.md and the current Flutter router

## 1. Route Architecture

GoRouter uses Riverpod state to decide whether the app should show setup or the
main shell. A configured gateway connection is enough to enter the product; the
first useful screen is chat.

### 1.1 Current Route Constants

```dart
abstract final class AppRoutes {
  static const setup = '/setup';
  static const chats = '/chats';
  static const chatThread = '/chats/:serverId/:threadId';
  static const servers = '/servers';
  static const serverDetail = '/servers/:id';
  static const agents = '/agents';
  static const agentEditor = '/agents/:id/edit';
  static const agentCreate = '/agents/create';
  static const config = '/config';
  static const configSection = '/config/:section';
  static const secretEditor = '/config/secrets/:key';
  static const terminal = '/terminal';
  static const terminalSession = '/terminal/:serverId';
  static const settings = '/settings';
}
```

Only setup, chats, servers, agents, and config are currently mounted in the
router. Detail routes, terminal, and settings constants remain future surfaces
until their screens have current gateway-backed behavior.

## 2. Current Route Table

### 2.1 Setup

| Path | Screen | Guard | Notes |
|------|--------|-------|-------|
| `/setup` | `SetupScreen` | None | Paste or scan `gormes navivox connect-info` output, enter token when required, probe `/healthz`, and connect to the stream. |

The setup screen should prefer a single "connect and talk now" path. Advanced
server inventory, imports, and terminal workflows are not part of the first
activation loop.

### 2.2 Main Shell

The shell route wraps the primary authenticated surfaces with app navigation.

| Tab | Path | Screen | Guard |
|-----|------|--------|-------|
| Chats | `/chats` | `ChatScreen` | Connected gateway |
| Servers | `/servers` | `ServersScreen` | Connected gateway |
| Agents | `/agents` | `AgentsScreen` | Connected gateway |
| Config | `/config` | `ConfigScreen` | Connected gateway; mutation controls require server role evidence |

### 2.3 Planned Detail Routes

| Path | Screen | Guard | Notes |
|------|--------|-------|-------|
| `/chats/:serverId/:threadId` | `ChatScreen` with session context | Connected gateway | Open an existing Navivox session from the local cache or server session list. |
| `/servers/:id` | `ServerDetailScreen` | Connected gateway | Show base URL, health, exposure mode, auth mode, and redacted token status. |
| `/agents/:id/edit` | `AgentEditorScreen` | Admin role | Edit generated agent/profile/tool/voice settings after a seed flow. |
| `/agents/create` | `AgentCreateScreen` | Admin role | Natural-language seed such as "screen inbound leads". |
| `/config/:section` | `ConfigSectionScreen` | Admin role | Schema-driven section editor. |
| `/config/secrets/:key` | `SecretEditorScreen` | Admin role + local unlock | Set, rotate, delete, and test a secret without reading its value. |
| `/settings` | `SettingsScreen` | Local app | Theme, local voice defaults, cache controls, and app lock. |
| `/terminal` | Future terminal surface | Explicit opt-in | Deferred; not part of the connect-and-talk loop. |

## 3. Router Configuration

The current provider redirects to setup until a gateway-backed server is present
in channel state.

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final channel = ref.watch(navivoxChannelProvider);

  return GoRouter(
    initialLocation: AppRoutes.chats,
    refreshListenable: channel,
    redirect: (context, state) {
      final hasServers = channel.state.servers.isNotEmpty;
      final isSetup = state.matchedLocation.startsWith(AppRoutes.setup);

      if (!hasServers && !isSetup) return AppRoutes.setup;
      if (hasServers && isSetup) return AppRoutes.chats;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AppRoutes.chats, builder: (_, __) => const ChatScreen()),
          GoRoute(path: AppRoutes.servers, builder: (_, __) => const ServersScreen()),
          GoRoute(path: AppRoutes.agents, builder: (_, __) => const AgentsScreen()),
          GoRoute(path: AppRoutes.config, builder: (_, __) => const ConfigScreen()),
        ],
      ),
    ],
  );
});
```

## 4. Route Guards

### 4.1 Connection Guard

```dart
final hasGatewayProvider = Provider<bool>((ref) {
  final channel = ref.watch(navivoxChannelProvider);
  return channel.state.servers.isNotEmpty;
});
```

Setup owns connection creation. The shell assumes a gateway exists and renders
connection loss as recoverable UI, not a route crash.

### 4.2 Role Guards

Role evidence comes from the server. Until the gateway exposes role metadata,
mutation actions are disabled or shown as "not available yet".

```dart
final canMutateConfigProvider = Provider<bool>((ref) {
  final role = ref.watch(activeServerRoleProvider);
  return role == NavivoxRole.owner || role == NavivoxRole.admin;
});
```

### 4.3 Inline Widget Guards

Fine-grained controls use inline guards instead of hiding whole screens.

```dart
class ConfigMutationGuard extends ConsumerWidget {
  const ConfigMutationGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(canMutateConfigProvider)) {
      return const ReadOnlyConfigView();
    }
    return child;
  }
}
```

## 5. Navigation Patterns

### 5.1 Setup To Chat

```text
Paste connect-info base URL + token
  -> GET /healthz
  -> GET /v1/navivox/status
  -> WS /v1/navivox/stream
  -> Navigate to /chats
```

### 5.2 Server Switcher

The server switcher changes the active gateway context without leaving chat.
Switching servers reconnects the `GatewayNavivoxChannel` and refreshes status.

### 5.3 Agent Switcher

The agent picker is a sheet/menu from chat. Agent selection updates local UI
state immediately and sends a gateway request once agent selection is exposed by
the channel contract.

### 5.4 Deep Links

Deep links are local app links. They never include tokens.

```text
navivox://chat/<serverId>/<threadId>
navivox://server/<serverId>
navivox://config/<serverId>/<section>
```

## 6. Mobile Navigation Layout

```text
+---------------------+
| App Bar             |  Server name, agent pill, connection status
|                     |
| Content Area        |
| (GoRouter child)    |
|                     |
+---------------------+
| Chats | Srv | Agt   |
| Config              |
+---------------------+
```

## 7. Desktop Navigation Layout

```text
+------+----------------------------------+
|      | Top Bar                          |
| Left | Server: local  Agent: default    |
| Rail +----------------------------------+
|      | Content Area                     |
| Chat | (GoRouter child)                 |
| Srv  |                                  |
| Agt  |                                  |
| Cfg  |                                  |
+------+----------------------------------+
| Status Bar: gateway, version, auth      |
+-----------------------------------------+
```

## 8. First-Run Flow Navigation

The first-run wizard uses internal step state rather than many routes:

```text
Step 1: Paste or scan connect-info
Step 2: Enter token when required
Step 3: Probe health and status
Step 4: Open stream
Step 5: Land in chat with a starter prompt
```

Optional later steps can help create an agent from a short natural-language
seed, but the operator should be able to talk before completing advanced
configuration.

## 9. Route Transition Animations

| Transition | Use Case |
|------------|----------|
| Slide right to left | Push to detail screens |
| Slide left to right | Pop back |
| Fade through | Tab switches in shell |
| Modal bottom sheet | Agent switcher, quick actions |
| Full-screen dialog | Secret editor and destructive confirmations |
