import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds [Text] widgets whose [Text.data] contains [needle] (case-insensitive).
Finder caseInsensitiveText(String needle) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final data = widget.data;
    if (data == null) return false;
    return data.toLowerCase().contains(needle.toLowerCase());
  });
}

/// Finds [Text] widgets whose [Text.data] contains [needle] (case-sensitive).
Finder visibleTextContaining(String needle) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Text) return false;
    final data = widget.data;
    if (data == null) return false;
    return data.contains(needle);
  });
}
