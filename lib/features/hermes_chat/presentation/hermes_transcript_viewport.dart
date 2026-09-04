import 'package:flutter/material.dart';

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
  int _generation = 0;
  bool _disposed = false;
  HermesViewportMode _mode = HermesViewportMode.followingLatest;
  HermesViewportMode get mode => _mode;
  set mode(HermesViewportMode value) {
    if (_mode == value) return;
    _mode = value;
    if (!_disposed) notifyListeners();
  }

  int get generation => _generation;

  void setOwner(Object? owner) {
    if (_owner == owner) return;
    capture();
    _owner = owner;
    _generation++;
    _rows.clear();
    // Explicit session selection wins over a previous reading position.
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
