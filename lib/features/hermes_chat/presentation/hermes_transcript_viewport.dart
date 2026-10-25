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
  final _projectedIndices = <String, int>{};
  final _anchors = <Object, HermesViewportAnchor>{};
  Object? _owner;
  String? _origin;
  Object? _source;
  int _generation = 0;
  bool _disposed = false;
  int _budget = 100;
  String? _windowEndId;
  int windowStart = 0;
  int windowEnd = 0;
  bool continuedTools = false;
  HermesChatTurn? _target;
  int? _scheduledTargetGeneration;

  Object get ownerIdentity => (_owner, _origin, _source);

  /// Chooses a bounded loaded window; never reads or mutates channel history.
  bool jumpToPrompt(String id, List<HermesChatTurn> turns) {
    if (_disposed || _owner == null) return false;
    final unique = HermesTurnPresentationIdentity.uniqueIds(turns);
    if (!unique.contains(id)) return false;
    final turn = turns.firstWhere((turn) => turn.id == id);
    if (turn.author != HermesTurnAuthor.user ||
        turn.kind != HermesTurnKind.text ||
        turn.text.trim().isEmpty) {
      return false;
    }
    _generation++;
    _target = turn;
    _budget = 100;
    if (mode == HermesViewportMode.explicitTarget) {
      notifyListeners();
    } else {
      mode = HermesViewportMode.explicitTarget;
    }
    _seekTarget(_generation);
    return true;
  }

  void cancelTarget({bool notify = true}) {
    if (_target == null) return;
    _target = null;
    _generation++;
    if (mode == HermesViewportMode.explicitTarget) {
      if (notify) {
        mode = HermesViewportMode.browsing;
      } else {
        _mode = HermesViewportMode.browsing;
      }
    }
  }

  /// Last prompt at the measured top, or the first mounted prompt below it.
  String? activePromptId(Set<String> prompts) {
    if (mode == HermesViewportMode.followingLatest) return null;
    final list = listKey.currentContext?.findRenderObject();
    if (list is! RenderBox || !list.hasSize) return null;
    String? above;
    String? below;
    var aboveY = -double.infinity;
    var belowY = double.infinity;
    for (final entry in _rows.entries) {
      if (!prompts.contains(entry.key)) continue;
      final row = entry.value.currentContext?.findRenderObject();
      if (row is! RenderBox || !row.attached || !row.hasSize) continue;
      final y =
          row.localToGlobal(Offset.zero).dy -
          list.localToGlobal(Offset.zero).dy;
      if (y <= 8 && y > aboveY) {
        above = entry.key;
        aboveY = y;
      }
      if (y > 8 && y < belowY) {
        below = entry.key;
        belowY = y;
      }
    }
    return above ?? below;
  }

  void _seekTarget(int generation) {
    if (_scheduledTargetGeneration == generation) return;
    _scheduledTargetGeneration = generation;
    var remaining = 104;
    void afterLayout(Duration _) {
      if (_disposed ||
          generation != _generation ||
          _target == null ||
          mode != HermesViewportMode.explicitTarget ||
          !scroll.hasClients) {
        return;
      }
      final id = _target!.id;
      if (!_projectedIndices.containsKey(id)) {
        cancelTarget();
        return;
      }
      final list = listKey.currentContext?.findRenderObject();
      final row = _rows[id]?.currentContext?.findRenderObject();
      if (list is RenderBox &&
          list.hasSize &&
          row is RenderBox &&
          row.attached &&
          row.hasSize) {
        final y =
            row.localToGlobal(Offset.zero).dy -
            list.localToGlobal(Offset.zero).dy;
        final sign = scroll.position.axisDirection == AxisDirection.up ? -1 : 1;
        final before = scroll.offset;
        scroll.jumpTo(
          (scroll.offset + sign * (y - 8)).clamp(
            scroll.position.minScrollExtent,
            scroll.position.maxScrollExtent,
          ),
        );
        // Reversed lazy extents can correct on layout. Verify the measured row
        // again, rather than guessing an offset from total estimated height.
        if ((y - 8).abs() > 1 &&
            (scroll.offset - before).abs() > .5 &&
            remaining-- > 0) {
          WidgetsBinding.instance.addPostFrameCallback(afterLayout);
          WidgetsBinding.instance.ensureVisualUpdate();
          return;
        }
        _target = null;
        mode = HermesViewportMode.browsing;
      } else if (remaining-- > 0 && _scrollToward(id, list)) {
        WidgetsBinding.instance.addPostFrameCallback(afterLayout);
        WidgetsBinding.instance.ensureVisualUpdate();
      } else {
        cancelTarget();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Presentation only; the channel retains all canonical loaded history.
  List<HermesChatTurn> project(
    List<HermesChatTurn> eligible, {
    Set<String>? uniqueIds,
  }) {
    final unique =
        uniqueIds ?? HermesTurnPresentationIdentity.uniqueIds(eligible);
    var end = eligible.length;
    final target = _target;
    if (target != null) {
      final index = unique.contains(target.id)
          ? eligible.indexWhere(
              (turn) =>
                  turn.id == target.id &&
                  turn.text == target.text &&
                  turn.sessionId == target.sessionId &&
                  turn.author == target.author &&
                  turn.kind == target.kind,
            )
          : -1;
      if (index < 0) {
        _target = null;
        _generation++;
        _mode = HermesViewportMode.browsing;
      } else {
        final start = (index - 2).clamp(0, eligible.length);
        end = (start + 100).clamp(0, eligible.length);
        // A window boundary needs a canonical identity even when adjacent
        // loaded rows are ambiguous. The unique target itself is a safe end.
        while (end > index + 1 && !unique.contains(eligible[end - 1].id)) {
          end--;
        }
        _budget = end - start;
        _windowEndId = unique.contains(eligible[end - 1].id)
            ? eligible[end - 1].id
            : null;
      }
    }
    if (_target == null &&
        mode != HermesViewportMode.followingLatest &&
        _windowEndId != null) {
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
    _projectedIndices
      ..clear()
      ..addEntries([
        for (var i = start; i < end; i++)
          if (unique.contains(eligible[i].id))
            MapEntry(eligible[i].id, end - 1 - i),
      ]);
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

  void setOwner(Object? owner, {String? origin, Object? source}) {
    if (_owner == owner && _origin == origin && identical(_source, source)) {
      return;
    }
    capture();
    if (_origin != origin || !identical(_source, source)) _anchors.clear();
    _origin = origin;
    _source = source;
    _owner = owner;
    _target = null;
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
    _target = null;
    _generation++;
    mode = nearLatest
        ? HermesViewportMode.followingLatest
        : HermesViewportMode.browsing;
  }

  void followLatest() {
    _target = null;
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
    if (_target != null && mode == HermesViewportMode.explicitTarget) {
      return _generation;
    }
    capture();
    if (mode != HermesViewportMode.followingLatest) {
      mode = HermesViewportMode.restoring;
    }
    return ++_generation;
  }

  void restore(int generation) {
    if (_target != null && mode == HermesViewportMode.explicitTarget) {
      _seekTarget(generation);
      return;
    }
    var remainingSteps = _projectedIndices.length + 1;
    void afterLayout(Duration _) {
      if (_disposed || generation != _generation || !scroll.hasClients) return;
      final anchor = _anchors[_owner];
      final list = listKey.currentContext?.findRenderObject();
      final row = anchor == null
          ? null
          : _rows[anchor.turnId]?.currentContext?.findRenderObject();
      if (mode == HermesViewportMode.restoring &&
          anchor != null &&
          _projectedIndices.containsKey(anchor.turnId) &&
          !(row is RenderBox && row.attached && row.hasSize)) {
        // A changed lazy row can evict an otherwise valid reading anchor.
        // Realize it through measured, lazy scrolling rather than treating
        // temporary unmounting as an instruction to jump to Latest.
        if (remainingSteps-- > 0 && _scrollToward(anchor.turnId, list)) {
          WidgetsBinding.instance.addPostFrameCallback(afterLayout);
          WidgetsBinding.instance.ensureVisualUpdate();
        } else {
          mode = HermesViewportMode.browsing;
        }
        return;
      }
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
    }

    WidgetsBinding.instance.addPostFrameCallback(afterLayout);
    // A canonical refresh may leave the widget tree unchanged. Post-frame work
    // alone does not request a frame, so restoration must arrange one.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  bool _scrollToward(String id, RenderObject? list) {
    if (list is! RenderBox || !list.hasSize) return false;
    final targetIndex = _projectedIndices[id]!;
    RenderBox? nearest;
    int? nearestIndex;
    for (final entry in _rows.entries) {
      final index = _projectedIndices[entry.key];
      final box = entry.value.currentContext?.findRenderObject();
      if (index == null || box is! RenderBox || !box.attached || !box.hasSize) {
        continue;
      }
      if (nearestIndex == null ||
          (index - targetIndex).abs() < (nearestIndex - targetIndex).abs()) {
        nearest = box;
        nearestIndex = index;
      }
    }
    if (nearest == null || nearestIndex == null) return false;
    final direction = targetIndex > nearestIndex ? 1 : -1;
    final y =
        nearest.localToGlobal(Offset.zero).dy -
        list.localToGlobal(Offset.zero).dy;
    final seekTop =
        (scroll.position.axisDirection == AxisDirection.up) == (direction > 0);
    final edge = seekTop ? -y : y + nearest.size.height - list.size.height;
    // Skip the measured interior of a giant mounted row, never extrapolate
    // height changes from the lazy list's estimated maxScrollExtent.
    final step = edge > list.size.height ? edge : list.size.height;
    final target = (scroll.offset + direction * step)
        .clamp(scroll.position.minScrollExtent, scroll.position.maxScrollExtent)
        .toDouble();
    if ((target - scroll.offset).abs() < 0.5) return false;
    scroll.jumpTo(target);
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _target = null;
    _generation++;
    _anchors.clear();
    _rows.clear();
    super.dispose();
  }

  void forgetWhere(bool Function(Object owner) matches) {
    _anchors.removeWhere((key, _) => matches(key));
    if (_owner != null && matches(_owner!)) {
      _target = null;
      _generation++;
      mode = HermesViewportMode.followingLatest;
    }
  }
}
