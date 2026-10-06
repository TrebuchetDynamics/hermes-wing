import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/hermes/models/hermes_profile.dart';
import '../../../l10n/app_localizations.dart';

/// Volatile presentation over the Chat owner's already-loaded inventory.
class ChatProfilePicker extends StatefulWidget {
  const ChatProfilePicker({
    super.key,
    required this.profiles,
    required this.selectedId,
    required this.preview,
    required this.onChoose,
    required this.onManage,
  });

  final ValueNotifier<List<HermesProfile>> profiles;
  final String? selectedId;
  final String Function(String) preview;
  final ValueChanged<String> onChoose;
  final VoidCallback onManage;

  @override
  State<ChatProfilePicker> createState() => _ChatProfilePickerState();
}

class _ChatProfilePickerState extends State<ChatProfilePicker> {
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  final _rows = <String, GlobalKey>{};
  String? _highlightedId;

  List<HermesProfile> get _matches {
    final q = _query.text.toLowerCase();
    final matches = widget.profiles.value
        .where(
          (p) =>
              p.displayName.toLowerCase().contains(q) ||
              p.id.toLowerCase().contains(q) ||
              p.model.toLowerCase().contains(q),
        )
        .toList();
    return [
      ...matches.where((p) => p.id == widget.selectedId),
      ...matches.where((p) => p.id != widget.selectedId),
    ];
  }

  @override
  void initState() {
    super.initState();
    widget.profiles.addListener(_refresh);
    _highlightedId = _matches.firstOrNull?.id;
  }

  void _refresh() {
    final matches = _matches;
    if (!matches.any((p) => p.id == _highlightedId)) {
      _highlightedId = matches.firstOrNull?.id;
    }
    setState(() {});
    _reveal(_highlightedId);
  }

  void _reveal(String? id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final row = _rows[id]?.currentContext;
      if (row != null) {
        Scrollable.ensureVisible(
          row,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        );
      }
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    // Do not replace native row/button activation or text-editing shortcuts.
    if (!_searchFocus.hasFocus ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isShiftPressed ||
        !_query.value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final matches = _matches;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final target = matches.where((p) => p.id == _highlightedId).firstOrNull;
      if (target != null) widget.onChoose(target.id);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (matches.isNotEmpty) {
        final index = matches.indexWhere((p) => p.id == _highlightedId);
        final next =
            (index +
                    (event.logicalKey == LogicalKeyboardKey.arrowDown ? 1 : -1))
                .clamp(0, matches.length - 1);
        setState(() => _highlightedId = matches[next].id);
        _reveal(_highlightedId);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    widget.profiles.removeListener(_refresh);
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final matches = _matches;
    return SafeArea(
      child: Focus(
        onKeyEvent: _key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Semantics(
                header: true,
                child: Text(
                  strings.switchAgentTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                key: const ValueKey('chat-profile-search'),
                controller: _query,
                focusNode: _searchFocus,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: strings.chatProfileSearch,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          key: const ValueKey('chat-profile-clear'),
                          tooltip: strings.profilesSearchClear,
                          onPressed: () {
                            _query.clear();
                            setState(
                              () => _highlightedId = _matches.firstOrNull?.id,
                            );
                            _searchFocus.requestFocus();
                            _reveal(_highlightedId);
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: (_) {
                  setState(() => _highlightedId = _matches.firstOrNull?.id);
                  _reveal(_highlightedId);
                },
              ),
            ),
            Expanded(
              child: matches.isEmpty
                  ? Center(
                      child: Semantics(
                        liveRegion: true,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            widget.profiles.value.isEmpty
                                ? strings.agentsEmptyTitle
                                : strings.profilesSearchNoMatchesTitle,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      key: const ValueKey('chat-profile-list'),
                      child: Column(
                        children: [
                          for (final profile in matches)
                            KeyedSubtree(
                              key: _rows.putIfAbsent(profile.id, GlobalKey.new),
                              child: Focus(
                                canRequestFocus: false,
                                onFocusChange: (focused) {
                                  if (focused) {
                                    setState(() => _highlightedId = profile.id);
                                    _reveal(profile.id);
                                  }
                                },
                                child: Semantics(
                                  selected: profile.id == widget.selectedId,
                                  hint: profile.id == _highlightedId
                                      ? strings.chatProfileHighlighted
                                      : null,
                                  child: ListTile(
                                    key: ValueKey(
                                      'chat-profile-row-${profile.id}',
                                    ),
                                    leading: Icon(
                                      profile.id == widget.selectedId
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                    ),
                                    trailing: profile.id == _highlightedId
                                        ? const Icon(Icons.chevron_right)
                                        : null,
                                    title: Text(
                                      widget.preview(
                                        profile.displayName.isEmpty
                                            ? profile.id
                                            : profile.displayName,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${strings.agentStableId(widget.preview(profile.id))}${profile.model.isEmpty ? '' : '\n${widget.preview(profile.model)}'}',
                                    ),
                                    selected: profile.id == widget.selectedId,
                                    onTap: () => widget.onChoose(profile.id),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            TextButton.icon(
              key: const ValueKey('chat-profile-manage'),
              onPressed: widget.onManage,
              icon: const Icon(Icons.settings_outlined),
              label: Text(strings.chatProfileManage),
            ),
          ],
        ),
      ),
    );
  }
}
