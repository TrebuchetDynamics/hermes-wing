import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A viewport for the complete block sequence produced by the Markdown parser.
///
/// Unknown extents are estimates for index lookup only. Mounted blocks always
/// receive unconstrained main-axis layout; tables, images and expanded code are
/// never forced into a guessed height.
class HermesMarkdownBlockViewport extends StatelessWidget {
  const HermesMarkdownBlockViewport({
    required this.controller,
    required this.children,
    required this.source,
    super.key,
  });

  final ScrollController controller;
  final List<Widget> children;
  final String source;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: controller,
    // No speculative mounting beyond the viewport. In particular, a far jump
    // must not build all intervening selection/accessibility subtrees.
    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
    slivers: [
      _MarkdownBlocks(
        source: source,
        textScaler: MediaQuery.textScalerOf(context),
        theme: Theme.of(context),
        delegate: SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: false,
        ),
      ),
    ],
  );
}

class _MarkdownBlocks extends SliverMultiBoxAdaptorWidget {
  const _MarkdownBlocks({
    required this.source,
    required this.textScaler,
    required this.theme,
    required super.delegate,
  });

  final String source;
  final TextScaler textScaler;
  final ThemeData theme;

  @override
  _RenderMarkdownBlocks createRenderObject(BuildContext context) =>
      _RenderMarkdownBlocks(
        source,
        textScaler,
        theme,
        childManager: context as SliverMultiBoxAdaptorElement,
        count: delegate.estimatedChildCount!,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMarkdownBlocks renderObject,
  ) => renderObject.update(
    count: delegate.estimatedChildCount!,
    source: source,
    textScaler: textScaler,
    theme: theme,
  );
}

/// Prefix sums of measured extents and counts. Unmeasured entries use the mean
/// of actual measurements. Binary lookup costs O(log² n), without visiting or
/// mounting any skipped block. Storage is bounded by the parsed block count.
class _BlockExtents {
  _BlockExtents(this.count)
    : _extents = List<double?>.filled(count, null),
      _sums = List<double>.filled(count + 1, 0),
      _counts = List<int>.filled(count + 1, 0);

  final int count;
  final List<double?> _extents;
  final List<double> _sums;
  final List<int> _counts;
  double _total = 0;
  int _measured = 0;
  double estimate = 1;

  void measure(int index, double extent) {
    final previous = _extents[index];
    if (previous == extent) return;
    final delta = extent - (previous ?? 0);
    _extents[index] = extent;
    _total += delta;
    if (previous == null) _measured++;
    for (var i = index + 1; i <= count; i += i & -i) {
      _sums[i] += delta;
      if (previous == null) _counts[i]++;
    }
  }

  void refineEstimate() {
    if (_measured > 0) estimate = math.max(1, _total / _measured);
  }

  double offset(int index) {
    var sum = 0.0;
    var measured = 0;
    for (var i = index; i > 0; i -= i & -i) {
      sum += _sums[i];
      measured += _counts[i];
    }
    return sum + (index - measured) * estimate;
  }

  int indexAt(double offset) {
    var low = 0;
    var high = count;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (this.offset(middle + 1) <= offset) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return math.min(low, count - 1);
  }
}

class _RenderMarkdownBlocks extends RenderSliverMultiBoxAdaptor {
  _RenderMarkdownBlocks(
    this._source,
    this._textScaler,
    this._theme, {
    required super.childManager,
    required int count,
  }) : _extents = _BlockExtents(count);

  _BlockExtents _extents;
  String _source;
  TextScaler _textScaler;
  ThemeData _theme;
  double? _width;
  bool _needsSeed = true;
  double? _lastTotal;
  int? _resetAnchor;
  double _resetAnchorDelta = 0;

  void update({
    required int count,
    required String source,
    required TextScaler textScaler,
    required ThemeData theme,
  }) {
    if (_extents.count != count ||
        _source != source ||
        _textScaler != textScaler ||
        _theme != theme) {
      _source = source;
      _textScaler = textScaler;
      _theme = theme;
      _reset(count);
    }
    markNeedsLayout();
  }

  void _reset(int count) {
    if (firstChild != null && indexOf(firstChild!) < count) {
      _resetAnchor = indexOf(firstChild!);
      _resetAnchorDelta =
          constraints.scrollOffset - (childScrollOffset(firstChild!) ?? 0);
    } else {
      _resetAnchor = null;
    }
    _extents = _BlockExtents(count);
    _needsSeed = true;
    _lastTotal = null;
  }

