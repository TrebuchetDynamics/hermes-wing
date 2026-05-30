import '../../../../core/gateway/navivox_gateway_protocol.dart';
import '../../../../core/protocol/navivox_json.dart';

class TranscriptRunRecordInfoRow {
  const TranscriptRunRecordInfoRow({required this.label, required this.value});

  final String label;
  final String value;
}

class TranscriptRunRecordTranscriptRow {
  const TranscriptRunRecordTranscriptRow({
    required this.role,
    required this.text,
  });

  final String role;
  final String text;
}

class TranscriptRunRecordToolRow {
  const TranscriptRunRecordToolRow({
    required this.id,
    required this.name,
    required this.status,
    required this.artifactRef,
  });

  final String id;
  final String name;
  final String status;
  final String artifactRef;
}

class TranscriptRunRecordPresentation {
  const TranscriptRunRecordPresentation._({
    required this.runId,
    required this.sessionId,
    required this.statusLabel,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.completedAtLabel,
    required this.providerUsageLabel,
    required this.providerCostLabel,
    required this.transcriptRows,
    required this.voiceRows,
    required this.toolRows,
  });

  factory TranscriptRunRecordPresentation.fromRecord(
    NavivoxRunRecordSnapshot record,
  ) {
    final raw = record.raw;
    final voice = navivoxMapFieldFromJson(raw, 'voice');
    return TranscriptRunRecordPresentation._(
      runId: _valueOrUnknown(record.runId),
      sessionId: _valueOrUnknown(record.sessionId),
      statusLabel: _valueOrUnknown(record.status),
      createdAtLabel: _dateLabel(record.createdAt),
      updatedAtLabel: _dateLabel(record.updatedAt),
      completedAtLabel: _dateLabel(record.completedAt),
      providerUsageLabel: _usageLabel(
        navivoxMapFieldFromJson(raw, 'provider_usage'),
      ),
      providerCostLabel: _costLabel(
        navivoxMapFieldFromJson(raw, 'provider_cost'),
      ),
      transcriptRows: _transcriptRows(raw),
      voiceRows: _voiceRows(voice),
      toolRows: _toolRows(raw),
    );
  }

  final String runId;
  final String sessionId;
  final String statusLabel;
  final String createdAtLabel;
  final String updatedAtLabel;
  final String completedAtLabel;
  final String providerUsageLabel;
  final String providerCostLabel;
  final List<TranscriptRunRecordTranscriptRow> transcriptRows;
  final List<TranscriptRunRecordInfoRow> voiceRows;
  final List<TranscriptRunRecordToolRow> toolRows;

  String get title => 'Evidence';

  String get searchableText {
    final parts = <String>[
      title,
      runId,
      sessionId,
      statusLabel,
      createdAtLabel,
      updatedAtLabel,
      completedAtLabel,
      providerUsageLabel,
      providerCostLabel,
      for (final row in transcriptRows) row.role,
      for (final row in transcriptRows) row.text,
      for (final row in voiceRows) row.label,
      for (final row in voiceRows) row.value,
      for (final row in toolRows) row.id,
      for (final row in toolRows) row.name,
      for (final row in toolRows) row.status,
      for (final row in toolRows) row.artifactRef,
    ];
    return parts.where((part) => part.trim().isNotEmpty).join('\n');
  }
}

List<TranscriptRunRecordTranscriptRow> _transcriptRows(
  Map<String, Object?> raw,
) {
  final value = raw['transcript'];
  if (value is! List) return const [];
  final rows = <TranscriptRunRecordTranscriptRow>[];
  for (final item in value.whereType<Map>()) {
    final row = Map<String, Object?>.from(item);
    final role = navivoxOptionalStringFromJson(row['role']);
    final text = navivoxOptionalStringFromJson(row['text']);
    if (role == null && text == null) continue;
    rows.add(
      TranscriptRunRecordTranscriptRow(
        role: role ?? 'unknown',
        text: text ?? '',
      ),
    );
  }
  return rows;
}

