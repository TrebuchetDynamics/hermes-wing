import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/hermes/channel/hermes_channel.dart';
import 'catalog_autocomplete_field.dart';
import '../../../core/hermes/shared/hermes_api_http.dart';
import '../../../core/wing_link/wing_link_client.dart';
import '../../../l10n/app_localizations.dart';

typedef ProfileCreateCallback =
    Future<void> Function({
      required String name,
      String? cloneFrom,
      String? description,
      String? provider,
      String? model,
      String? providerApiKey,
      String? idempotencyKey,
    });
typedef _PendingProfileApproval = ({
  String approvalId,
  String idempotencyKey,
  int expiresAt,
});

typedef ProfileRenameCallback =
    Future<void> Function({
      required String profileId,
      required String name,
      required String revision,
    });
typedef ProfileDeleteCallback =
    Future<void> Function(
      String profileId,
      String revision, {
      String? idempotencyKey,
    });

class ProfileEditorSheet extends StatefulWidget {
  const ProfileEditorSheet({
    required this.channel,
    required this.profiles,
    this.profile,
    this.canEditSoul = false,
    this.canDelete = false,
    this.stableNames = false,
    this.canConfigure = false,
    this.soulOnly = false,
    this.loadModelOptions,

    this.onCreate,
    this.onRename,
    this.onDelete,
    this.ownerChanges,
    this.isOwnerCurrent,
    this.onCancel,
    this.onSaved,
    super.key,
  });

  final HermesChannel channel;
  final List<HermesProfile> profiles;
  final HermesProfile? profile;
  final bool canEditSoul;
  final bool canDelete;
  final bool stableNames;
  final bool canConfigure;
  final bool soulOnly;
  final Future<HermesModelOptions> Function(String profileId)? loadModelOptions;

  final ProfileCreateCallback? onCreate;
  final ProfileRenameCallback? onRename;
  final ProfileDeleteCallback? onDelete;

  // A modal's management source can change independently of its channel.
  final Listenable? ownerChanges;
  final bool Function()? isOwnerCurrent;
  final VoidCallback? onCancel;
  final VoidCallback? onSaved;

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
  HermesModelOptions? _modelOptions;

  bool _loadingModels = false;
  bool _catalogFailed = false;
  int _catalogGeneration = 0;
  bool _saving = false;
  bool _loadingPersona = false;
  _PendingProfileApproval? _pendingApproval;
  Timer? _approvalExpiryTimer;

  Object? _personaSource;
  Object _personaOwner = Object();
  int _personaReadGeneration = 0;

  Object? _mutationSource;
  Object _mutationOwner = Object();
  bool _mutationObsolete = false;

  void _observeMutationOwner() {
    if (!_editing) return;
    final source = (
      widget.channel,
      widget.channel.state.connectedBaseUrl,
      widget.profile?.id,
      widget.profile?.revision,
      widget.onRename,
      widget.onDelete,
      widget.isOwnerCurrent?.call() ?? true,
    );
    if (source == _mutationSource) return;
    _mutationSource = source;
    _mutationOwner = Object();
    _mutationObsolete = !(widget.isOwnerCurrent?.call() ?? true);
    _clearPendingApproval();
    _saving = false;
    _error = null;
  }

  bool _ownsMutation(Object owner) {
    if (!mounted) return false;
    _observeMutationOwner();
    return identical(owner, _mutationOwner) && !_mutationObsolete;
  }

  bool get _personaEligible =>
      widget.profile != null &&
      widget.canEditSoul &&
      widget.channel.state.canEditProfileSoul &&
      (widget.isOwnerCurrent?.call() ?? true);

