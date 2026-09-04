import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/wing_link/models/wing_link_directory.dart';
import '../../../l10n/app_localizations.dart';

typedef DirectoryRootsLoader = Future<List<WingLinkDirectory>> Function();
typedef ChildDirectoriesLoader =
    Future<WingLinkDirectoryPage> Function(String handle, int offset);

Future<void> showProfileDirectoryBrowser(
  BuildContext context, {
  required DirectoryRootsLoader loadRoots,
  required ChildDirectoriesLoader loadChildren,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.8,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: _ProfileDirectoryBrowserSheet(
            loadRoots: loadRoots,
            loadChildren: loadChildren,
          ),
        ),
      ),
    ),
  );
}

class _DirectoryLevel {
  _DirectoryLevel({
    required this.name,
    required this.directories,
    this.parentHandle,
    this.nextOffset,
  });

  final String name;
  final String? parentHandle;
  List<WingLinkDirectory> directories;
  int? nextOffset;
}

class _ProfileDirectoryBrowserSheet extends StatefulWidget {
  const _ProfileDirectoryBrowserSheet({
    required this.loadRoots,
    required this.loadChildren,
  });

  final DirectoryRootsLoader loadRoots;
  final ChildDirectoriesLoader loadChildren;

  @override
  State<_ProfileDirectoryBrowserSheet> createState() =>
      _ProfileDirectoryBrowserSheetState();
}

class _ProfileDirectoryBrowserSheetState
    extends State<_ProfileDirectoryBrowserSheet> {
  final List<_DirectoryLevel> _levels = [];
  bool _loading = true;
  bool _recoveryAttempted = false;
  bool _failed = false;

  _DirectoryLevel? get _current => _levels.isEmpty ? null : _levels.last;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRoots());
  }

  Future<void> _loadRoots() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final roots = await widget.loadRoots();
      if (!mounted) return;
      setState(() {
        _levels
          ..clear()
          ..add(_DirectoryLevel(name: '', directories: List.of(roots)));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _levels.clear();
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _open(WingLinkDirectory directory) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await widget.loadChildren(directory.handle, 0);
      if (!mounted) return;
      setState(() {
        _levels.add(
          _DirectoryLevel(
            name: directory.name,
            parentHandle: directory.handle,
            directories: List.of(page.directories),
            nextOffset: page.nextOffset,
          ),
        );
        _loading = false;
      });
    } catch (_) {
      await _recoverOrFail();
    }
  }

  Future<void> _loadMore() async {
    final level = _current;
    final handle = level?.parentHandle;
    final offset = level?.nextOffset;
    if (level == null || handle == null || offset == null) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await widget.loadChildren(handle, offset);
      if (!mounted || _current != level) return;
      setState(() {
        level.directories = [...level.directories, ...page.directories];
        level.nextOffset = page.nextOffset;
        _loading = false;
      });
    } catch (_) {
      await _recoverOrFail();
    }
  }

  Future<void> _recoverOrFail() async {
    if (!_recoveryAttempted) {
      _recoveryAttempted = true;
      if (mounted) {
        setState(() {
          _levels.clear();
          _loading = true;
          _failed = false;
        });
      }
      await _loadRoots();
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = true;
    });
  }

  void _back() {
    if (_levels.length <= 1) return;
    setState(() {
      _levels.removeLast();
      _failed = false;
    });
  }

  Future<void> _retry() async {
    _recoveryAttempted = false;
    await _loadRoots();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current = _current;
    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    current?.name.isNotEmpty == true
                        ? current!.name
                        : strings.directoryBrowserTitle,
                    style: theme.textTheme.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: strings.closeAction,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody(context, strings, current)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (_levels.length > 1)
                  OutlinedButton.icon(
                    key: const ValueKey('directory-browser-back'),
                    onPressed: _loading ? null : _back,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(strings.directoryBrowserBackAction),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(strings.closeAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations strings,
    _DirectoryLevel? current,
  ) {
    if (_loading) {
      return Semantics(
        liveRegion: true,
        label: strings.directoryBrowserLoading,
        child: Center(
          key: const ValueKey('directory-browser-loading'),
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (_failed) {
      return Semantics(
        liveRegion: true,
        label: strings.directoryBrowserError,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.folder_off_outlined, size: 40),
                const SizedBox(height: 12),
                Text(
                  strings.directoryBrowserError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('directory-browser-retry'),
                  onPressed: () => unawaited(_retry()),
                  icon: const Icon(Icons.refresh),
                  label: Text(strings.retryAction),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final directories = current?.directories ?? const <WingLinkDirectory>[];
    if (directories.isEmpty && current?.nextOffset == null) {
      return ListView(
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.folder_open_outlined, size: 40),
          const SizedBox(height: 12),
          Text(
            strings.directoryBrowserEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SelectableText(
            strings.directoryBrowserEmptyBody,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            strings.directoryBrowserProjectUnavailable,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return ListView(
      children: [
        for (final directory in directories)
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(directory.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => unawaited(_open(directory)),
          ),
        if (current?.nextOffset != null)
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              key: const ValueKey('directory-browser-load-more'),
              onPressed: () => unawaited(_loadMore()),
              icon: const Icon(Icons.expand_more),
              label: Text(strings.directoryBrowserLoadMoreAction),
            ),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            strings.directoryBrowserProjectUnavailable,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