List<TranscriptRunRecordInfoRow> _voiceRows(Map<String, Object?> voice) {
  final rows = <TranscriptRunRecordInfoRow>[];
  final transcript = navivoxOptionalStringFromJson(voice['device_transcript']);
  if (transcript != null) {
    rows.add(
      TranscriptRunRecordInfoRow(label: 'Device transcript', value: transcript),
    );
  }

  final audio = navivoxMapFieldFromJson(voice, 'audio');
  final audioParts = <String>[];
  final duration = navivoxOptionalStringFromJson(audio['duration_ms']);
  if (duration != null) audioParts.add('$duration ms');
  final codec = navivoxOptionalStringFromJson(audio['codec']);
  if (codec != null) audioParts.add('codec $codec');
  if (audio.containsKey('raw_audio_stored')) {
    audioParts.add(
      audio['raw_audio_stored'] == true
          ? 'raw audio stored'
          : 'raw audio not stored',
    );
  }
  final retention = navivoxOptionalStringFromJson(audio['retention']);
  if (retention != null) audioParts.add('retention $retention');
  if (audioParts.isNotEmpty) {
    rows.add(
      TranscriptRunRecordInfoRow(label: 'Audio', value: audioParts.join(' • ')),
    );
  }

  final serverStt = _providerState(
    navivoxMapFieldFromJson(voice, 'server_stt'),
  );
  if (serverStt != null) {
    rows.add(TranscriptRunRecordInfoRow(label: 'Server STT', value: serverStt));
  }
  final tts = _providerState(
    navivoxMapFieldFromJson(voice, 'tts'),
    includeVoice: true,
  );
  if (tts != null) {
    rows.add(TranscriptRunRecordInfoRow(label: 'TTS', value: tts));
  }

  if (rows.isEmpty) {
    rows.add(
      const TranscriptRunRecordInfoRow(
        label: 'Raw audio retention',
        value: 'unknown',
      ),
    );
  }
  return rows;
}

String? _providerState(
  Map<String, Object?> value, {
  bool includeVoice = false,
}) {
  if (value.isEmpty) return null;
  final parts = <String>[];
  final provider = navivoxOptionalStringFromJson(value['provider']);
  final status = navivoxOptionalStringFromJson(value['status']);
  if (provider != null) parts.add(provider);
  if (status != null) parts.add(status);
  if (includeVoice) {
    final voice = navivoxOptionalStringFromJson(value['voice_id']);
    if (voice != null) parts.add('voice $voice');
  }
  return parts.isEmpty ? null : parts.join(' • ');
}

List<TranscriptRunRecordToolRow> _toolRows(Map<String, Object?> raw) {
  final value = raw['tool_events'];
  if (value is! List) return const [];
  final rows = <TranscriptRunRecordToolRow>[];
  for (final item in value.whereType<Map>()) {
    final row = Map<String, Object?>.from(item);
    final id = navivoxOptionalStringFromJson(row['tool_call_id']) ?? 'unknown';
    final name = navivoxOptionalStringFromJson(row['name']) ?? id;
    final status = navivoxOptionalStringFromJson(row['status']) ?? 'unknown';
    final metadata = navivoxMapFieldFromJson(row, 'metadata');
    rows.add(
      TranscriptRunRecordToolRow(
        id: id,
        name: name,
        status: status,
        artifactRef: _artifactRef(metadata),
      ),
    );
  }
  return rows;
}

String _artifactRef(Map<String, Object?> metadata) {
  return navivoxOptionalStringFromJson(metadata['artifact_ref']) ??
      navivoxOptionalStringFromJson(metadata['ref']) ??
      navivoxOptionalStringFromJson(metadata['artifact_id']) ??
      'none';
}

String _usageLabel(Map<String, Object?> value) {
  if (value.isEmpty) return 'unknown';
  final status = navivoxOptionalStringFromJson(value['status']);
  if (status != null && status != 'available') return status;
  final total = navivoxOptionalStringFromJson(value['total_tokens']);
  if (total != null) return '$total tokens';
  final input = navivoxOptionalStringFromJson(
    value['input_tokens'] ?? value['prompt_tokens'],
  );
  final output = navivoxOptionalStringFromJson(
    value['output_tokens'] ?? value['completion_tokens'],
  );
  final parts = <String>[];
  if (input != null) parts.add('input $input');
  if (output != null) parts.add('output $output');
  if (parts.isNotEmpty) return parts.join(' • ');
  return status ?? 'unknown';
}

String _costLabel(Map<String, Object?> value) {
  if (value.isEmpty) return 'unknown';
  final status = navivoxOptionalStringFromJson(value['status']);
  if (status != null && status != 'available') return status;
  final total = navivoxOptionalStringFromJson(
    value['total_usd'] ?? value['cost_usd'] ?? value['total_cost_usd'],
  );
  if (total != null) return '$total USD';
  return status ?? 'unknown';
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'unknown';
  return date.toLocal().toIso8601String();
}

String _valueOrUnknown(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'unknown' : trimmed;
}
