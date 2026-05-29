import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/channel/navivox_channel.dart';
import '../../../core/channel/navivox_channel_provider.dart';
import '../../../core/gateway/navivox_gateway_protocol.dart';
import '../../profile_contacts/profile_contact_presentation.dart';
import '../../profiles/profile_voice_profile_card.dart';
import '../apply/config_apply_dispatcher.dart';
import '../apply/config_apply_flow_model.dart';
import '../apply/config_apply_presentation.dart';
import '../form/config_draft_session.dart';
import '../form/config_field_presentation.dart';
import '../presentation/config_screen_presentation.dart';
import '../presentation/config_section_presentation.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({this.sectionId, super.key});

  final String? sectionId;

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  NavivoxChannel? _subscribed;
  final ConfigApplyDispatcher _applyDispatcher = const ConfigApplyDispatcher();
  ConfigDraftSession _draftSession = const ConfigDraftSession();
  final TextEditingController _controller = TextEditingController();
  NavivoxConfigAdminResponse? _lastConfigAdminApply;
  String? _configAdminError;

  void _onChannelChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscribed?.removeListener(_onChannelChanged);
    _controller.dispose();
    super.dispose();
  }

  void _stageDraft(ConfigFieldPresentation field) {
    setState(() {
      _draftSession = _draftSession.stageEdit(field, _controller.text);
    });
  }

  Future<void> _applyPendingChanges(ConfigApplyFlowModel flow) async {
    if (!flow.canApply) return;
    final channel = ref.read(navivoxChannelProvider);
    if (channel.configAdminAvailable) {
      await _applyConfigAdminChanges(flow, channel);
      return;
    }

    final presentation = ConfigApplyPresentation.fromFlow(flow);
    if (presentation.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) =>
            _ConfigConfirmationDialog(presentation: presentation),
      );
      if (!mounted || confirmed != true) return;
    }

    final result = _applyDispatcher.dispatch(flow: flow, channel: channel);
    if (!result.wasDispatched) return;
    setState(() {
      _draftSession = _draftSession.clearApplied(flow);
    });
  }

  Future<void> _applyConfigAdminChanges(
    ConfigApplyFlowModel flow,
    NavivoxChannel channel,
  ) async {
    final changes = _configAdminChangesFromFlow(flow);
    if (changes.isEmpty) return;
    setState(() {
      _configAdminError = null;
      _lastConfigAdminApply = null;
    });
    try {
      final validation = await channel.validateConfigAdmin(changes);
      if (!mounted) return;
      if (!validation.valid) {
        setState(() {
          _configAdminError = 'Config validation failed.';
        });
        return;
      }
      final diff = await channel.diffConfigAdmin(changes);
      if (!mounted) return;
      if (!diff.valid) {
        setState(() {
          _configAdminError = 'Config diff failed.';
        });
        return;
      }
      final presentation = ConfigApplyPresentation.fromFlow(flow);
      if (presentation.requiresConfirmation) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => _ConfigConfirmationDialog(
            presentation: presentation,
            backendDiff: diff,
          ),
        );
        if (!mounted || confirmed != true) return;
      }
      final applied = await channel.applyConfigAdmin(changes);
      if (!mounted) return;
      if (!applied.applied) {
        setState(() {
          _configAdminError = 'Config apply was not accepted by Gormes.';
        });
        return;
      }
      setState(() {
        _lastConfigAdminApply = applied;
        _draftSession = _draftSession.clearApplied(flow);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _configAdminError = 'Config admin request failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final channel = ref.watch(navivoxChannelProvider);
    if (!identical(_subscribed, channel)) {
      _subscribed?.removeListener(_onChannelChanged);
      channel.addListener(_onChannelChanged);
      _subscribed = channel;
    }

    final screen = ConfigScreenPresentation.fromState(
      state: channel.state,
      sectionId: widget.sectionId,
      draftSession: _draftSession,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Config')),
      body: ListView(
        children: [
          _ConfigScopeCard(scope: screen.scope),
          if (channel.state.activeProfileContact != null)
            ProfileVoiceProfileCard(channel: channel),
          if (screen.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(screen.emptyMessage)),
            )
          else if (screen.isMissingSection)
            _MissingConfigSectionCard(message: screen.missingSectionMessage)
          else
            for (final section in screen.sections)
              _ConfigSectionCard(
                section: section,
                controller: _controller,
                onEdit: (field) {
                  _controller.text = _draftSession.editInitialValueFor(field);
                  setState(() {
                    _draftSession = _draftSession.beginEditing(field);
                  });
                },
                onCancel: () => setState(() {
                  _draftSession = _draftSession.cancelEditing();
                }),
                onSave: _stageDraft,
              ),
          if (screen.showPendingChanges)
            _ConfigPendingChangesCard(
              presentation: screen.applyPresentation,
              onApply: () => _applyPendingChanges(screen.applyFlow),
            ),
          if (_configAdminError != null)
            _ConfigAdminStatusCard(message: _configAdminError!, isError: true),
          if (_lastConfigAdminApply != null)
            _ConfigAdminApplyResultCard(result: _lastConfigAdminApply!),
        ],
      ),
    );
  }
}

