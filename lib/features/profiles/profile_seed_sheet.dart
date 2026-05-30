import 'package:flutter/material.dart';

import '../../core/channel/navivox_channel.dart';
import '../../core/gateway/navivox_gateway_protocol.dart';
import '../../core/protocol/navivox_json.dart';

class ProfileSeedSheet extends StatefulWidget {
  const ProfileSeedSheet({super.key, required this.channel});

  final NavivoxChannel channel;

  @override
  State<ProfileSeedSheet> createState() => _ProfileSeedSheetState();
}

class _ProfileSeedSheetState extends State<ProfileSeedSheet> {
  final _seedController = TextEditingController();
  final _profileIdController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _providerController = TextEditingController();
  final _modelController = TextEditingController();
  final _toolPolicyController = TextEditingController();
  final _voiceMetadataController = TextEditingController();
  final _workspacePathController = TextEditingController();

  NavivoxProfileSeedResult? _draftResult;
  bool _confirmNoWorkspace = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _workspacePathController.addListener(_onWorkspaceChanged);
  }

  @override
  void dispose() {
    _seedController.dispose();
    _profileIdController.dispose();
    _displayNameController.dispose();
    _instructionsController.dispose();
    _providerController.dispose();
    _modelController.dispose();
    _toolPolicyController.dispose();
    _voiceMetadataController.dispose();
    _workspacePathController
      ..removeListener(_onWorkspaceChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftResult?.draft;
    final canApply = !_loading && draft != null && _workspaceConfirmed;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create from seed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Gormes drafts profile config from your text. Navivox never writes TOML or grants workspace roots directly.',
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('profile-seed-input'),
              controller: _seedController,
              decoration: const InputDecoration(
                labelText: 'Profile seed',
                hintText: 'work on mineru repo',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const ValueKey('profile-seed-draft-button'),
                onPressed: _loading ? null : _generateDraft,
                icon: _loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: const Text('Generate draft'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (draft != null) ...[
              const SizedBox(height: 16),
              _DraftSummary(draft: draft),
              const SizedBox(height: 12),
              TextField(
                controller: _profileIdController,
                decoration: const InputDecoration(
                  labelText: 'Profile ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions',
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _providerController,
                      decoration: const InputDecoration(
                        labelText: 'Provider',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _toolPolicyController,
                decoration: const InputDecoration(
                  labelText: 'Tool policy',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _voiceMetadataController,
                decoration: const InputDecoration(
                  labelText: 'Voice metadata',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              Text(
                'Workspace suggestions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _WorkspaceSuggestions(draft: draft),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('profile-seed-workspace-path'),
                controller: _workspacePathController,
                decoration: const InputDecoration(
                  labelText: 'Workspace root path',
                  hintText: '/absolute/path/to/workspace',
                  border: OutlineInputBorder(),
                  helperText:
                      'Only paths you type here are sent to Gormes on apply.',
                ),
              ),
              CheckboxListTile(
                key: const ValueKey('profile-seed-no-workspace-confirmation'),
                value: _confirmNoWorkspace,
                onChanged: (value) => setState(() {
                  _confirmNoWorkspace = value ?? false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Continue without workspace roots'),
                subtitle: const Text(
                  'I understand suggested workspaces are not granted unless I type a path.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('profile-seed-apply-button'),
                onPressed: canApply ? _applyDraft : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Apply through Gormes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _workspaceConfirmed =>
      _workspaceRoots.isNotEmpty || _confirmNoWorkspace;

  List<String> get _workspaceRoots => navivoxTrimmedStringList(
    _workspacePathController.text.split(RegExp(r'[\n,]')),
  );

  void _onWorkspaceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _generateDraft() async {
    final seed = _seedController.text.trim();
    if (seed.isEmpty) {
      setState(() => _error = 'Enter a profile seed first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.channel.profileSeed(seed: seed);
      if (!mounted) return;
      setState(() {
        _draftResult = result;
        _populateDraft(result.draft);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gormes profile seed draft failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyDraft() async {
    final seed = _seedController.text.trim();
    if (seed.isEmpty || !_workspaceConfirmed) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.channel.profileSeed(
        seed: seed,
        apply: true,
        workspaceRoots: _workspaceRoots,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gormes profile seed apply failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _populateDraft(Map<String, Object?> draft) {
    final providerState = navivoxMapFieldFromJson(
      draft,
      'provider_model_state',
    );
    _profileIdController.text = navivoxStringFieldFromJson(draft, 'profile_id');
    _displayNameController.text = navivoxStringFieldFromJson(
      draft,
      'display_name',
    );
    _instructionsController.text = navivoxStringFieldFromJson(
      draft,
      'instructions',
    );
    _providerController.text = navivoxStringFieldFromJson(
      providerState,
      'provider',
    );
    _modelController.text = navivoxStringFieldFromJson(providerState, 'model');
    _toolPolicyController.text = _toolPolicyText(
      navivoxMapFieldFromJson(draft, 'tool_policy'),
    );
    _voiceMetadataController.text = _keyValueText(
      navivoxMapFieldFromJson(draft, 'voice_profile_metadata'),
    );
  }
}

class _DraftSummary extends StatelessWidget {
  const _DraftSummary({required this.draft});

  final Map<String, Object?> draft;

  @override
  Widget build(BuildContext context) {
    final providerState = navivoxMapFieldFromJson(
      draft,
      'provider_model_state',
    );
    final generationSource = navivoxStringFieldFromJson(
      draft,
      'generation_source',
    );
    final evidence = navivoxStringListFieldFromJson(draft, 'evidence');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('generation_source=$generationSource'),
            Text(
              'Provider status: ${navivoxStringFieldFromJson(providerState, 'status')}',
            ),
            if (evidence.isNotEmpty) Text('Evidence: ${evidence.join(', ')}'),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceSuggestions extends StatelessWidget {
  const _WorkspaceSuggestions({required this.draft});

  final Map<String, Object?> draft;

  @override
  Widget build(BuildContext context) {
    final suggestions =
        navivoxListFieldFromJson(draft, 'workspace_root_suggestions')
            .whereType<Map>()
            .map((item) => Map<String, Object?>.from(item))
            .toList(growable: false);
    if (suggestions.isEmpty) {
      return const Text('No workspace suggestions returned by Gormes.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final suggestion in suggestions)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_open),
            title: Text(navivoxStringFieldFromJson(suggestion, 'label')),
            subtitle: Text(
              '${navivoxStringFieldFromJson(suggestion, 'purpose')} (${_boolField(suggestion, 'requires_confirmation') ? 'requires confirmation' : 'informational'})',
            ),
          ),
      ],
    );
  }
}

String _toolPolicyText(Map<String, Object?> toolPolicy) {
  final lines = <String>[];
  final mode = navivoxStringFieldFromJson(toolPolicy, 'mode');
  if (mode.isNotEmpty) lines.add('mode: $mode');
  final allowed = navivoxStringListFieldFromJson(toolPolicy, 'allowed');
  if (allowed.isNotEmpty) lines.add('allowed: ${allowed.join(', ')}');
  final requiresApproval = navivoxStringListFieldFromJson(
    toolPolicy,
    'requires_approval',
  );
  if (requiresApproval.isNotEmpty) {
    lines.add('requires_approval: ${requiresApproval.join(', ')}');
  }
  return lines.join('\n');
}

String _keyValueText(Map<String, Object?> values) {
  final lines = <String>[];
  for (final entry in values.entries) {
    final value = entry.value;
    if (value == null) continue;
    if (value is List) {
      lines.add('${entry.key}: ${value.join(', ')}');
    } else {
      lines.add('${entry.key}: $value');
    }
  }
  return lines.join('\n');
}

bool _boolField(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is bool) return value;
  return value?.toString().trim().toLowerCase() == 'true';
}
