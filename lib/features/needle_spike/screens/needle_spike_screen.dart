import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/voice/voice_capture_service.dart';
import '../data/needle_test_transcripts.dart';
import '../models/needle_scorecard.dart';
import '../providers/needle_spike_providers.dart';
import '../services/needle_result.dart';

/// Hidden evaluation screen for the Needle spike. Reached only via the
/// NEEDLE_SPIKE-gated route. Transcripts shown here are never logged or
/// persisted; the scorecard keeps counts only.
class NeedleSpikeScreen extends ConsumerStatefulWidget {
  const NeedleSpikeScreen({super.key});

  @override
  ConsumerState<NeedleSpikeScreen> createState() => _NeedleSpikeScreenState();
}

class _NeedleSpikeScreenState extends ConsumerState<NeedleSpikeScreen> {
  final _transcriptController = TextEditingController();
  final _scorecard = NeedleScorecard();

  String? _modelDir;
  bool _preparing = false;
  bool _running = false;
  bool _capturing = false;
  int _downloadedBytes = 0;
  String? _error;
  NeedleResult? _result;

  /// True once the current [_result] has been given a verdict. Gates the
  /// verdict buttons so each result is scored exactly once; cleared when a
  /// new run starts.
  bool _resultScored = false;

  /// The capture service currently recording, if any. Held so dispose can
  /// release the microphone if the user backs out mid-capture.
  VoiceCaptureService? _activeCapture;

  /// True after the first tap on Reset; the second tap within the timeout
  /// actually clears the scorecard. Guards against stray taps wiping counts.
  bool _resetArmed = false;
  Timer? _resetArmTimer;

  @override
  void initState() {
    super.initState();
    _checkInstalled();
  }

