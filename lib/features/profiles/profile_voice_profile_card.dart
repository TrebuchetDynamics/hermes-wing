import 'package:flutter/material.dart';

import '../../core/channel/navivox_channel.dart';
import '../../core/gateway/navivox_gateway_protocol.dart';
import '../../core/protocol/navivox_json.dart';

class ProfileVoiceProfileCard extends StatefulWidget {
  const ProfileVoiceProfileCard({super.key, required this.channel});

  final NavivoxChannel channel;

  @override
  State<ProfileVoiceProfileCard> createState() =>
      _ProfileVoiceProfileCardState();
}

class _ProfileVoiceProfileCardState extends State<ProfileVoiceProfileCard> {
  final _sttProviderController = TextEditingController();
  final _ttsProviderController = TextEditingController();
  final _voiceIdController = TextEditingController();
  final _languagePolicyController = TextEditingController();
  final _fallbackVoiceController = TextEditingController();
  final _sttCredentialController = TextEditingController();
  final _ttsCredentialController = TextEditingController();

  NavivoxVoiceProfilesResponse? _profiles;
  NavivoxVoiceProfileValidationResponse? _validation;
  NavivoxRunRecordSnapshot? _runRecord;
  String? _statusMessage;
  String? _error;
  bool _loading = false;
  bool _editing = false;
  String? _loadedProfileKey;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didUpdateWidget(ProfileVoiceProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final key = widget.channel.state.activeProfileContact?.key;
    if (key != _loadedProfileKey) {
      _loadProfiles();
    }
  }