List<NavivoxConfigAdminChange> _configAdminChangesFromFlow(
  ConfigApplyFlowModel flow,
) {
  return flow.changes
      .map(
        (change) => NavivoxConfigAdminChange(
          key: change.path,
          value: change.applyValue,
        ),
      )
      .toList(growable: false);
}

class _ConfigScopeCard extends StatelessWidget {
  const _ConfigScopeCard({required this.scope});

  final ProfileContactScopePresentation scope;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile config scope',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Server: ${scope.serverLabel}'),
            Text('Profile: ${scope.profileLabel}'),
            if (scope.profileId != null) Text('Profile ID: ${scope.profileId}'),
            const SizedBox(height: 8),
            const Text(
              'Config values shown here belong to the selected Gormes profile when the gateway provides profile-scoped config.',
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingConfigSectionCard extends StatelessWidget {
  const _MissingConfigSectionCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message)),
    );
  }
}

class _ConfigSectionCard extends StatelessWidget {
  const _ConfigSectionCard({
    required this.section,
    required this.controller,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final ConfigSectionPresentation section;
  final TextEditingController controller;
  final ValueChanged<ConfigFieldPresentation> onEdit;
  final VoidCallback onCancel;
  final ValueChanged<ConfigFieldPresentation> onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.label, style: Theme.of(context).textTheme.titleMedium),
            if (section.hasDescription) ...[
              const SizedBox(height: 4),
              Text(section.description!),
            ],
            const SizedBox(height: 8),
            for (final field in section.fields)
              _ConfigRow(
                field: field.field,
                isEditing: field.isEditing,
                controller: controller,
                onEdit: onEdit,
                onCancel: onCancel,
                onSave: onSave,
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfigPendingChangesCard extends StatelessWidget {
  const _ConfigPendingChangesCard({
    required this.presentation,
    required this.onApply,
  });

  final ConfigApplyPresentation presentation;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              presentation.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final change in presentation.changes) ...[
              Text(change.summaryLabel),
              if (change.hasRestartLabel)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(label: Text(change.restartLabel!)),
                ),
              for (final message in change.validationMessages)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const ValueKey('config-apply-pending'),
                onPressed: presentation.canApply ? onApply : null,
                child: Text(presentation.applyButtonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigAdminStatusCard extends StatelessWidget {
  const _ConfigAdminStatusCard({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: isError
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
      ),
    );
  }
}

class _ConfigAdminApplyResultCard extends StatelessWidget {
  const _ConfigAdminApplyResultCard({required this.result});

  final NavivoxConfigAdminResponse result;

  @override
  Widget build(BuildContext context) {
    final status = result.reloadApplied
        ? 'Config reload applied by Gormes.'
        : result.pendingRestart
        ? 'Config changes pending restart.'
        : 'Config changes applied.';
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: Theme.of(context).textTheme.titleSmall),
            if (result.reloadError.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(result.reloadError),
            ],
            for (final change in result.changes)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(change.summaryLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConfigConfirmationDialog extends StatelessWidget {
  const _ConfigConfirmationDialog({
    required this.presentation,
    this.backendDiff,
  });

  final ConfigApplyPresentation presentation;
  final NavivoxConfigAdminResponse? backendDiff;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(presentation.confirmationTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(presentation.confirmationIntro),
          const SizedBox(height: 12),
          for (final summary in _confirmationSummaries()) ...[
            Text(summary),
            const SizedBox(height: 8),
          ],
          if (backendDiff == null)
            for (final change in presentation.changes) ...[
              if (change.hasRestartLabel)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Chip(label: Text(change.restartLabel!)),
                ),
              const SizedBox(height: 8),
            ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm apply'),
        ),
      ],
    );
  }

  List<String> _confirmationSummaries() {
    final diff = backendDiff;
    if (diff != null && diff.changes.isNotEmpty) {
      return diff.changes.map((change) => change.summaryLabel).toList();
    }
    return presentation.changes
        .map((change) => change.summaryLabel)
        .toList(growable: false);
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.field,
    required this.isEditing,
    required this.controller,
    required this.onEdit,
    required this.onCancel,
    required this.onSave,
  });

  final ConfigFieldPresentation field;
  final bool isEditing;
  final TextEditingController controller;
  final ValueChanged<ConfigFieldPresentation> onEdit;
  final VoidCallback onCancel;
  final ValueChanged<ConfigFieldPresentation> onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (isEditing)
                  TextField(
                    key: field.inputKey,
                    controller: controller,
                    obscureText: field.obscureText,
                    keyboardType: field.keyboardType,
                  )
                else
                  Text(field.displayValue),
                for (final helper in field.helperLines)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(helper),
                  ),
                for (final message in field.validationMessages)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isEditing) ...[
            IconButton(
              key: field.saveKey,
              icon: const Icon(Icons.check),
              onPressed: () => onSave(field),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
          ] else
            IconButton(
              key: field.editKey,
              icon: const Icon(Icons.edit),
              onPressed: () => onEdit(field),
            ),
        ],
      ),
    );
  }
}
