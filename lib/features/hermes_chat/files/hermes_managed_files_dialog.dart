import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../core/hermes/client/hermes_managed_files.dart';
import '../../../l10n/app_localizations.dart';

/// Explicit reads only. No file content or host paths enter Chat state, caches,
/// persistence or diagnostics; replacing the owner discards the volatile view.
class HermesManagedFilesDialog extends StatefulWidget {
  const HermesManagedFilesDialog({
    super.key,
    required this.channel,
    this.opening,
  });
  final HermesChannel channel;

  /// The invocation's lease and provider identity, captured before route building.
  final ({HermesChannel channel, HermesManagedFilesSession? files})? opening;
  @override
  State<HermesManagedFilesDialog> createState() =>
      _HermesManagedFilesDialogState();
}

class _HermesManagedFilesDialogState extends State<HermesManagedFilesDialog> {
  HermesManagedFilesSession? _files;
  HermesManagedDirectory? _directory;
  HermesManagedFilesFailure? _failure;
  String? _text, _name;
  bool _loading = false;
  int _operation = 0;
  final _parentFocus = FocusNode(), _backFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.channel.addListener(_ownerChanged);
    final opening = widget.opening;
    if (opening == null) {
      _open();
    } else if (!identical(opening.channel, widget.channel) ||
        opening.files?.isCurrent == false) {
      _failure = HermesManagedFilesFailure.stale;
    } else if (opening.files == null) {
      _failure = HermesManagedFilesFailure.unsupported;
    } else {
      final files = _files = opening.files!;
      unawaited(_load(files, () => files.list()));
    }
  }

  @override
  void didUpdateWidget(covariant HermesManagedFilesDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.channel, widget.channel)) return;
    oldWidget.channel.removeListener(_ownerChanged);
    widget.channel.addListener(_ownerChanged);
    _operation++;
    _files = null;
    _directory = null;
    _text = _name = null;
    _loading = false;
    _failure = HermesManagedFilesFailure.stale;
  }

  @override
  void dispose() {
    _operation++;
    widget.channel.removeListener(_ownerChanged);
    _parentFocus.dispose();
    _backFocus.dispose();
    super.dispose();
  }

  void _ownerChanged() {
    if (_files == null || _files!.isCurrent) return;
    _operation++;
    setState(() {
      _files = null;
      _directory = null;
      _text = _name = null;
      _loading = false;
      _failure = HermesManagedFilesFailure.stale;
    });
  }

  void _open() {
    if (_loading) return;
    final Object channel = widget.channel;
    if (channel is! HermesManagedFilesChannel ||
        !channel.canBrowseManagedFiles) {
      setState(() => _failure = HermesManagedFilesFailure.unsupported);
      return;
    }
    try {
      _files = channel.beginManagedFiles();
      final files = _files!;
      unawaited(_load(files, () => files.list()));
    } catch (_) {
      setState(() => _failure = HermesManagedFilesFailure.unsupported);
    }
  }

  Future<void> _load(
    HermesManagedFilesSession files,
    Future<Object> Function() read, {
    String? name,
    int? expectedOperation,
  }) async {
    if (expectedOperation != null && expectedOperation != _operation) return;
    if (!identical(files, _files) || !files.isCurrent || _loading) {
      _ownerChanged();
      return;
    }
    final operation = ++_operation;
    setState(() {
      _loading = true;
      _failure = null;
      _text = _name = null;
    });
    try {
      final result = await read();
      if (!mounted || operation != _operation) return;
      if (!identical(files, _files) || !files.isCurrent) {
        _ownerChanged();
        return;
      }
      setState(() {
        if (result is HermesManagedDirectory) _directory = result;
        if (result is String) {
          _text = result;
          _name = name;
        }
      });
    } on HermesManagedFilesException catch (error) {
      if (!mounted || operation != _operation) return;
      setState(() {
        _directory = null;
        _failure = error.kind;
      });
    } catch (_) {
      if (!mounted || operation != _operation) return;
      setState(() {
        _directory = null;
        _failure = HermesManagedFilesFailure.failed;
      });
    } finally {
      if (mounted && operation == _operation) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = widget.channel.state;
    final files = _files;
    final renderedOperation = _operation;
    final directory = _directory;
    final failure = _failure;
    final preview = _text != null;
    final entries = !_loading && failure == null && !preview
        ? directory?.entries
        : null;
    final message = switch (failure) {
      HermesManagedFilesFailure.unsupported ||
      HermesManagedFilesFailure.malformed => strings.managedFilesUnavailable,
      HermesManagedFilesFailure.denied => strings.managedFilesDenied,
      HermesManagedFilesFailure.oversized => strings.managedFilesOversized,
      HermesManagedFilesFailure.binary => strings.managedFilesBinary,
      HermesManagedFilesFailure.stale => strings.managedFilesStale,
      _ => strings.managedFilesFailed,
    };
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 760,
        height: MediaQuery.sizeOf(context).height * .85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 20,
                end: 8,
                top: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.managedFilesTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.closeAction,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 1 + (entries?.length ?? 0),
                itemBuilder: (context, index) {
                  if (index > 0) {
                    final entry = entries![index - 1];
                    return ListTile(
                      leading: Icon(
                        entry.isDirectory
                            ? Icons.folder_outlined
                            : Icons.description_outlined,
                      ),
                      title: Text(entry.name),
                      onTap: () {
                        if (files == null) return;
                        if (entry.isDirectory) {
                          unawaited(
                            _load(
                              files,
                              () => files.list(entry.path),
                              expectedOperation: renderedOperation,
                            ),
                          );
                        } else {
                          unawaited(
                            _load(
                              files,
                              () => files.read(entry),
                              name: entry.name,
                              expectedOperation: renderedOperation,
                            ),
                          );
                        }
                      },
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(strings.managedFilesExplanation),
                      const SizedBox(height: 12),
                      Text(
                        strings.managedFilesOwner(
                          state.connectedBaseUrl ??
                              strings.managedFilesNoSelection,
                          state.selectedProfileId ??
                              strings.managedFilesNoSelection,
                          state.activeSessionId ??
                              strings.managedFilesNoSelection,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (directory != null && failure == null) ...[
                        const SizedBox(height: 12),
                        SelectableText(directory.root),
                        if (directory.path != directory.root)
                          SelectableText(directory.path),
                      ],
                      if (!_loading && failure == null && directory != null)
                        Row(
                          children: [
                            if (preview)
                              IconButton(
                                focusNode: _backFocus,
                                tooltip: strings.managedFilesBack,
                                onPressed: () {
                                  if (renderedOperation == _operation &&
                                      identical(files, _files) &&
                                      files?.isCurrent == true) {
                                    setState(() {
                                      _text = _name = null;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.arrow_back),
                              )
                            else if (directory.parent != null)
                              IconButton(
                                focusNode: _parentFocus,
                                tooltip: strings.managedFilesParent,
                                onPressed: () => unawaited(
                                  _load(
                                    files!,
                                    () => files.list(directory.parent),
                                    expectedOperation: renderedOperation,
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                            IconButton(
                              tooltip: strings.managedFilesRefresh,
                              onPressed: () => unawaited(
                                _load(
                                  files!,
                                  () => files.list(directory.path),
                                  expectedOperation: renderedOperation,
                                ),
                              ),
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      if (_loading)
                        Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: strings.managedFilesLoading,
                          ),
                        ),
                      if (failure != null) ...[
                        const SizedBox(height: 16),
                        Semantics(liveRegion: true, child: Text(message)),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () {
                              if (renderedOperation == _operation) _open();
                            },
                            child: Text(strings.retryAction),
                          ),
                        ),
                      ],
                      if (preview && !_loading && failure == null) ...[
                        if (_name != null)
                          Text(
                            _name!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        SelectableText(_text!),
                      ],
                      if (entries?.isEmpty == true)
                        Text(strings.managedFilesEmpty),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