  @override
  void dispose() {
    // Fire-and-forget: release the microphone if a capture is in flight.
    _activeCapture?.cancel();
    _transcriptController.dispose();
    _resetArmTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInstalled() async {
    try {
      final install = await ref.read(needleInstallServiceProvider.future);
      final dir = await install.installedModelDir();
      if (!mounted) return;
      setState(() => _modelDir = dir);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    }
  }

  Future<void> _prepareModel() async {
    setState(() {
      _preparing = true;
      _error = null;
    });
    try {
      final install = await ref.read(needleInstallServiceProvider.future);
      final dir = await install.ensureModel(
        onProgress: (bytes) {
          if (mounted) setState(() => _downloadedBytes = bytes);
        },
      );
      final engine = ref.read(needleEngineProvider);
      await engine.load(dir);
      if (!mounted) return;
      setState(() => _modelDir = dir);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _run(String transcript) async {
    final trimmed = transcript.trim();
    if (trimmed.isEmpty || _running) return;
    setState(() {
      _running = true;
      _error = null;
      _result = null;
      _resultScored = false;
    });
    try {
      final engine = ref.read(needleEngineProvider);
      if (!engine.isLoaded) {
        final dir = _modelDir;
        if (dir == null) {
          throw StateError('Download the model first.');
        }
        await engine.load(dir);
      }
      final service = ref.read(needleSpikeServiceProvider);
      final result = await service.parseTranscript(trimmed);
      if (!mounted) return;
      setState(() => _result = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _captureFromMic() async {
    final factory = ref.read(needleVoiceCaptureFactoryProvider);
    final capture = factory();
    if (capture == null) {
      setState(() => _error = 'Speech capture unavailable on this platform.');
      return;
    }
    setState(() {
      _capturing = true;
      _error = null;
    });
    _activeCapture = capture;
    try {
      final result = await capture.capture(
        timeout: const Duration(seconds: 15),
      );
      if (!mounted) return;
      _transcriptController.text = result.transcript;
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      _activeCapture = null;
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// Verdicts may only be recorded against a real, current, not-yet-scored
  /// result — otherwise the tally would drift from the actual runs.
  bool get _canRecordVerdict => _result != null && !_running && !_resultScored;

  void _recordVerdict(NeedleVerdict verdict) {
    if (!_canRecordVerdict) return;
    setState(() {
      _scorecard.record(verdict);
      _resultScored = true;
    });
  }

  /// First tap arms the reset (auto-disarms after 3s); second tap while
  /// armed actually clears the scorecard. Prevents a stray tap from wiping
  /// counts.
  void _handleResetTap() {
    if (_resetArmed) {
      _resetArmTimer?.cancel();
      setState(() {
        _scorecard.reset();
        _resetArmed = false;
      });
      return;
    }
    _resetArmTimer?.cancel();
    setState(() => _resetArmed = true);
    _resetArmTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _resetArmed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Needle spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_modelDir == null) _buildInstallCard() else ..._buildEvalUi(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstallCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Needle model is not installed (~16 MB download).'),
            const SizedBox(height: 12),
            if (_preparing)
              Text('Downloading… $_downloadedBytes bytes')
            else
              FilledButton(
                key: const Key('needle-download-button'),
                onPressed: _prepareModel,
                child: const Text('Download and load model'),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEvalUi() {
    final result = _result;
    return [
      TextField(
        key: const Key('needle-transcript-field'),
        controller: _transcriptController,
        decoration: InputDecoration(
          labelText: 'Transcript',
          suffixIcon: IconButton(
            key: const Key('needle-mic-button'),
            icon: Icon(_capturing ? Icons.mic : Icons.mic_none),
            onPressed: _capturing ? null : _captureFromMic,
          ),
        ),
      ),
      const SizedBox(height: 8),
      FilledButton(
        key: const Key('needle-run-button'),
        onPressed: _running ? null : () => _run(_transcriptController.text),
        child: Text(_running ? 'Running…' : 'Run Needle'),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in needleTestTranscripts)
            ActionChip(
              label: Text(t.text, overflow: TextOverflow.ellipsis),
              onPressed: _running
                  ? null
                  : () {
                      _transcriptController.text = t.text;
                      _run(t.text);
                    },
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (result != null) _buildResultCard(result),
      const SizedBox(height: 16),
      _buildScorecard(),
    ];
  }

  Widget _buildResultCard(NeedleResult result) {
    final calls = result.functionCalls;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              calls.isEmpty
                  ? 'No tool call. Raw response: ${result.response}'
                  : [
                      if (calls.length > 1)
                        '⚠ ${calls.length} tool calls returned:',
                      for (final call in calls)
                        'Tool: ${call.name}\nArgs: ${call.arguments}',
                    ].join('\n'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'wall ${result.wallLatencyMs} ms · '
              'engine ${result.totalTimeMs?.toStringAsFixed(1) ?? '—'} ms · '
              'ttft ${result.timeToFirstTokenMs?.toStringAsFixed(1) ?? '—'} ms · '
              'confidence ${result.confidence?.toStringAsFixed(3) ?? '—'}',
            ),
            if (!result.success)
              Text('Engine error: ${result.error ?? 'unknown'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildScorecard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_scorecard.summaryLine),
            if (_resultScored)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('scored ✓'),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  key: const Key('needle-verdict-correct'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.correct)
                      : null,
                  child: const Text('Correct'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-wrong-tool'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.wrongTool)
                      : null,
                  child: const Text('Wrong tool'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-wrong-args'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.wrongArgs)
                      : null,
                  child: const Text('Wrong args'),
                ),
                OutlinedButton(
                  key: const Key('needle-verdict-no-call'),
                  onPressed: _canRecordVerdict
                      ? () => _recordVerdict(NeedleVerdict.noCall)
                      : null,
                  child: const Text('No call'),
                ),
                TextButton(
                  key: const Key('needle-scorecard-reset'),
                  onPressed: _handleResetTap,
                  child: Text(_resetArmed ? 'Confirm reset' : 'Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