  @override
  void dispose() {
    _sttProviderController.dispose();
    _ttsProviderController.dispose();
    _voiceIdController.dispose();
    _languagePolicyController.dispose();
    _fallbackVoiceController.dispose();
    _sttCredentialController.dispose();
    _ttsCredentialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.channel.state.activeProfileContact;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voice profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Text chat remains available when voice providers are unavailable.',
            ),
            if (active == null) ...[
              const SizedBox(height: 8),
              const Text('Select a profile to inspect voice settings.'),
            ] else if (_loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ] else if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else ...[
              const SizedBox(height: 12),
              _buildProfileContent(context, active),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    NavivoxProfileContact active,
  ) {
    final response = _profiles;
    final view = _activeVoiceProfile(active);
    if (response == null || view == null) {
      return const Text('No voice profile reported by Gormes.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile: ${view.displayName}'),
        Text(
          'Available STT: ${_listLabel(response.providerMatrix.sttProviders)}',
        ),
        Text(
          'Available TTS: ${_listLabel(response.providerMatrix.ttsProviders)}',
        ),
        const SizedBox(height: 8),
        if (_editing)
          _VoiceProfileEditor(
            sttProviderController: _sttProviderController,
            ttsProviderController: _ttsProviderController,
            voiceIdController: _voiceIdController,
            languagePolicyController: _languagePolicyController,
            fallbackVoiceController: _fallbackVoiceController,
            sttCredentialController: _sttCredentialController,
            ttsCredentialController: _ttsCredentialController,
            validationErrors: _validation?.errors ?? const [],
            onApply: () => _validateAndApply(view),
            onCancel: () => setState(() => _editing = false),
          )
        else ...[
          Text('STT provider: ${_valueOrUnset(view.voiceProfile.sttProvider)}'),
          Text('TTS provider: ${_valueOrUnset(view.voiceProfile.ttsProvider)}'),
          Text('Voice ID: ${_valueOrUnset(view.voiceProfile.voiceId)}'),
          Text(
            'Language policy: ${_valueOrUnset(view.voiceProfile.languagePolicy)}',
          ),
          Text(
            'Fallback voice: ${_valueOrUnset(view.voiceProfile.fallbackVoice)}',
          ),
          const SizedBox(height: 8),
          Text(
            _credentialLabel(
              'STT credential',
              view.credentialStatusRefs['stt'],
            ),
          ),
          Text(
            _credentialLabel(
              'TTS credential',
              view.credentialStatusRefs['tts'],
            ),
          ),
          for (final error in view.errors) Text(_errorLabel(error)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const ValueKey('voice-profile-edit'),
                onPressed: () => _beginEditing(view),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit voice profile'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('voice-profile-load-evidence'),
                onPressed: _loadRunRecordEvidence,
                icon: const Icon(Icons.history),
                label: const Text('Load voice fallback evidence'),
              ),
            ],
          ),
        ],
        if (_statusMessage != null) ...[
          const SizedBox(height: 8),
          Text(_statusMessage!),
        ],
        if (_runRecord != null) ...[
          const SizedBox(height: 8),
          _VoiceRunEvidence(record: _runRecord!),
        ],
      ],
    );
  }

  Future<void> _loadProfiles() async {
    final key = widget.channel.state.activeProfileContact?.key;
    setState(() {
      _loadedProfileKey = key;
      _loading = key != null;
      _error = null;
      _validation = null;
      _runRecord = null;
      _statusMessage = null;
      _editing = false;
    });
    if (key == null) return;
    try {
      final profiles = await widget.channel.voiceProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gormes voice profiles are unavailable.';
        _loading = false;
      });
    }
  }

  NavivoxVoiceProfileView? _activeVoiceProfile(NavivoxProfileContact active) {
    final profiles = _profiles?.profiles ?? const [];
    for (final profile in profiles) {
      if (profile.profileId == active.profileId) return profile;
    }
    return null;
  }

  void _beginEditing(NavivoxVoiceProfileView view) {
    final voice = view.voiceProfile;
    _sttProviderController.text = voice.sttProvider;
    _ttsProviderController.text = voice.ttsProvider;
    _voiceIdController.text = voice.voiceId;
    _languagePolicyController.text = voice.languagePolicy;
    _fallbackVoiceController.text = voice.fallbackVoice;
    _sttCredentialController.clear();
    _ttsCredentialController.clear();
    setState(() {
      _editing = true;
      _validation = null;
      _statusMessage = null;
    });
  }

  Future<void> _validateAndApply(NavivoxVoiceProfileView view) async {
    final profileId = view.profileId;
    final voiceProfile = NavivoxProfileVoiceProfile(
      sttProvider: _sttProviderController.text,
      ttsProvider: _ttsProviderController.text,
      voiceId: _voiceIdController.text,
      languagePolicy: _languagePolicyController.text,
      fallbackVoice: _fallbackVoiceController.text,
    );
    final validation = await widget.channel.validateVoiceProfile(
      profileId: profileId,
      voiceProfile: voiceProfile,
    );
    if (!mounted) return;
    setState(() => _validation = validation);
    if (!validation.valid) return;

    for (final field in _voiceProfileFields(voiceProfile)) {
      widget.channel.sendConfigSet(
        field: 'profiles.$profileId.voice_profile.${field.name}',
        value: field.value,
      );
    }
    final sttCredential = _sttCredentialController.text.trim();
    if (sttCredential.isNotEmpty) {
      widget.channel.sendConfigSecretSet(
        name: 'profiles.$profileId.voice_profile.stt_credential',
        secret: sttCredential,
      );
    }
    final ttsCredential = _ttsCredentialController.text.trim();
    if (ttsCredential.isNotEmpty) {
      widget.channel.sendConfigSecretSet(
        name: 'profiles.$profileId.voice_profile.tts_credential',
        secret: ttsCredential,
      );
    }
    _sttCredentialController.clear();
    _ttsCredentialController.clear();
    setState(() {
      _editing = false;
      _statusMessage = 'Voice profile sent to Gormes config admin.';
    });
  }

  Future<void> _loadRunRecordEvidence() async {
    final activeRun = widget.channel.state.activeVoiceRun;
    final id = activeRun?.requestId?.trim().isNotEmpty == true
        ? activeRun!.requestId!
        : activeRun?.id;
    if (id == null || id.trim().isEmpty) {
      setState(() {
        _statusMessage = 'No voice run evidence yet.';
      });
      return;
    }
    final record = await widget.channel.runRecord(id);
    if (!mounted) return;
    setState(() {
      _runRecord = record;
      _statusMessage = null;
    });
  }
}

