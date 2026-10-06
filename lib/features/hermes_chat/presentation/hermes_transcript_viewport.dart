import 'package:flutter/material.dart';
import '../../../core/hermes/models/hermes_chat_turn.dart';
import 'hermes_turn_presentation_identity.dart';

enum HermesViewportMode { followingLatest, browsing, restoring, explicitTarget }

class HermesViewportAnchor {
  const HermesViewportAnchor(this.owner, this.turnId, this.edgeOffset);
  final Object owner;
  final String turnId;
  final double edgeOffset;
}

/// Bounded, process-local reading position. Only unique Agent IDs may restore.
class HermesTranscriptViewportController extends ChangeNotifier {
  HermesTranscriptViewportController(this.scroll);
  final ScrollController scroll;
  final listKey = GlobalKey();
  final _rows = <String, GlobalKey>{};
  final _anchors = <Object, HermesViewportAnchor>{};
  Object? _owner;
  String? _origin;
  int _generation = 0;
  bool _disposed = false;
  int _budget = 100;
  String? _windowEndId;
  int windowStart = 0;
  int windowEnd = 0;
  bool continuedTools = false;

  /// Presentation only; the channel retains all canonical loaded history.
  List<HermesChatTurn> project(
    List<HermesChatTurn> eligible, {
    Set<String>? uniqueIds,
  }) {
    final unique =
        uniqueIds ?? HermesTurnPresentationIdentity.uniqueIds(eligible);
    var end = eligible.length;
    if (mode != HermesViewportMode.followingLatest && _windowEndId != null) {
      final index = unique.contains(_windowEndId)
          ? eligible.indexWhere((turn) => turn.id == _windowEndId)
          : -1;
      if (index >= 0) {
        end = index + 1;
      } else {
        _budget = 100;
        _windowEndId = null;
      }
    }
    var start =
        (end - (mode == HermesViewportMode.followingLatest ? 100 : _budget))
            .clamp(0, end);
    bool toolAt(int i) =>
        i >= 0 &&
        i < eligible.length &&
        eligible[i].kind == HermesTurnKind.toolCall &&
        eligible[i].toolCall != null;
    if (mode == HermesViewportMode.followingLatest) {
      var groupStart = start;
      while (groupStart > 0 &&
          toolAt(groupStart) &&
          toolAt(groupStart - 1) &&
          start - groupStart < 100) {
        groupStart--;
      }
      if (!toolAt(groupStart - 1)) start = groupStart;
    }
    windowStart = start;
    windowEnd = end;
    continuedTools = start > 0 && toolAt(start) && toolAt(start - 1);
    if (mode == HermesViewportMode.followingLatest) {
      _windowEndId = end > 0 && unique.contains(eligible[end - 1].id)
          ? eligible[end - 1].id
          : null;
      _budget = end - start;
    }
    return eligible.sublist(start, end);
  }

  void revealEarlier() => _budget = windowEnd - windowStart + 100;
  HermesViewportMode _mode = HermesViewportMode.followingLatest;
  HermesViewportMode get mode => _mode;
  set mode(HermesViewportMode value) {
    if (_mode == value) return;
    _mode = value;
    if (!_disposed) notifyListeners();
  }

  int get generation => _generation;

  void setOwner(Object? owner, {String? origin}) {
    if (_owner == owner && _origin == origin) return;
    capture();
    if (_origin != origin) _anchors.clear();
    _origin = origin;
    _owner = owner;
    _generation++;
    _rows.clear();
    // Explicit session selection wins over a previous reading position.
    _budget = 100;
    _windowEndId = null;
    mode = HermesViewportMode.followingLatest;
  }

  void retainRows(Set<String> ids) =>
      _rows.removeWhere((id, _) => !ids.contains(id));
  GlobalKey rowKey(String id) => _rows.putIfAbsent(id, GlobalKey.new);

  void userScrolled({required bool nearLatest}) {
    _generation++;
    mode = nearLatest
        ? HermesViewportMode.followingLatest
        : HermesViewportMode.browsing;
  }

  void followLatest() {
    _generation++;
    _budget = 100;
    _windowEndId = null;
    mode = HermesViewportMode.followingLatest;
  }

  bool onScroll(ScrollNotification notification) {
    if (notification.depth == 0 &&
        (notification is UserScrollNotification ||
            notification is ScrollUpdateNotification &&
                notification.dragDetails != null)) {
      userScrolled(
        nearLatest:
            notification.metrics.pixels - notification.metrics.minScrollExtent <
            80,
      );
    }
    return false;
  }

  void capture() {
    final owner = _owner;
    if (owner == null || mode == HermesViewportMode.followingLatest) return;
    final list = listKey.currentContext?.findRenderObject();
    if (list is! RenderBox || !list.hasSize) return;
    final top = list.localToGlobal(Offset.zero).dy;
    HermesViewportAnchor? anchor;
    for (final entry in _rows.entries) {
      final row = entry.value.currentContext?.findRenderObject();
      if (row is! RenderBox || !row.hasSize || !row.attached) continue;
      final y = row.localToGlobal(Offset.zero).dy - top;
      if (y + row.size.height <= 0 || y >= list.size.height) continue;
      if (anchor == null || y < anchor.edgeOffset) {
        anchor = HermesViewportAnchor(owner, entry.key, y);
      }
    }
    _anchors.remove(owner);
    if (anchor != null) _anchors[owner] = anchor;
    while (_anchors.length > 64) {
      _anchors.remove(_anchors.keys.first);
    }
  }

  int beginAuthoritativeRefresh() {
    capture();
    if (mode != HermesViewportMode.followingLatest) {
      mode = HermesViewportMode.restoring;
    }
    return ++_generation;
  }

  void restore(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || generation != _generation || !scroll.hasClients) return;
      final anchor = _anchors[_owner];
      final list = listKey.currentContext?.findRenderObject();
      final row = anchor == null
          ? null
          : _rows[anchor.turnId]?.currentContext?.findRenderObject();
      if (mode == HermesViewportMode.restoring &&
          row is RenderBox &&
          row.hasSize &&
          list is RenderBox &&
          list.hasSize) {
        final y =
            row.localToGlobal(Offset.zero).dy -
            list.localToGlobal(Offset.zero).dy;
        final sign = scroll.position.axisDirection == AxisDirection.up ? -1 : 1;
        final target = scroll.offset + sign * (y - anchor!.edgeOffset);
        scroll.jumpTo(
          target.clamp(
            scroll.position.minScrollExtent,
            scroll.position.maxScrollExtent,
          ),
        );
        mode = HermesViewportMode.browsing;
      } else if (mode == HermesViewportMode.restoring ||
          mode == HermesViewportMode.followingLatest) {
        followLatest();
        scroll.jumpTo(scroll.position.minScrollExtent);
        // Shrinking a lazy list can correct its estimated extent on the next
        // layout. Reassert explicit Latest only if no newer reading intent won.
        final latestGeneration = _generation;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed &&
              latestGeneration == _generation &&
              mode == HermesViewportMode.followingLatest &&
              scroll.hasClients) {
            scroll.jumpTo(scroll.position.minScrollExtent);
          }
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
    // A canonical refresh may leave the widget tree unchanged. Post-frame work
    // alone does not request a frame, so restoration must arrange one.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _anchors.clear();
    _rows.clear();
    super.dispose();
  }

  void forgetWhere(bool Function(Object owner) matches) {
    _anchors.removeWhere((key, _) => matches(key));
    if (_owner != null && matches(_owner!)) {
      _generation++;
      mode = HermesViewportMode.followingLatest;
    }
  }
}