  void _setOffset(RenderBox child, double offset) {
    (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
        offset;
  }

  // An explicit jump to the scrollbar's end must remain at the end while the
  // estimate changes. Measure the real suffix backwards instead of chasing a
  // moving estimated maximum over multiple jumps.
  void _layoutEnd(BoxConstraints box) {
    if (lastChild == null || indexOf(lastChild!) != _extents.count - 1) {
      collectGarbage(childCount, 0);
      addInitialChild(index: _extents.count - 1);
    }
    var child = lastChild!;
    var extent = 0.0;
    while (true) {
      child.layout(box, parentUsesSize: true);
      _extents.measure(indexOf(child), paintExtentOf(child));
      extent += paintExtentOf(child);
      if (extent >= constraints.remainingPaintExtent || indexOf(child) == 0) {
        break;
      }
      child =
          childBefore(child) ??
          insertAndLayoutLeadingChild(box, parentUsesSize: true)!;
    }
    collectGarbage(calculateLeadingGarbage(firstIndex: indexOf(child)), 0);
    _extents.refineEstimate();
    final start = _extents.offset(indexOf(child));
    var end = start;
    RenderBox? walker = child;
    while (walker != null) {
      _setOffset(walker, end);
      end += paintExtentOf(walker);
      walker = childAfter(walker);
    }
    _lastTotal = end;
    final correction =
        math.max(0.0, end - constraints.remainingPaintExtent) -
        constraints.scrollOffset;
    if (correction.abs() > precisionErrorTolerance) {
      geometry = SliverGeometry(scrollOffsetCorrection: correction);
      return;
    }
    geometry = SliverGeometry(
      scrollExtent: end,
      paintExtent: calculatePaintOffset(constraints, from: start, to: end),
      cacheExtent: calculateCacheOffset(constraints, from: start, to: end),
      maxPaintExtent: end,
      hasVisualOverflow: constraints.scrollOffset > 0,
    );
    childManager.setDidUnderflow(true);
  }

  @override
  void performLayout() {
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    if (_width != constraints.crossAxisExtent) {
      _width = constraints.crossAxisExtent;
      _reset(_extents.count);
    }
    if (_extents.count == 0) {
      collectGarbage(childCount, 0);
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }
    final box = constraints.asBoxConstraints();
    if (_needsSeed) {
      // Seed from a real layout, not a universal item extent or source heuristic.
      // Retain existing block state across width/theme/scale invalidation.
      if (firstChild != null && indexOf(firstChild!) >= _extents.count) {
        collectGarbage(childCount, 0);
      }
      if (firstChild == null && !addInitialChild()) {
        geometry = SliverGeometry.zero;
        childManager.didFinishLayout();
        return;
      }
      firstChild!.layout(box, parentUsesSize: true);
      _extents.measure(indexOf(firstChild!), paintExtentOf(firstChild!));
      _extents.refineEstimate();
      _needsSeed = false;
      final anchor = _resetAnchor;
      _resetAnchor = null;
      if (anchor != null) {
        final correction =
            _extents.offset(anchor) +
            _resetAnchorDelta -
            constraints.scrollOffset;
        if (correction.abs() > precisionErrorTolerance) {
          // Invalidate measurements without replacing a mounted selection or
          // expanded-code subtree merely because its layout inputs changed.
          geometry = SliverGeometry(scrollOffsetCorrection: correction);
          childManager.didFinishLayout();
          return;
        }
      }
    }

    final scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    if (_lastTotal != null &&
        constraints.scrollOffset > 0 &&
        constraints.scrollOffset + constraints.remainingPaintExtent >=
            _lastTotal! - precisionErrorTolerance) {
      _layoutEnd(box);
      childManager.didFinishLayout();
      return;
    }
    final targetEnd = scrollOffset + constraints.remainingCacheExtent;
    final firstIndex = _extents.indexAt(scrollOffset);
    final start = _extents.offset(firstIndex);
    if (firstChild != null &&
        (firstIndex < indexOf(firstChild!) ||
            firstIndex > indexOf(lastChild!))) {
      collectGarbage(childCount, 0);
    } else {
      collectGarbage(calculateLeadingGarbage(firstIndex: firstIndex), 0);
    }
    if (firstChild == null &&
        !addInitialChild(index: firstIndex, layoutOffset: start)) {
      geometry = SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    var child = firstChild!;
    var end = start;
    while (true) {
      _setOffset(child, end);
      child.layout(box, parentUsesSize: true);
      final index = indexOf(child);
      final extent = paintExtentOf(child);
      // Re-measure every visible child: expand/collapse and asynchronous image
      // layout replace its cached extent and therefore all following prefixes.
      _extents.measure(index, extent);
      end += extent;
      if (end >= targetEnd || index == _extents.count - 1) break;
      final next = childAfter(child);
      child =
          next ??
          insertAndLayoutChild(box, after: child, parentUsesSize: true)!;
    }
    collectGarbage(0, calculateTrailingGarbage(lastIndex: indexOf(child)));
    _extents.refineEstimate();
    final shift = _extents.offset(firstIndex) - start;
    if (shift.abs() > precisionErrorTolerance) {
      _lastTotal = _extents.offset(_extents.count);
      // Refine unknown prefixes while anchoring the first visible block. The
      // corrected pass seeks the same index, not the intervening unmounted ones.
      geometry = SliverGeometry(scrollOffsetCorrection: shift);
      childManager.didFinishLayout();
      return;
    }

    final total = math.max(end, _extents.offset(_extents.count));
    _lastTotal = total;
    geometry = SliverGeometry(
      scrollExtent: total,
      paintExtent: calculatePaintOffset(constraints, from: start, to: end),
      cacheExtent: calculateCacheOffset(constraints, from: start, to: end),
      maxPaintExtent: total,
      hasVisualOverflow: constraints.scrollOffset > 0 || end > targetEnd,
    );
    childManager.setDidUnderflow(indexOf(child) == _extents.count - 1);
    childManager.didFinishLayout();
  }
}