  void _observePersonaOwner() {
    if (!widget.canEditSoul && _personaSource == null) return;
    final state = widget.channel.state;
    final source = (
      widget.channel,
      state.connectedBaseUrl,
      state.selectedProfileId,
      state.isConnected,
      state.isSelectingProfile,
      widget.profile?.id,
      _personaEligible,
    );
    if (source == _personaSource) return;
    _personaSource = source;
    _personaOwner = Object();
    ++_personaReadGeneration;
    _personaController.clear();
    _personaRevision = null;
    _originalPersona = '';
    _error = null;
    _loadingPersona = false;
    _saving = false;
    _nameController.text = widget.stableNames
        ? widget.profile?.id ?? ''
        : widget.profile?.displayName ?? '';
    final owner = _personaOwner;
    if (_personaEligible) {
      _loadingPersona = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_ownsPersona(owner)) unawaited(_loadPersona());
      });
    }
  }

  void _personaOwnerChanged() {
    final previous = _personaOwner;
    final previousMutation = _mutationOwner;
    _observeMutationOwner();
    _observePersonaOwner();
    if (mounted &&
        (!identical(previous, _personaOwner) ||
            !identical(previousMutation, _mutationOwner))) {
      setState(() {});
    }
  }

  bool _ownsPersona(Object owner) {
    if (!mounted) return false;
    _observePersonaOwner();
    return identical(owner, _personaOwner) && _personaEligible;
  }

  bool get _editing => widget.profile != null;
  bool get _payloadFrozen =>
      _saving || _loadingPersona || _pendingApproval != null;

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
    }
    widget.channel.addListener(_personaOwnerChanged);
    widget.ownerChanges?.addListener(_personaOwnerChanged);
    _observeMutationOwner();
    _observePersonaOwner();
    if (widget.canConfigure) {
      unawaited(_loadCatalog());
    }
  }

  @override
  void didUpdateWidget(ProfileEditorSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.channel, widget.channel)) {
      oldWidget.channel.removeListener(_personaOwnerChanged);
      widget.channel.addListener(_personaOwnerChanged);
    }
    if (!identical(oldWidget.ownerChanges, widget.ownerChanges)) {
      oldWidget.ownerChanges?.removeListener(_personaOwnerChanged);
      widget.ownerChanges?.addListener(_personaOwnerChanged);
    }
    _observeMutationOwner();
    _observePersonaOwner();
  }

  @override
  void dispose() {
    widget.channel.removeListener(_personaOwnerChanged);
    widget.ownerChanges?.removeListener(_personaOwnerChanged);
    _approvalExpiryTimer?.cancel();
    _credentialController.clear();
    _nameController.dispose();
    _personaController.dispose();
    _descriptionController.dispose();
    _providerController.dispose();
    _modelController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final loader = widget.loadModelOptions;
    if (loader == null) return;
    final generation = ++_catalogGeneration;
    setState(() {
      _loadingModels = true;
      _catalogFailed = false;
      _modelOptions = null;
    });
    final profile =
        widget.profile?.id ??
        _cloneFrom ??
        (widget.profiles.any((row) => row.id == 'default')
            ? 'default'
            : widget.profiles.firstOrNull?.id);
    try {
      if (profile == null) throw StateError('No profile available');
      final options = await loader(profile);
      if (!mounted || generation != _catalogGeneration) return;
      setState(() => _modelOptions = options);
    } catch (_) {
      if (!mounted || generation != _catalogGeneration) return;
      setState(() => _catalogFailed = true);
    } finally {
      if (mounted && generation == _catalogGeneration) {
        setState(() => _loadingModels = false);
      }
    }
  }

  List<String> get _providerOptions =>
      _modelOptions?.providers.map((row) => row.slug).toList() ?? const [];

  List<String> get _modelSuggestions =>
      _modelOptions?.providers
          .where((row) => row.slug == _providerController.text.trim())
          .expand((row) => row.models)
          .toSet()
          .toList() ??
      const [];

  void _providerChanged(String _) {
    _modelController.clear();
    setState(() {});
  }

  List<Widget> _catalogStatus(AppLocalizations strings) => [
    if (_loadingModels) ...[
      const LinearProgressIndicator(),
      Text(strings.profileCatalogLoading),
      const SizedBox(height: 12),
    ],
    if (_catalogFailed) ...[
      Text(strings.profileCatalogUnavailable),
      TextButton(
        onPressed: _payloadFrozen ? null : _loadCatalog,
        child: Text(strings.profileCatalogRetry),
      ),
    ],
  ];

  Future<void> _loadPersona() async {
    final owner = _personaOwner;
    if (!_ownsPersona(owner)) return;
    final channel = widget.channel;
    final profileId = widget.profile!.id;
    final generation = ++_personaReadGeneration;
    setState(() {
      _loadingPersona = true;
      _personaRevision = null;
      _personaController.clear();
      _originalPersona = '';
      _error = null;
    });
    bool current() =>
        _ownsPersona(owner) && generation == _personaReadGeneration;
    try {
      final soul = await channel.readProfileSoul(profileId);
      if (!current()) return;
      if (soul.revision.trim().isEmpty) throw StateError('Missing revision');
      _personaController.text = soul.soul;
      _originalPersona = soul.soul;
      _personaRevision = soul.revision;
    } catch (_) {
      if (!mounted || !current()) return;
      _error = AppLocalizations.of(context).profileOperationFailed;
    } finally {
      if (current()) setState(() => _loadingPersona = false);
    }
  }

  Future<void> _deleteProfile() async {
    _observeMutationOwner();
    final owner = _mutationOwner;
    if (!_ownsMutation(owner)) return;
    final profile = widget.profile;
    if (profile == null || profile.id == 'default' || _saving) return;
    final pendingApproval = _pendingApproval;
    if (pendingApproval != null && _approvalExpired(pendingApproval)) {
      setState(() {
        _clearPendingApproval();
        _error = _editing
            ? AppLocalizations.of(context).profileDeletionApprovalExpired
            : AppLocalizations.of(context).profileApprovalExpired;
      });
      return;
    }
    final strings = AppLocalizations.of(context);
    final expectedName = profile.displayName.isEmpty
        ? profile.id
        : profile.displayName;
    final confirmed = pendingApproval != null
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (dialogContext) => _DeleteConfirmationDialog(
              expectedName: expectedName,
              strings: strings,
            ),
          );
    if (confirmed != true || !_ownsMutation(owner)) return;

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
        await onDelete(
          profile.id,
          profile.revision,
          idempotencyKey: pendingApproval?.idempotencyKey,
        );
      }
      if (!_ownsMutation(owner)) return;
      _clearPendingApproval();
      if (mounted) await Navigator.of(context).maybePop();
    } on WingLinkApprovalRequired catch (approval) {
      if (!_ownsMutation(owner)) return;
      setState(() {
        if (pendingApproval != null &&
            approval.idempotencyKey != pendingApproval.idempotencyKey) {
          _clearPendingApproval();
          _error = strings.profileOperationFailed;
        } else {
          _holdPendingApproval(approval);
        }
      });
    } catch (error) {
      if (!_ownsMutation(owner)) return;
      setState(() {
        _clearPendingApproval();
        _error = _isProfileRevisionConflict(error)
            ? strings.profileRevisionConflict
            : strings.profileOperationFailed;
      });
    } finally {
      if (_ownsMutation(owner)) setState(() => _saving = false);
    }
  }

  bool _approvalExpired(_PendingProfileApproval approval) =>
      DateTime.now().millisecondsSinceEpoch >= approval.expiresAt * 1000;

  void _clearPendingApproval({bool clearCredential = true}) {
    _approvalExpiryTimer?.cancel();
    _approvalExpiryTimer = null;
    _pendingApproval = null;
    if (clearCredential) _credentialController.clear();
  }

  void _holdPendingApproval(WingLinkApprovalRequired approval) {
    _approvalExpiryTimer?.cancel();
    _pendingApproval = (
      approvalId: approval.approvalId,
      idempotencyKey: approval.idempotencyKey,
      expiresAt: approval.expiresAt,
    );
    final delay = DateTime.fromMillisecondsSinceEpoch(
      approval.expiresAt * 1000,
    ).difference(DateTime.now());
    _approvalExpiryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (!mounted ||
          _pendingApproval?.idempotencyKey != approval.idempotencyKey) {
        return;
      }
      setState(() {
        _clearPendingApproval();
        _error = _editing
            ? AppLocalizations.of(context).profileDeletionApprovalExpired
            : AppLocalizations.of(context).profileApprovalExpired;
      });
    });
  }

  void _cancelEditor() {
    setState(() => _clearPendingApproval());
    final onCancel = widget.onCancel;
    if (onCancel != null) {
      onCancel();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _save() async {
    _observeMutationOwner();
    final mutationOwner = _mutationOwner;
    if (_editing && !_ownsMutation(mutationOwner)) return;
    _observePersonaOwner();
    if (_loadingPersona || _saving) return;
    if (widget.canEditSoul && (!_personaEligible || _personaRevision == null)) {
      return;
    }
    if (!(widget.isOwnerCurrent?.call() ?? true)) return;
    final owner = _personaOwner;
    final channel = widget.channel;
    final profile = widget.profile;
    final persona = _personaController.text;
    final personaRevision = _personaRevision;
    final originalPersona = _originalPersona;
    final editSoul = widget.canEditSoul;
    final stableNames = widget.stableNames;
    final onRename = widget.onRename;
    bool current() =>
        mounted &&
        (profile == null || _ownsMutation(mutationOwner)) &&
        (widget.isOwnerCurrent?.call() ?? true) &&
        (!editSoul || _ownsPersona(owner));
    if (_editing && _pendingApproval != null) return _deleteProfile();
    final pendingApproval = _pendingApproval;
    if (pendingApproval != null && _approvalExpired(pendingApproval)) {
      setState(() {
        _clearPendingApproval();
        _error = _editing
            ? AppLocalizations.of(context).profileDeletionApprovalExpired
            : AppLocalizations.of(context).profileApprovalExpired;
      });
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final name = _nameController.text.trim();
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
            idempotencyKey: pendingApproval?.idempotencyKey,
          );
        }
      } else {
        final currentName = stableNames ? profile.id : profile.displayName;
        final hasConfigurationChange =
            widget.canConfigure &&
            (_descriptionController.text.trim().isNotEmpty ||
                _providerController.text.trim().isNotEmpty ||
                _modelController.text.trim().isNotEmpty ||
                _credentialController.text.isNotEmpty);
        if (name != currentName || hasConfigurationChange) {
          if (onRename == null) {
            await channel.renameProfile(
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
        if (!current()) return;
        if (editSoul && personaRevision != null && persona != originalPersona) {
          await channel.writeProfileSoul(
            profileId: stableNames && name != currentName ? name : profile.id,
            soul: persona,
            revision: personaRevision,
          );
        }
      }
      if (!mounted || !current()) return;
      _clearPendingApproval();
      final onSaved = widget.onSaved;
      if (onSaved != null) {
        onSaved();
      } else {
        await Navigator.of(context).maybePop();
      }
    } on WingLinkApprovalRequired catch (approval) {
      if (!current()) return;
      if (pendingApproval != null &&
          approval.idempotencyKey != pendingApproval.idempotencyKey) {
        setState(() {
          _clearPendingApproval();
          _error = AppLocalizations.of(context).profileOperationFailed;
        });
      } else {
        setState(() {
          _holdPendingApproval(approval);
          _error = null;
        });
      }
    } catch (error) {
      if (!current()) return;
      final conflict = _isProfileRevisionConflict(error);
      if (conflict && editSoul) {
        // A rejected SOUL write means the server has newer content. Reconcile
        // before showing the conflict so a retry cannot overwrite stale text.
        await _loadPersona();
      }
      if (!mounted || !current()) return;
      final strings = AppLocalizations.of(context);
      setState(() {
        _clearPendingApproval();
        _error = conflict
            ? strings.profileRevisionConflict
            : strings.profileOperationFailed;
      });
    } finally {
      if (current()) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final profile = widget.profile;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.hasBoundedHeight
                  ? constraints.maxHeight
                  : MediaQuery.sizeOf(context).height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile == null
                            ? strings.createAgentTitle
                            : widget.soulOnly
                            ? strings.profilePersonaTitle(profile.displayName)
                            : strings.editAgent,
                        style: widget.soulOnly
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 6),
                        Text(strings.agentStableId(profile.id)),
                      ],
                    ],
                  ),
                ),
                const Divider(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!widget.soulOnly) ...[
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              enabled: !_payloadFrozen && !_mutationObsolete,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: strings.agentDisplayName,
                                helperText: widget.stableNames
                                    ? strings.profileStableNameHint
                                    : null,
                                helperMaxLines: 3,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) {
                                  return strings.agentNameRequired;
                                }
                                if (widget.stableNames &&
                                    !RegExp(
                                      r'^[a-z0-9][a-z0-9_-]{0,63}$',
                                    ).hasMatch(name)) {
                                  return strings.profileStableNameHint;
                                }
                                return null;
                              },
                            ),
                          ],
                          if (profile == null) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String?>(
                              initialValue: _cloneFrom,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: strings.cloneFromAgent,
                                helperText: widget.canConfigure
                                    ? _cloneFrom == null
                                          ? strings.profileFreshSetupHint
                                          : strings.profileCloneSetupHint
                                    : null,
                                helperMaxLines: 4,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: _payloadFrozen
                                  ? null
                                  : (value) {
                                      setState(() => _cloneFrom = value);
                                      unawaited(_loadCatalog());
                                    },
                            ),
                            if (widget.canConfigure) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                enabled: !_payloadFrozen,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: strings.profileDescriptionLabel,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._catalogStatus(strings),
                              CatalogAutocompleteField(
                                controller: _providerController,
                                enabled: !_payloadFrozen,
                                options: _providerOptions,
                                searchLabels: {
                                  for (final row
                                      in _modelOptions?.providers ??
                                          <HermesModelOptionProvider>[])
                                    row.slug: row.label,
                                },
                                label: strings.profileProviderLabel,
                                onChanged: _providerChanged,
                                validator: (value) {
                                  final provider = value?.trim() ?? '';
                                  final needsExplicitConfiguration =
                                      _cloneFrom == null ||
                                      _modelController.text.trim().isNotEmpty ||
                                      _credentialController.text.isNotEmpty;
                                  if (provider.isEmpty &&
                                      needsExplicitConfiguration) {
                                    return strings.profileProviderRequired;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              CatalogAutocompleteField(
                                controller: _modelController,
                                enabled: !_payloadFrozen,
                                options: _modelSuggestions,
                                label: strings.profileModelLabel,
                                validator: (value) {
                                  final model = value?.trim() ?? '';
                                  final needsExplicitConfiguration =
                                      _cloneFrom == null ||
                                      _providerController.text
                                          .trim()
                                          .isNotEmpty ||
                                      _credentialController.text.isNotEmpty;
                                  if (model.isEmpty &&
                                      needsExplicitConfiguration) {
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
                                enabled: !_payloadFrozen,
                                obscureText: true,
                                autocorrect: false,
                                enableSuggestions: false,
                                autofillHints: const <String>[],
                                decoration: InputDecoration(
                                  labelText: strings.profileCredentialLabel,
                                  helperText: strings.profileCredentialHint,
                                  helperMaxLines: 4,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ],
                          if (profile != null && widget.canConfigure) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              enabled: !_payloadFrozen,
                              minLines: 2,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: strings.profileDescriptionLabel,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ..._catalogStatus(strings),
                            CatalogAutocompleteField(
                              controller: _providerController,
                              enabled: !_payloadFrozen,
                              options: _providerOptions,
                              searchLabels: {
                                for (final row
                                    in _modelOptions?.providers ??
                                        <HermesModelOptionProvider>[])
                                  row.slug: row.label,
                              },
                              label: strings.profileProviderLabel,
                              onChanged: _providerChanged,
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
                            CatalogAutocompleteField(
                              controller: _modelController,
                              enabled: !_payloadFrozen,
                              options: _modelSuggestions,
                              label: strings.profileModelLabel,
                              validator: (value) {
                                final model = value?.trim() ?? '';
                                if (model.isEmpty &&
                                    _providerController.text
                                        .trim()
                                        .isNotEmpty) {
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
                              enabled: !_payloadFrozen,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const <String>[],
                              decoration: InputDecoration(
                                labelText: strings.profileCredentialLabel,
                                helperText: strings.profileCredentialHint,
                                helperMaxLines: 4,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                          if (profile != null && widget.canEditSoul) ...[
                            const SizedBox(height: 16),
                            if (_loadingPersona)
                              Semantics(
                                liveRegion: true,
                                label: strings.personaLoading,
                                child: const LinearProgressIndicator(),
                              )
                            else
                              TextFormField(
                                controller: _personaController,
                                enabled:
                                    !_payloadFrozen &&
                                    _personaEligible &&
                                    _personaRevision != null,
                                minLines: 5,
                                maxLines: 12,
                                decoration: InputDecoration(
                                  labelText: strings.personaLabel,
                                  helperText: strings.personaHint,
                                  helperMaxLines: 3,
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
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                minimumSize: const Size(48, 48),
                              ),
                              onPressed: _payloadFrozen || _mutationObsolete
                                  ? null
                                  : _deleteProfile,
                              icon: const Icon(Icons.delete_outline),
                              label: Text(strings.deleteAgent),
                            ),
                          ],
                          if (!widget.soulOnly &&
                              profile != null &&
                              profile.id == 'default') ...[
                            const SizedBox(height: 16),
                            Text(strings.defaultAgentCannotDelete),
                          ],
                          if (_pendingApproval != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                strings.profileApprovalRequired(
                                  _pendingApproval!.approvalId,
                                ),
                              ),
                            ),
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
                            if (widget.canEditSoul &&
                                _personaEligible &&
                                _personaRevision == null)
                              TextButton(
                                onPressed: _payloadFrozen ? null : _loadPersona,
                                child: Text(strings.retryAction),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: _saving ? null : _cancelEditor,
                        child: Text(
                          _pendingApproval == null || _editing
                              ? strings.cancelAction
                              : strings.profileCancelSetup,
                        ),
                      ),
                      FilledButton(
                        onPressed:
                            _saving ||
                                _loadingPersona ||
                                !(widget.isOwnerCurrent?.call() ?? true) ||
                                (widget.canEditSoul &&
                                    (!_personaEligible ||
                                        _personaRevision == null))
                            ? null
                            : _save,
                        child: _saving
                            ? Semantics(
                                excludeSemantics: widget.canEditSoul,
                                label: widget.canEditSoul
                                    ? strings.saveAction
                                    : null,
                                child: const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Text(
                                _pendingApproval != null
                                    ? (_editing
                                          ? strings.profileRetryApprovedDeletion
                                          : strings.profileRetryApprovedSetup)
                                    : profile == null
                                    ? strings.createAction
                                    : strings.saveAction,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
bool _isProfileRevisionConflict(Object error) =>
    (error is HermesApiStatusException && error.statusCode == 412) ||
    error is WingLinkPreconditionFailed;

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
