import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';

typedef ProfileCreateCallback =
    Future<void> Function({
      required String name,
      String? cloneFrom,
      String? description,
      String? provider,
      String? model,
      String? providerApiKey,
    });
typedef ProfileRenameCallback =
    Future<void> Function({
      required String profileId,
      required String name,
      required String revision,
    });
typedef ProfileDeleteCallback =
    Future<void> Function(String profileId, String revision);

class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({
    required this.channel,
    required this.profiles,
    this.profile,
    this.canEditSoul = false,
    this.canDelete = false,
    this.stableNames = false,
    this.canConfigure = false,
    this.onCreate,
    this.onRename,
    this.onDelete,
    super.key,
  });

  final HermesChannel channel;
  final List<HermesProfile> profiles;
  final HermesProfile? profile;
  final bool canEditSoul;
  final bool canDelete;
  final bool stableNames;
  final bool canConfigure;
  final ProfileCreateCallback? onCreate;
  final ProfileRenameCallback? onRename;
  final ProfileDeleteCallback? onDelete;

  @override
  State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _personaController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _providerController = TextEditingController();
  final _modelController = TextEditingController();
  final _credentialController = TextEditingController();
  String? _cloneFrom;
  String? _personaRevision;
  String _originalPersona = '';
  String? _error;
  bool _saving = false;
  bool _loadingPersona = false;

  bool get _editing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.stableNames
          ? widget.profile?.id ?? ''
          : widget.profile?.displayName ?? '',
    );
    if (!_editing) {
      _cloneFrom = widget.profiles.any((profile) => profile.id == 'default')
          ? 'default'
          : widget.profiles.firstOrNull?.id;
    } else if (widget.canEditSoul) {
      _loadPersona();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _personaController.dispose();
    _descriptionController.dispose();
    _providerController.dispose();
    _modelController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  Future<void> _loadPersona() async {
    setState(() => _loadingPersona = true);
    try {
      final soul = await widget.channel.readProfileSoul(widget.profile!.id);
      if (!mounted) return;
      _personaController.text = soul.soul;
      _originalPersona = soul.soul;
      _personaRevision = soul.revision;
    } catch (_) {
      if (!mounted) return;
      _error = AppLocalizations.of(context).profileOperationFailed;
    } finally {
      if (mounted) setState(() => _loadingPersona = false);
    }
  }

  Future<void> _deleteProfile() async {
    final profile = widget.profile;
    if (profile == null || profile.id == 'default') return;
    final strings = AppLocalizations.of(context);
    final expectedName = profile.displayName.isEmpty
        ? profile.id
        : profile.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeleteConfirmationDialog(
        expectedName: expectedName,
        strings: strings,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final onDelete = widget.onDelete;
      if (onDelete == null) {
        await widget.channel.deleteProfile(
          profileId: profile.id,
          revision: profile.revision,
        );
      } else {
        await onDelete(profile.id, profile.revision);
      }
      if (mounted) await Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().contains('412')
            ? strings.profileRevisionConflict
            : strings.profileOperationFailed;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _nameController.text.trim();
      final profile = widget.profile;
      if (profile == null) {
        final onCreate = widget.onCreate;
        if (onCreate == null) {
          await widget.channel.createProfile(name: name, cloneFrom: _cloneFrom);
        } else {
          await onCreate(
            name: name,
            cloneFrom: _cloneFrom,
            description: _descriptionController.text.trim(),
            provider: _providerController.text.trim(),
            model: _modelController.text.trim(),
            providerApiKey: _credentialController.text.isEmpty
                ? null
                : _credentialController.text,
          );
        }
      } else {
        final currentName = widget.stableNames
            ? profile.id
            : profile.displayName;
        final hasConfigurationChange =
            widget.canConfigure &&
            (_descriptionController.text.trim().isNotEmpty ||
                _providerController.text.trim().isNotEmpty ||
                _modelController.text.trim().isNotEmpty ||
                _credentialController.text.isNotEmpty);
        if (name != currentName || hasConfigurationChange) {
          final onRename = widget.onRename;
          if (onRename == null) {
            await widget.channel.renameProfile(
              profileId: profile.id,
              name: name,
              revision: profile.revision,
            );
          } else {
            await onRename(
              profileId: profile.id,
              name: name,
              revision: profile.revision,
            );
          }
        }
        final personaRevision = _personaRevision;
        if (widget.canEditSoul &&
            personaRevision != null &&
            _personaController.text != _originalPersona) {
          await widget.channel.writeProfileSoul(
            profileId: widget.stableNames && name != currentName
                ? name
                : profile.id,
            soul: _personaController.text,
            revision: personaRevision,
          );
        }
      }
      if (mounted) await Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      setState(() {
        _error = error.toString().contains('412')
            ? strings.profileRevisionConflict
            : strings.profileOperationFailed;
      });
    } finally {
      _credentialController.clear();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final profile = widget.profile;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile == null ? strings.createAgentTitle : strings.editAgent,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (profile != null) ...[
                const SizedBox(height: 6),
                Text(strings.agentStableId(profile.id)),
              ],
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: strings.agentDisplayName,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return strings.agentNameRequired;
                  if (widget.stableNames &&
                      !RegExp(r'^[a-z0-9][a-z0-9_-]{0,63}$').hasMatch(name)) {
                    return strings.profileStableNameHint;
                  }
                  return null;
                },
              ),
              if (profile == null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _cloneFrom,
                  decoration: InputDecoration(
                    labelText: strings.cloneFromAgent,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(strings.startFresh),
                    ),
                    for (final candidate in widget.profiles)
                      DropdownMenuItem<String?>(
                        value: candidate.id,
                        child: Text(
                          candidate.displayName.isEmpty
                              ? candidate.id
                              : candidate.displayName,
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _cloneFrom = value),
                ),
                if (widget.canConfigure) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: strings.profileDescriptionLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _providerController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: strings.profileProviderLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final provider = value?.trim() ?? '';
                      if (!_editing && provider.isEmpty) {
                        return strings.profileProviderRequired;
                      }
                      if (_editing &&
                          provider.isEmpty &&
                          _modelController.text.trim().isNotEmpty) {
                        return strings.profileProviderRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modelController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: strings.profileModelLabel,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final model = value?.trim() ?? '';
                      if (!_editing && model.isEmpty) {
                        return strings.profileModelRequired;
                      }
                      if (_editing &&
                          model.isEmpty &&
                          _providerController.text.trim().isNotEmpty) {
                        return strings.profileModelRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(strings.profileReadinessNotice),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _credentialController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const <String>[],
                    decoration: InputDecoration(
                      labelText: strings.profileCredentialLabel,
                      helperText: strings.profileCredentialHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
              if (profile != null && widget.canConfigure) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: strings.profileDescriptionLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _providerController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.profileProviderLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final provider = value?.trim() ?? '';
                    if (provider.isEmpty &&
                        _modelController.text.trim().isNotEmpty) {
                      return strings.profileProviderRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: strings.profileModelLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final model = value?.trim() ?? '';
                    if (model.isEmpty &&
                        _providerController.text.trim().isNotEmpty) {
                      return strings.profileModelRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(strings.profileReadinessNotice),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _credentialController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const <String>[],
                  decoration: InputDecoration(
                    labelText: strings.profileCredentialLabel,
                    helperText: strings.profileCredentialHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              if (profile != null && widget.canEditSoul) ...[
                const SizedBox(height: 16),
                if (_loadingPersona)
                  const LinearProgressIndicator()
                else
                  TextFormField(
                    controller: _personaController,
                    minLines: 5,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: strings.personaLabel,
                      helperText: strings.personaHint,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
              ],
              if (profile != null &&
                  widget.canDelete &&
                  profile.id != 'default') ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: _saving ? null : _deleteProfile,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings.deleteAgent),
                ),
              ],
              if (profile != null && profile.id == 'default') ...[
                const SizedBox(height: 16),
                Text(strings.defaultAgentCannotDelete),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: Text(strings.cancelAction),
                  ),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            profile == null
                                ? strings.createAction
                                : strings.saveAction,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// High-emphasis destructive confirmation that requires the operator to type
/// the agent's display name before the delete action is enabled. Owns its own
/// [TextEditingController] so it is disposed only after the dialog is fully
/// gone from the tree (a synchronous dispose after `showDialog` returns races
/// the exit transition).
class _DeleteConfirmationDialog extends StatefulWidget {
  const _DeleteConfirmationDialog({
    required this.expectedName,
    required this.strings,
  });

  final String expectedName;
  final AppLocalizations strings;

  @override
  State<_DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final theme = Theme.of(context);
    final matches = _controller.text.trim() == widget.expectedName;
    return AlertDialog(
      title: Text(strings.deleteAgentTitle(widget.expectedName)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.deleteAgentBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: strings.deleteConfirmationLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancelAction),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: matches ? () => Navigator.of(context).pop(true) : null,
          icon: const Icon(Icons.delete_outline),
          label: Text(strings.deleteAgent),
        ),
      ],
    );
  }
}