class _VoiceProfileEditor extends StatelessWidget {
  const _VoiceProfileEditor({
    required this.sttProviderController,
    required this.ttsProviderController,
    required this.voiceIdController,
    required this.languagePolicyController,
    required this.fallbackVoiceController,
    required this.sttCredentialController,
    required this.ttsCredentialController,
    required this.validationErrors,
    required this.onApply,
    required this.onCancel,
  });

  final TextEditingController sttProviderController;
  final TextEditingController ttsProviderController;
  final TextEditingController voiceIdController;
  final TextEditingController languagePolicyController;
  final TextEditingController fallbackVoiceController;
  final TextEditingController sttCredentialController;
  final TextEditingController ttsCredentialController;
  final List<NavivoxVoiceProfileFieldError> validationErrors;
  final VoidCallback onApply;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _input('stt_provider', 'STT provider', sttProviderController),
        _input('tts_provider', 'TTS provider', ttsProviderController),
        _input('voice_id', 'Voice ID', voiceIdController),
        _input('language_policy', 'Language policy', languagePolicyController),
        _input('fallback_voice', 'Fallback voice', fallbackVoiceController),
        _input(
          'stt_credential',
          'STT credential (write-only)',
          sttCredentialController,
          obscureText: true,
        ),
        _input(
          'tts_credential',
          'TTS credential (write-only)',
          ttsCredentialController,
          obscureText: true,
        ),
        for (final error in validationErrors)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _errorLabel(error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              key: const ValueKey('voice-profile-validate-apply'),
              onPressed: onApply,
              child: const Text('Validate and apply through Gormes'),
            ),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
          ],
        ),
      ],
    );
  }

  Widget _input(
    String field,
    String label,
    TextEditingController controller, {
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        key: ValueKey('voice-profile-input-$field'),
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _VoiceRunEvidence extends StatelessWidget {
  const _VoiceRunEvidence({required this.record});

  final NavivoxRunRecordSnapshot record;

  @override
  Widget build(BuildContext context) {
    final voice = navivoxMapFieldFromJson(record.raw, 'voice');
    final serverStt = navivoxMapFieldFromJson(voice, 'server_stt');
    final tts = navivoxMapFieldFromJson(voice, 'tts');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Server STT: ${_providerStatus(serverStt)}'),
        Text('TTS: ${_providerStatus(tts)}'),
      ],
    );
  }
}

typedef _VoiceField = ({String name, String value});

List<_VoiceField> _voiceProfileFields(NavivoxProfileVoiceProfile voice) {
  return [
    (name: 'stt_provider', value: voice.sttProvider.trim()),
    (name: 'tts_provider', value: voice.ttsProvider.trim()),
    (name: 'voice_id', value: voice.voiceId.trim()),
    (name: 'language_policy', value: voice.languagePolicy.trim()),
    (name: 'fallback_voice', value: voice.fallbackVoice.trim()),
  ];
}

String _providerStatus(Map<String, Object?> value) {
  final provider = navivoxStringFieldFromJson(value, 'provider');
  final status = navivoxStringFieldFromJson(value, 'status');
  return [provider, status].where((part) => part.isNotEmpty).join(' ');
}

String _credentialLabel(String label, NavivoxVoiceCredentialStatus? status) {
  if (status == null) return '$label: not reported';
  final suffix = status.source.trim().isEmpty ? '' : ' (${status.source})';
  return '$label: ${status.status}$suffix';
}

String _errorLabel(NavivoxVoiceProfileFieldError error) {
  return '${error.field}: ${error.message}';
}

String _listLabel(List<String> values) {
  if (values.isEmpty) return 'not reported';
  return values.join(', ');
}

String _valueOrUnset(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'unset' : trimmed;
}
