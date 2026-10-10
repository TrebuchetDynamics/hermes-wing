import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/models/hermes_session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../../shared/security/wing_redaction.dart';
import '../gateways/hermes_gateway_directory.dart';
import '../providers/hermes_channel_provider.dart';
import '../providers/hermes_directory_lifetime.dart';
import '../gateways/gateway_contact.dart';
import '../session/hermes_session_pin_store.dart';
import '../screens/hermes_chat_screen.dart' show HermesSessionsPanel;
import 'global_session_scope.dart';

/// A loaded-inventory view, not a directory consumer or a second session owner.
class ShellSessionAccess extends ConsumerStatefulWidget {
  const ShellSessionAccess({this.fullPanel = false, super.key});
  final bool fullPanel;

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
  String? _retrySession;
  bool _retryLoadMore = false;
  bool _retryActivation = false;
  GoRouter? _router;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.fullPanel) return;
    final router = GoRouter.of(context);
    if (identical(router, _router)) return;
    _router?.routeInformationProvider.removeListener(_routeChanged);
    _router = router;
    router.routeInformationProvider.addListener(_routeChanged);
  }

  void _routeChanged() {
    _generation++;
    _error = null;
    _retryActivation = false;
    _retryLoadMore = false;
  }

  bool _scheduled = false;
  final _pins = HermesSessionPinStore();

  GatewayContactId get _pinContact =>
      _directory?.activeContactId ??
      GatewayContactId(
        gatewayId: 'direct',
        profileId: _channel.state.selectedProfileId ?? 'default',
      );

  bool get _canList {
    final caps = _channel.state.capabilities;
    if (caps == null) return true;
    final endpoint = caps.endpoints['sessions'];
    return caps.supportsSchema &&
        caps.advertisesEndpoint('sessions', 'GET', '/api/sessions') &&
        endpoint != null &&
        (!endpoint.profileScoped ||
            caps.profileContext.isSupportedQueryContext) &&
        endpoint.requiredScopes.every(caps.auth.allows);
  }

  @override
  void initState() {
    super.initState();
    if (widget.fullPanel) {
      _pins.addListener(_changed);
      unawaited(_pins.load());
    }
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
    _channel.state.canUpdateSessions,
    _channel.state.canDeleteSessions,
    _channel.state.canForkSessions,
    _channel.state.capabilities,
  );

  bool get _settled =>
      (!widget.fullPanel || ModalRoute.of(context)?.isActive == true) &&
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
      _retrySession = null;
      _retryLoadMore = false;
      _retryActivation = false;
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
    _pins.removeListener(_changed);
    _pins.dispose();
    _router?.routeInformationProvider.removeListener(_routeChanged);
    super.dispose();
  }

  Future<void> _loadMore(int generation) async {
    if (!mounted ||
        generation != _generation ||
        !_settled ||
        !_canList ||
        _pending != null ||
        !_channel.state.hasMoreSessions ||
        _channel.state.isLoadingMoreSessions) {
      return;
    }
    final token = Object();
    setState(() {
      _pending = token;
      _error = null;
    });
    try {
      _retryLoadMore = true;
      _retryActivation = false;
      await _channel.loadMoreSessions();
      if (mounted &&
          generation == _generation &&
          _channel.state.errorMessage != null) {
        setState(
          () => _error = AppLocalizations.of(context).shellSessionFailed,
        );
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = AppLocalizations.of(context).shellSessionFailed,
        );
      }
    } finally {
      if (mounted && identical(_pending, token)) {
        setState(() => _pending = null);
      }
    }
  }

  Future<void> _mutate(
    int generation,
    List<HermesSession> rows,
    String operation,
  ) async {
    bool permitted() => switch (operation) {
      'rename' => _channel.state.canUpdateSessions,
      'fork' => _channel.state.canForkSessions,
      _ => _channel.state.canDeleteSessions,
    };
    final remaining = rows.map((row) => row.id).toSet();
    final modalRoute = widget.fullPanel ? ModalRoute.of(context) : null;
    bool current() =>
        mounted &&
        generation == _generation &&
        _settled &&
        permitted() &&
        (modalRoute == null || modalRoute.isActive) &&
        remaining.every(
          (id) =>
              _channel.state.sessions.any((row) => row.id == id) &&
              (operation == 'rename' || !_channel.state.isSessionStreaming(id)),
        );
    if (_pending != null || remaining.isEmpty || !current()) return;
    _retryActivation = false;
    _retryLoadMore = false;
    final token = Object();
    setState(() {
      _pending = token;
      _error = null;
    });
    final strings = AppLocalizations.of(context);
    try {
      if (operation == 'rename') {
        final original = rows.single.title ?? '';
        final safe = wingRedactedPreview(original, maxLength: 96);
        var draft = safe == original ? original : '';
        final title = await showDialog<String>(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (_, update) => AlertDialog(
              title: Text(strings.chatSessionActionRenameTitle),
              content: TextFormField(
                key: const ValueKey('hermes-session-title-field'),
                autofocus: true,
                initialValue: draft,
                decoration: InputDecoration(
                  labelText: strings.chatSessionActionTitleFieldLabel,
                ),
                onChanged: (value) => update(() => draft = value),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(strings.cancelAction),
                ),
                FilledButton(
                  key: const ValueKey('hermes-session-title-save'),
                  onPressed: draft.trim().isEmpty || draft.trim() == original
                      ? null
                      : () => Navigator.of(dialogContext).pop(draft.trim()),
                  child: Text(strings.saveAction),
                ),
              ],
            ),
          ),
        );
        if (title == null || !current()) return;
        await _channel.renameSession(sessionId: rows.single.id, title: title);
      } else {
        final fork = operation == 'fork';
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              fork
                  ? strings.chatSessionActionBranchTitle
                  : rows.length == 1
                  ? strings.chatSessionActionDeleteTitle
                  : strings.chatSessionActionDeleteManyTitle(rows.length),
            ),
            content: Text(
              fork
                  ? strings.chatSessionActionBranchBody(
                      wingRedactedPreview(
                        rows.single.title ?? rows.single.id,
                        maxLength: 96,
                      ),
                    )
                  : rows.length == 1
                  ? strings.chatSessionActionDeleteBody(
                      wingRedactedPreview(
                        rows.single.title ?? rows.single.id,
                        maxLength: 96,
                      ),
                    )
                  : strings.chatSessionActionDeleteManyBody,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(strings.cancelAction),
              ),
              FilledButton(
                key: ValueKey(
                  fork
                      ? 'hermes-session-branch-confirm'
                      : 'hermes-session-delete-confirm',
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  fork
                      ? strings.chatSessionActionBranchConfirmAction
                      : strings.chatSessionActionDeleteAction,
                ),
              ),
            ],
          ),
        );
        if (confirmed != true || !current()) return;
        for (final row in rows) {
          if (!current()) return;
          remaining.remove(row.id);
          if (fork) {
            await _channel.forkSession(row.id);
          } else {
            // Own submitted deletion is not an external row-loss invalidation.
            _knownIds.remove(row.id);
            await _channel.deleteSession(row.id);
          }
        }
      }
      if (current() && _channel.state.errorMessage != null) {
        setState(() => _error = strings.shellSessionFailed);
      }
    } catch (_) {
      if (current()) setState(() => _error = strings.shellSessionFailed);
    } finally {
      if (mounted && identical(_pending, token)) {
        setState(() => _pending = null);
      }
    }
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
    final navigator = Navigator.of(context);
    final modalRoute = widget.fullPanel ? ModalRoute.of(context) : null;
    final location = router.routeInformationProvider.value.uri;
    var invalidated = false;
    final token = Object();
    final lifetime = _lifetime;
    bool current() =>
        !invalidated &&
        mounted &&
        generation == _generation &&
        identical(channel, _channel) &&
        (modalRoute == null || modalRoute.isActive) &&
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
      _retryLoadMore = false;
      _retrySession = sessionId;
      // A creation failure has no verified replay contract. Only a read of an
      // acknowledged session may be offered as generic recovery.
      _retryActivation = sessionId != null;
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
          : selected != null &&
                !originalIds.contains(selected) &&
                channel.state.sessions.any((s) => s.id == selected);
      if (sessionId == null && acknowledged) {
        _retrySession = selected;
        _retryActivation = true;
      }
      if (!acknowledged || channel.state.errorMessage != null) {
        setState(
          () => _error = AppLocalizations.of(context).shellSessionFailed,
        );
        return;
      }
      if (widget.fullPanel) navigator.pop();
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
    if (widget.fullPanel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pending != null)
            Semantics(
              liveRegion: true,
              child: Text(strings.shellSessionPending),
            ),
          if (_error != null || state.errorMessage != null)
            Semantics(
              liveRegion: true,
              child: Text(strings.shellSessionFailed),
            ),
          if (!_settled) Text(strings.shellUnavailable),
          if (_error != null && enabled && (_retryLoadMore || _retryActivation))
            TextButton(
              key: const ValueKey('global-sessions-retry'),
              onPressed: () => _retryLoadMore
                  ? _loadMore(generation)
                  : _activate(generation, _retrySession),
              child: Text(strings.retryAction),
            ),
          Flexible(
            child: IgnorePointer(
              ignoring: !enabled,
              child: ExcludeFocus(
                excluding: !enabled,
                child: HermesSessionsPanel(
                  state: state,
                  autofocusSearch: true,
                  canLoadMore: _canList,
                  inventoryFailed: _error != null || state.errorMessage != null,
                  canCreate: enabled && state.canCreateSessions,
                  pinnedSessionIds: {
                    for (final row in state.sessions)
                      if (_pins.isPinned(_pinContact, row.id)) row.id,
                  },
                  unreadCompletedSessionIds: const {},
                  onTogglePinned: (row) {
                    if (enabled &&
                        generation == _generation &&
                        state.sessions.any((s) => s.id == row.id)) {
                      unawaited(_pins.toggle(_pinContact, row.id));
                    }
                  },
                  onCreate: () => _activate(generation, null),
                  onSelect: (row) => _activate(generation, row.id),
                  onLoadMore: () => _loadMore(generation),
                  onRename: (row) => _mutate(generation, [row], 'rename'),
                  onFork: (row) => _mutate(generation, [row], 'fork'),
                  onDelete: (row) => _mutate(generation, [row], 'delete'),
                  onDeleteSelected: (rows) =>
                      _mutate(generation, rows, 'delete'),
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Exact source identity is separate from its redacted display label. Dart's
    // insertion-ordered map preserves first encounter and incoming row order.
    final groups = <String?, List<HermesSession>>{};
    for (final session in state.sessions) {
      final source = session.source.trim().isEmpty ? null : session.source;
      (groups[source] ??= []).add(session);
    }
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
            GlobalSessionsButton(enabled: _settled),
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
              for (final group in groups.entries) ...[
                Semantics(
                  header: true,
                  child: Text(
                    strings.shellSessionSource(
                      group.key == null
                          ? strings.sessionUnknownSource
                          : wingRedactedPreview(group.key!, maxLength: 48),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                for (final session in group.value)
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
          ],
        ),
      ),
    );
  }
}
