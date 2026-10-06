import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../shared/security/wing_redaction.dart';
import '../gateways/hermes_gateway_directory.dart';
import '../providers/hermes_channel_provider.dart';
import '../providers/hermes_directory_lifetime.dart';

/// A loaded-inventory view, not a directory consumer or a second session owner.
class ShellSessionAccess extends ConsumerStatefulWidget {
  const ShellSessionAccess({super.key});

  @override
  ConsumerState<ShellSessionAccess> createState() => _ShellSessionAccessState();
}

class _ShellSessionAccessState extends ConsumerState<ShellSessionAccess> {
  late HermesChannel _channel;
  late HermesDirectoryLifetime _lifetime;
  HermesGatewayDirectory? _directory;
  Object? _owner;
  Set<String> _knownIds = {};
  int _generation = 0;
  Object? _pending;
  String? _error;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _channel = ref.read(hermesChannelProvider);
    _channel.addListener(_changed);
    _lifetime = ref.read(hermesDirectoryLifetimeProvider);
    _lifetime.addListener(_directoryChanged);
    _directoryChanged();
    ref.listenManual(hermesChannelProvider, (_, next) {
      if (identical(next, _channel)) return;
      _channel.removeListener(_changed);
      _channel = next;
      _channel.addListener(_changed);
      _changed();
    });
    ref.listenManual(hermesDirectoryLifetimeProvider, (_, next) {
      if (identical(next, _lifetime)) return;
      _lifetime.removeListener(_directoryChanged);
      _lifetime = next;
      _lifetime.addListener(_directoryChanged);
      _directoryChanged();
    });
  }

  Object get _identity => (
    _channel,
    _lifetime,
    _directory,
    _directory?.activeContactId,
    _directory?.isActivating ?? false,
    _directory?.restoringSessionId,
    _channel.state.status,
    _channel.state.connectedBaseUrl,
    _channel.state.selectedProfileId,
    _channel.state.isSelectingProfile,
    _channel.state.hasUnreconciledRun,
    _channel.state.canCreateSessions,
    _channel.state.canReadSessionHistory,
  );

  bool get _settled =>
      _channel.state.isConnected &&
      !_channel.state.isSelectingProfile &&
      !_channel.state.hasUnreconciledRun &&
      _channel.state.canReadSessionHistory &&
      !(_directory?.isActivating ?? false) &&
      _directory?.restoringSessionId == null;

  void _directoryChanged() {
    final next = _lifetime.current;
    if (!identical(next, _directory)) {
      _directory?.removeListener(_changed);
      _directory = next;
      _directory?.addListener(_changed);
    }
    _changed();
  }

  void _changed() {
    final next = _identity;
    final ids = _channel.state.sessions.map((session) => session.id).toSet();
    if (next != _owner || _knownIds.any((id) => !ids.contains(id))) {
      _owner = next;
      _generation++;
      _error = null;
    }
    _knownIds = ids;
    // Directory construction may occur in a descendant's build. Invalidation
    // above is synchronous; only painting is deferred, never action admission.
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(() {
      _scheduled = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _generation++;
    _channel.removeListener(_changed);
    _directory?.removeListener(_changed);
    _lifetime.removeListener(_directoryChanged);
    super.dispose();
  }

  Future<void> _activate(int generation, String? sessionId) async {
    if (!mounted ||
        generation != _generation ||
        !_settled ||
        _pending != null) {
      return;
    }
    final channel = _channel;
    final state = channel.state;
    if (sessionId == null && !state.canCreateSessions) return;
    final originalIds = state.sessions.map((s) => s.id).toSet();
    if (sessionId != null && !originalIds.contains(sessionId)) return;
    final router = GoRouter.of(context);
    final location = router.routeInformationProvider.value.uri;
    var invalidated = false;
    final token = Object();
    final lifetime = _lifetime;
    bool current() =>
        !invalidated &&
        mounted &&
        generation == _generation &&
        identical(channel, _channel) &&
        _settled &&
        (sessionId == null
            ? channel.state.canCreateSessions
            : channel.state.sessions.any((s) => s.id == sessionId));
    void observe() {
      if (!current() || router.routeInformationProvider.value.uri != location) {
        invalidated = true;
      }
    }

    channel.addListener(observe);
    lifetime.addListener(observe);
    final directory = _directory;
    directory?.addListener(observe);
    router.routeInformationProvider.addListener(observe);
    setState(() {
      _pending = token;
      _error = null;
    });
    try {
      if (sessionId == null) {
        await channel.createSession(canAccept: current);
      } else {
        await channel.selectSession(sessionId, canAccept: current);
      }
      observe();
      if (!current()) return;
      final selected = channel.state.activeSessionId;
      final acknowledged = sessionId != null
          ? selected == sessionId
          : selected != null && !originalIds.contains(selected);
      if (!acknowledged || channel.state.errorMessage != null) {
        setState(
          () => _error = AppLocalizations.of(context).shellSessionFailed,
        );
        return;
      }
      router.go(AppRoutes.hermes);
    } catch (_) {
      if (current()) {
        setState(
          () => _error = AppLocalizations.of(context).shellSessionFailed,
        );
      }
    } finally {
      channel.removeListener(observe);
      lifetime.removeListener(observe);
      directory?.removeListener(observe);
      router.routeInformationProvider.removeListener(observe);
      if (mounted && identical(_pending, token)) {
        setState(() => _pending = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = _channel.state;
    final generation = _generation;
    final enabled = _settled && _pending == null;
    return Semantics(
      key: const ValueKey('shell-session-access'),
      container: true,
      explicitChildNodes: true,
      label: strings.shellLoadedSessions,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.shellLoadedSessions,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              strings.shellSessionScope,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            TextButton.icon(
              key: const ValueKey('shell-new-session'),
              onPressed: enabled && state.canCreateSessions
                  ? () => _activate(generation, null)
                  : null,
              icon: const Icon(Icons.add),
              label: Text(strings.shellNewSession),
            ),
            if (_pending != null)
              Semantics(
                liveRegion: true,
                child: Text(strings.shellSessionPending),
              ),
            if (_error != null)
              Semantics(liveRegion: true, child: Text(_error!)),
            if (!_settled)
              Text(strings.shellUnavailable)
            else
              for (final session in state.sessions)
                Builder(
                  builder: (rowContext) => Focus(
                    canRequestFocus: false,
                    skipTraversal: true,
                    onFocusChange: (focused) {
                      if (focused) {
                        Scrollable.ensureVisible(rowContext, alignment: 0.5);
                      }
                    },
                    child: MergeSemantics(
                      child: Semantics(
                        selected: state.activeSessionId == session.id,
                        child: TextButton(
                          key: ValueKey('shell-open-session-${session.id}'),
                          onPressed: enabled
                              ? () => _activate(generation, session.id)
                              : null,
                          child: Text(
                            strings.shellOpenSession(
                              wingRedactedPreview(
                                session.title ?? session.id,
                                maxLength: 80,
                              ),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
