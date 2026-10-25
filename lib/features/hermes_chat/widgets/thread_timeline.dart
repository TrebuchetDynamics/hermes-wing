import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/security/wing_redaction.dart';
import '../presentation/hermes_transcript_viewport.dart';
import '../presentation/hermes_turn_presentation_identity.dart';

/// Derived, process-local labels, never another history inventory.
List<({String id, String preview})> loadedThreadPrompts(
  List<HermesChatTurn> turns,
  String sessionId,
) {
  return [
    for (final turn in _promptTurns(turns, sessionId))
      (id: turn.id, preview: _preview(turn.text)),
  ];
}

Iterable<HermesChatTurn> _promptTurns(
  List<HermesChatTurn> turns,
  String sessionId,
) sync* {
  final unique = HermesTurnPresentationIdentity.uniqueIds(turns);
  final notification = RegExp(r'^\[IMPORTANT: Background process [\s\S]*\]$');
  for (final turn in turns) {
    if (turn.sessionId == sessionId &&
        unique.contains(turn.id) &&
        turn.author == HermesTurnAuthor.user &&
        turn.kind == HermesTurnKind.text &&
        turn.text.trim().isNotEmpty &&
        !notification.hasMatch(turn.text.trim())) {
      yield turn;
    }
  }
}

String _preview(String text) {
  final safe = wingRedactSensitiveText(
    text,
  ).replaceAll(RegExp(r'\s+'), ' ').trim();
  return safe.length <= 120 ? safe : '${safe.substring(0, 119).trimRight()}…';
}

// Avoid redacting every loaded prompt again for pointer paint or assistant
// streaming. Compare canonical inputs without retaining another raw inventory.
bool _samePromptSources(
  List<HermesChatTurn> before,
  List<HermesChatTurn> after,
) {
  if (before.length != after.length) return false;
  for (var i = 0; i < before.length; i++) {
    final a = before[i];
    final b = after[i];
    if (identical(a, b)) continue;
    if (a.id != b.id ||
        a.sessionId != b.sessionId ||
        a.author != b.author ||
        a.kind != b.kind ||
        (a.author == HermesTurnAuthor.user && a.text != b.text)) {
      return false;
    }
  }
  return true;
}

/// Official loaded-only fallback. Tiny wide ticks and a full-size lazy list
/// share targets and exact viewport ownership; neither discovers archive rows.
class HermesThreadTimeline extends StatefulWidget {
  const HermesThreadTimeline({
    super.key,
    required this.turns,
    required this.sessionId,
    required this.viewport,
    required this.hidden,
    required this.onJump,
    required this.onEarlier,
    required this.canShowEarlier,
    required this.loadingEarlier,
    required this.child,
    this.hasHeader = false,
  });

  final List<HermesChatTurn> turns;
  final String sessionId;
  final HermesTranscriptViewportController viewport;
  final bool hidden;
  final ValueChanged<String> onJump;
  final VoidCallback onEarlier;
  final bool canShowEarlier;
  final bool loadingEarlier;
  final Widget child;
  final bool hasHeader;

  @override
  State<HermesThreadTimeline> createState() => _HermesThreadTimelineState();
}

class _HermesThreadTimelineState extends State<HermesThreadTimeline> {
  final _control = FocusNode(debugLabel: 'Conversation timeline');
  final _navigation = FocusNode(debugLabel: 'Timeline prompt navigation');
  final _railFocus = FocusNode(debugLabel: 'Timeline rail');
  final _rail = ScrollController();
  final _prompts = ScrollController();
  late Object _owner;
  bool _open = false;
  bool _hasPrompts = false;
  int _cursor = 0;
  int? _hover;
  int _activeIndex = 0;
  bool _activeFramePending = false;
  int? _lastRailIndex;
  List<({String id, String preview})> _entries = const [];

  @override
  void initState() {
    super.initState();
    _owner = widget.viewport.ownerIdentity;
    _refreshEntries();
  }

  void _refreshEntries() {
    if (widget.hidden) {
      _entries = const [];
      _hasPrompts = _promptTurns(widget.turns, widget.sessionId).isNotEmpty;
    } else {
      _entries = loadedThreadPrompts(widget.turns, widget.sessionId);
      _hasPrompts = _entries.isNotEmpty;
    }
  }

