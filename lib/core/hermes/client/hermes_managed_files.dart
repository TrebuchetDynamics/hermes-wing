import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Optional native serve capability. Messaging API permission is not file access.
abstract interface class HermesManagedFilesChannel {
  /// Transport eligibility for policy discovery only; not a locked-root grant.
  bool get canBrowseManagedFiles;
  HermesManagedFilesSession beginManagedFiles();
}

enum HermesManagedFilesFailure {
  unsupported,
  denied,
  failed,
  malformed,
  oversized,
  binary,
  stale,
  cancelled,
}

final class HermesManagedFilesException implements Exception {
  const HermesManagedFilesException(this.kind);
  final HermesManagedFilesFailure kind;
  @override
  String toString() => 'Managed files unavailable: ${kind.name}';
}

/// One explicit attempt, including its native save. Never reused for Retry.
final class HermesManagedFileTransfer {
  HermesManagedFileTransfer({this.onProgress});
  final void Function(int received, int? total)? onProgress;
  final _cancelled = Completer<void>();
  bool get isCancelled => _cancelled.isCompleted;
  Future<void> get whenCancelled => _cancelled.future;
  void cancel() {
    if (!isCancelled) _cancelled.complete();
  }

  void check() {
    if (isCancelled) {
      throw const HermesManagedFilesException(
        HermesManagedFilesFailure.cancelled,
      );
    }
  }
}

final class HermesManagedFileEntry {
  const HermesManagedFileEntry._(
    this.name,
    this.path,
    this.isDirectory,
    this.size,
  );
  final String name, path;
  final bool isDirectory;
  final int? size;
}

final class HermesManagedDirectory {
  const HermesManagedDirectory._(
    this.root,
    this.path,
    this.parent,
    this.entries,
  );
  final String root, path;
  final String? parent;
  final List<HermesManagedFileEntry> entries;
}

/// Volatile read-only access to one connection's advertised managed root.
/// Path checks here reject malformed UI handles; confinement of resolved symlinks
/// and sensitive files is the Agent's managed-files policy, not this lexical gate.
final class HermesManagedFilesSession {
  HermesManagedFilesSession({
    required Future<Map<String, dynamic>> Function(
      String,
      Map<String, String>,
      int,
    )
    request,
    required bool Function() isCurrent,
    Future<Uint8List> Function(String path, HermesManagedFileTransfer transfer)?
    download,
  }) : // Public callbacks keep the native transport out of this shared decoder.
       // ignore: prefer_initializing_formals
       _download = download,
       // ignore: prefer_initializing_formals
       _request = request,
       // ignore: prefer_initializing_formals
       _isCurrent = isCurrent;

  static const maximumDownloadBytes = 8 * 1024 * 1024;
  static const maximumPreviewBytes = 64 * 1024;
  static const maximumEntries = 500;
  final Future<Map<String, dynamic>> Function(String, Map<String, String>, int)
  _request;
  final bool Function() _isCurrent;
  final Future<Uint8List> Function(String, HermesManagedFileTransfer)?
  _download;
  bool get canDownload => isCurrent && _root != null && _download != null;
  String? _root;
  bool _retired = false, _busy = false;
  final _directories = <String>{};
  List<HermesManagedFileEntry> _entries = const [];

  bool get isCurrent => !_retired && _isCurrent();
  void _current() {
    if (!isCurrent) _fail(HermesManagedFilesFailure.stale);
  }

  Never _fail(HermesManagedFilesFailure kind) =>
      throw HermesManagedFilesException(kind);
  Never _malformed() {
    _retired = true;
    _fail(HermesManagedFilesFailure.malformed);
  }

  String _path(Object? value) {
    if (value is! String ||
        value.length > 4096 ||
        !value.startsWith('/') ||
        value.contains(RegExp(r'[\x00-\x1f\x7f\\]')) ||
        value
            .split('/')
            .skip(1)
            .any((p) => p.isEmpty || p == '.' || p == '..')) {
      return _malformed();
    }
    return value;
  }

  bool _inside(String path) => path == _root || path.startsWith('${_root!}/');
  String _policy(Map<String, dynamic> json) {
    final locked = json['locked_root'];
    if (locked == null || locked == '' || json['can_change_path'] != false) {
      _retired = true;
      _fail(HermesManagedFilesFailure.unsupported);
    }
    final root = _path(locked);
    if (json['root'] != root || (_root != null && _root != root)) _malformed();
    _root ??= root;
    return root;
  }

  Future<T> _run<T>(Future<T> Function() action) async {
    _current();
    if (_busy) _fail(HermesManagedFilesFailure.failed);
    _busy = true;
    try {
      final result = await action();
      _current();
      return result;
    } on HermesManagedFilesException {
      if (!_isCurrent()) _fail(HermesManagedFilesFailure.stale);
      rethrow;
    } catch (_) {
      _current();
      _fail(HermesManagedFilesFailure.failed);
    } finally {
      _busy = false;
    }
  }

