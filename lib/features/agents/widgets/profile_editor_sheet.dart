import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import '../../../l10n/app_localizations.dart';

class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({
    required this.channel,
    required this.profiles,
    this.profile,
    this.canEditSoul = false,
    this.canDelete = false,
    super.key,
  });

  final HermesChannel channel;
  final List<HermesProfile> profiles;
  final HermesProfile? profile;
  final bool canEditSoul;
  final bool canDelete;

  @override
  State<ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<ProfileEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _personaController = TextEditingController();
  String? _cloneFrom;
  String? _personaRevision;
  String? _error;
  bool _saving = false;
  bool _loadingPersona = false;

  bool get _editing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile?.displayName ?? '',
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
    super.dispose();
  }

  Future<void> _loadPersona() async {
    setState(() => _loadingPersona = true);
    try {
      final soul = await widget.channel.readProfileSoul(widget.profile!.id);
      if (!mounted) return;
      _personaController.text = soul.soul;
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
      await widget.channel.deleteProfile(
        profileId: profile.id,
        revision: profile.revision,
      );
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
        await widget.channel.createProfile(name: name, cloneFrom: _cloneFrom);
      } else {
        if (name != profile.displayName) {
          await widget.channel.renameProfile(
            profileId: profile.id,
            name: name,
            revision: profile.revision,
          );
        }
        final personaRevision = _personaRevision;
        if (widget.canEditSoul && personaRevision != null) {
          await widget.channel.writeProfileSoul(
            profileId: profile.id,
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? strings.agentNameRequired
                    : null,
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
