import 'dart:convert';

class WingLinkDirectory {
  const WingLinkDirectory({required this.handle, required this.name});

  factory WingLinkDirectory.fromJson(Map<String, Object?> json) {
    if (json.keys.any((key) => key != 'handle' && key != 'name')) {
      throw const FormatException('Unexpected directory field');
    }
    final handle = json['handle'];
    final name = json['name'];
    if (handle is! String ||
        !isValidHandle(handle) ||
        name is! String ||
        name.isEmpty ||
        utf8.encode(name).length > 255 ||
        name.contains('\u0000') ||
        name.contains('/') ||
        name.contains('\\')) {
      throw const FormatException('Invalid directory');
    }
    return WingLinkDirectory(handle: handle, name: name);
  }

  final String handle;
  final String name;

  static final RegExp _handlePattern = RegExp(r'^dirh_[A-Za-z0-9_-]{22,92}$');

  static bool isValidHandle(String value) => _handlePattern.hasMatch(value);
}

class WingLinkDirectoryPage {
  const WingLinkDirectoryPage({this.directories = const [], this.nextOffset});

  factory WingLinkDirectoryPage.fromJson(
    Map<String, Object?> json, {
    required int maximumDirectories,
    required bool allowNextOffset,
  }) {
    if (json.keys.any((key) => key != 'directories' && key != 'next_offset')) {
      throw const FormatException('Unexpected directory page field');
    }
    final rows = json['directories'];
    final nextOffset = json['next_offset'];
    if (rows is! List || rows.length > maximumDirectories) {
      throw const FormatException('Invalid directory page');
    }
    if (json.containsKey('next_offset') &&
        (!allowNextOffset ||
            nextOffset is! int ||
            nextOffset < 0 ||
            nextOffset > 1000)) {
      throw const FormatException('Invalid directory page');
    }
    final directories = <WingLinkDirectory>[];
    for (final row in rows) {
      if (row is! Map) {
        throw const FormatException('Invalid directory page');
      }
      directories.add(WingLinkDirectory.fromJson(row.cast<String, Object?>()));
    }
    return WingLinkDirectoryPage(
      directories: List.unmodifiable(directories),
      nextOffset: nextOffset as int?,
    );
  }

  final List<WingLinkDirectory> directories;
  final int? nextOffset;
}