  Future<HermesManagedDirectory> list([String? path]) => _run(() async {
    if (path != null && (!_directories.contains(path) || !_inside(path))) {
      _fail(HermesManagedFilesFailure.denied);
    }
    final json = await _request(
      '/api/files',
      path == null ? {} : {'path': path},
      512 * 1024,
    );
    _current();
    final root = _policy(json);
    final actual = _path(json['path']);
    if (!_inside(actual) || actual != (path ?? root)) _malformed();
    final parent = json['parent'];
    if (actual == root
        ? parent != null
        : parent != actual.substring(0, actual.lastIndexOf('/'))) {
      _malformed();
    }
    if (parent != null && !_inside(_path(parent))) _malformed();
    final rows = json['entries'];
    if (rows is! List) _malformed();
    if (rows.length > maximumEntries) {
      _fail(HermesManagedFilesFailure.oversized);
    }
    final entries = <HermesManagedFileEntry>[];
    final names = <String>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) _malformed();
      final name = row['name'],
          directory = row['is_directory'],
          size = row['size'];
      if (name is! String ||
          name.isEmpty ||
          name.length > 255 ||
          name == '.' ||
          name == '..' ||
          name.contains(RegExp(r'[/\\\x00-\x1f\x7f]')) ||
          directory is! bool ||
          (size != null && (size is! int || size < 0))) {
        _malformed();
      }
      // Broken links have no readable target; the server may preserve a placeholder.
      if (row['broken_link'] == true) continue;
      final target = _path(row['path']);
      if (!_inside(target) || !names.add(name)) {
        _malformed();
      }
      entries.add(
        HermesManagedFileEntry._(name, target, directory, size as int?),
      );
    }
    _current();
    // Retain only this bounded page's handles, not a shadow navigation inventory.
    _directories.clear();
    _directories.addAll([
      actual,
      if (parent is String) parent,
      ...entries.where((e) => e.isDirectory).map((e) => e.path),
    ]);
    _entries = List.unmodifiable(entries);
    return HermesManagedDirectory._(root, actual, parent as String?, _entries);
  });

  Future<Uint8List> download(
    HermesManagedFileEntry entry,
    HermesManagedFileTransfer transfer,
  ) => _run(() async {
    transfer.check();
    if (!canDownload ||
        !_entries.contains(entry) ||
        entry.isDirectory ||
        !_inside(entry.path)) {
      _fail(HermesManagedFilesFailure.denied);
    }
    if ((entry.size ?? 0) > maximumDownloadBytes) {
      _fail(HermesManagedFilesFailure.oversized);
    }
    final bytes = await _download!(entry.path, transfer);
    transfer.check();
    _current();
    if (bytes.length > maximumDownloadBytes) {
      _fail(HermesManagedFilesFailure.oversized);
    }
    return bytes;
  });

  Future<String> read(HermesManagedFileEntry entry) => _run(() async {
    if (!_entries.contains(entry) ||
        entry.isDirectory ||
        !_inside(entry.path)) {
      _fail(HermesManagedFilesFailure.denied);
    }
    if (entry.size != null && entry.size! > maximumPreviewBytes) {
      _fail(HermesManagedFilesFailure.oversized);
    }
    final json = await _request('/api/files/read', {
      'path': entry.path,
    }, 128 * 1024);
    _current();
    _policy(json);
    // Managed listings name the alias, while reads name the canonical target.
    if (json['path'] != entry.path ||
        json['name'] != entry.path.split('/').last) {
      _malformed();
    }
    final size = json['size'],
        data = json['data_url'],
        mime = json['mime_type'];
    if (size is! int ||
        size < 0 ||
        data is! String ||
        mime is! String ||
        mime.length > 256) {
      _malformed();
    }
    if (size > maximumPreviewBytes) _fail(HermesManagedFilesFailure.oversized);
    final prefix = 'data:$mime;base64,';
    if (!data.startsWith(prefix) ||
        data.length > prefix.length + ((maximumPreviewBytes + 2) ~/ 3) * 4) {
      _malformed();
    }
    List<int> bytes;
    try {
      bytes = base64Decode(data.substring(prefix.length));
    } on FormatException {
      return _malformed();
    }
    if (bytes.length != size) _malformed();
    if (bytes.any((b) => b == 0 || (b < 32 && b != 9 && b != 10 && b != 13))) {
      _fail(HermesManagedFilesFailure.binary);
    }
    try {
      return utf8.decode(bytes);
    } on FormatException {
      _fail(HermesManagedFilesFailure.binary);
    }
  });
}