  @override
  void didUpdateWidget(HermesThreadTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hidden != widget.hidden ||
        oldWidget.sessionId != widget.sessionId ||
        !_samePromptSources(oldWidget.turns, widget.turns)) {
      _refreshEntries();
    }
    if (_owner != widget.viewport.ownerIdentity || widget.hidden) {
      _open = false;
      _lastRailIndex = null;
      _cursor = 0;
      _owner = widget.viewport.ownerIdentity;
      // Invalidate synchronously so a queued realization cannot beat hiding.
      widget.viewport.cancelTarget(notify: false);
    }
  }

  @override
  void dispose() {
    _control.dispose();
    _navigation.dispose();
    _railFocus.dispose();
    _rail.dispose();
    _prompts.dispose();
    super.dispose();
  }

  void _close({bool returnFocus = true}) {
    setState(() {
      _open = false;
      _lastRailIndex = null;
    });
    if (returnFocus &&
        !widget.hidden &&
        _owner == widget.viewport.ownerIdentity) {
      _control.requestFocus();
    }
  }

  void _scheduleActivePrompt() {
    if (_activeFramePending) return;
    _activeFramePending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activeFramePending = false;
      if (!mounted ||
          widget.hidden ||
          _entries.isEmpty ||
          _owner != widget.viewport.ownerIdentity) {
        return;
      }
      // During build a retained GlobalKey may still name an inactive lazy row.
      // Read geometry only after the transcript has finished layout/unmounting.
      final id = widget.viewport.activePromptId(
        _entries.map((entry) => entry.id).toSet(),
      );
      final index = widget.viewport.mode == HermesViewportMode.followingLatest
          ? _entries.length - 1
          : _entries
                .indexWhere((entry) => entry.id == id)
                .clamp(0, _entries.length - 1);
      if (index != _activeIndex) setState(() => _activeIndex = index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final available = !widget.hidden && entries.isNotEmpty;
    _cursor = entries.isEmpty ? 0 : _cursor.clamp(0, entries.length - 1);
    final strings = AppLocalizations.of(context);
    final extent = 104 * MediaQuery.textScalerOf(context).scale(14) / 14;

    void activate(int index) {
      if (_owner != widget.viewport.ownerIdentity || widget.hidden) return;
      final id = entries[index].id;
      // The callback revalidates canonical identity, not an old list position.
      widget.onJump(id);
      if (_open) _close();
    }

    KeyEventResult key(KeyEvent event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }
      final next = switch (event.logicalKey) {
        LogicalKeyboardKey.home => 0,
        LogicalKeyboardKey.end => entries.length - 1,
        LogicalKeyboardKey.arrowUp => _cursor - 1,
        LogicalKeyboardKey.arrowDown => _cursor + 1,
        _ => null,
      };
      if (next != null) {
        setState(() => _cursor = next.clamp(0, entries.length - 1));
        // Transfer key ownership away from a previously tabbed prompt button.
        // Otherwise Enter would activate that old button, not the new cursor.
        (_open ? _navigation : _railFocus).requestFocus();
        final scroll = _open ? _prompts : _rail;
        if (scroll.hasClients) {
          scroll.jumpTo(
            (_cursor * (_open ? extent : 7.0)).clamp(
              0,
              scroll.position.maxScrollExtent,
            ),
          );
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape && _open) {
        _close();
        return KeyEventResult.handled;
      }
      if ((_navigation.hasPrimaryFocus || _railFocus.hasPrimaryFocus) &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        activate(_cursor);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    Widget earlier() => TextButton(
      key: const ValueKey('hermes-timeline-earlier'),
      onPressed: widget.canShowEarlier && !widget.loadingEarlier
          ? () {
              if (widget.hidden || _owner != widget.viewport.ownerIdentity) {
                return;
              }
              if (_open) _close();
              widget.onEarlier();
            }
          : null,
      child: Text(
        widget.loadingEarlier
            ? strings.chatTranscriptLoadingEarlierLabel
            : strings.chatTimelineShowEarlier,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_open || constraints.maxWidth < 600) {
          _lastRailIndex = null;
          _hover = null;
        }
        // Reserve space only for real loaded navigation, independently of its
        // hide preference. Short keyboard viewports use a side lane, preserving
        // at least 64px of transcript instead of imposing a 48px header.
        final sideLane =
            _hasPrompts && !widget.hasHeader && constraints.maxHeight < 112;
        return Stack(
          children: [
            PositionedDirectional(
              top: _hasPrompts && !widget.hasHeader && !sideLane ? 48 : 0,
              bottom: 0,
              start: 0,
              end: sideLane ? 48 : 0,
              child: ExcludeFocus(
                excluding: available && _open,
                child: ExcludeSemantics(
                  excluding: available && _open,
                  child: widget.child,
                ),
              ),
            ),
            if (available && !_open)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: IconButton(
                  key: const ValueKey('hermes-timeline-open'),
                  focusNode: _control,
                  tooltip: strings.chatConversationTimeline,
                  icon: const Icon(Icons.format_list_bulleted, size: 18),
                  onPressed: () {
                    setState(() => _open = true);
                    _navigation.requestFocus();
                  },
                ),
              ),
            if (available &&
                !_open &&
                constraints.maxHeight >= 112 &&
                constraints.maxWidth >= 600)
              PositionedDirectional(
                end: 0,
                top: (constraints.maxHeight * .25).clamp(48, double.infinity),
                width: constraints.maxWidth >= 720 ? 24 : 12,
                height: constraints.maxHeight * .5,
                child: Focus(
                  focusNode: _railFocus,
                  onFocusChange: (focused) {
                    setState(() {
                      if (focused) _cursor = _activeIndex;
                    });
                  },
                  onKeyEvent: (_, event) => key(event),
                  child: ListenableBuilder(
                    listenable: Listenable.merge([
                      widget.viewport,
                      widget.viewport.scroll,
                    ]),
                    builder: (context, _) {
                      _scheduleActivePrompt();
                      _activeIndex =
                          widget.viewport.mode ==
                              HermesViewportMode.followingLatest
                          ? entries.length - 1
                          : _activeIndex.clamp(0, entries.length - 1);
                      final active = entries[_activeIndex].id;
                      if (!_railFocus.hasFocus &&
                          _hover == null &&
                          _lastRailIndex != _activeIndex) {
                        final index = _activeIndex;
                        final owner = _owner;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted ||
                              widget.hidden ||
                              owner != widget.viewport.ownerIdentity ||
                              !_rail.hasClients ||
                              _railFocus.hasFocus ||
                              _hover != null ||
                              index != _activeIndex) {
                            return;
                          }
                          _rail.jumpTo(
                            (index * 7.0).clamp(
                              0,
                              _rail.position.maxScrollExtent,
                            ),
                          );
                          _lastRailIndex = index;
                        });
                      }
                      return Semantics(
                        label: strings.chatConversationTimeline,
                        container: true,
                        value: _railFocus.hasFocus
                            ? entries[_cursor].preview
                            : null,
                        child: ListView.builder(
                          key: const ValueKey('hermes-timeline-rail'),
                          controller: _rail,
                          itemExtent: 7,
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final selected = active == entry.id;
                            return Semantics(
                              button: true,
                              selected: selected,
                              label: entry.preview,
                              onTap: () => activate(index),
                              child: Tooltip(
                                message: entry.preview,
                                excludeFromSemantics: true,
                                child: MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _hover = index),
                                  onExit: (_) => setState(() => _hover = null),
                                  child: GestureDetector(
                                    onTap: () {
                                      _cursor = index;
                                      activate(index);
                                    },
                                    child: Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: Container(
                                        width:
                                            selected ||
                                                _hover == index ||
                                                (_railFocus.hasFocus &&
                                                    _cursor == index)
                                            ? 16
                                            : 8,
                                        height: 2,
                                        color: selected
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (available && _open)
              Positioned.fill(
                child: Material(
                  key: const ValueKey('hermes-timeline-dialog'),
                  elevation: 4,
                  child: FocusScope(
                    child: Focus(
                      focusNode: _navigation,
                      onKeyEvent: (_, event) => key(event),
                      child: Semantics(
                        container: true,
                        explicitChildNodes: true,
                        label: strings.chatConversationTimeline,
                        value: entries[_cursor].preview,
                        liveRegion: true,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(strings.chatConversationTimeline),
                                ),
                                IconButton(
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).closeButtonTooltip,
                                  onPressed: _close,
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            if (widget.canShowEarlier || widget.loadingEarlier)
                              earlier(),
                            Expanded(
                              child: ListView.builder(
                                key: const ValueKey('hermes-timeline-prompts'),
                                controller: _prompts,
                                itemExtent: extent,
                                itemCount: entries.length,
                                itemBuilder: (context, index) => Semantics(
                                  selected: index == _cursor,
                                  child: TextButton(
                                    key: ValueKey(
                                      'hermes-timeline-prompt-${entries[index].id}',
                                    ),
                                    onPressed: () => activate(index),
                                    onFocusChange: (focused) {
                                      if (focused) {
                                        setState(() => _cursor = index);
                                      }
                                    },
                                    child: Text(
                                      entries[index].preview,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
