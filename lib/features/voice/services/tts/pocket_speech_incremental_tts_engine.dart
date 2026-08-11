import 'dart:typed_data';

import 'package:pocket_speech/pocket_speech.dart';

import '../../../../shared/voice/text_to_speech_service.dart';
import '../../../../shared/voice/voice_settings.dart';
import 'android_incremental_pcm_playback.dart';
import 'incremental_tts_engine.dart';
import 'incremental_tts_coordinator.dart';
import 'pocket_speech_text_to_speech_service.dart';
import 'text_to_speech_service.dart' show TtsSettingsReader;

TextToSpeechService? createIncrementalPocketSpeechTextToSpeechService({
  required bool enabled,
  required bool isAndroid,
  required PocketSpeechVoicePack? voicePack,
  PocketSpeechEngine? engine,
  IncrementalPcmPlayback? playback,
  required TextToSpeechService? fallback,
  TtsSettingsReader? settings,
}) {
  if (!enabled ||
      !isAndroid ||
      voicePack?.model != PocketSpeechModel.kokoro ||
      fallback == null) {
    return null;
  }
  final effectiveEngine = engine ?? PackagePocketSpeechEngine(voicePack!);
  return IncrementalTtsCoordinator(
    engine: PocketSpeechIncrementalTtsEngine(
      effectiveEngine,
      selectedVoice: () => settings?.call().ttsVoiceName,
      speed: () => settings?.call().speechRate ?? 1.0,
    ),
    playback: playback ?? AndroidIncrementalPcmPlayback(),
    fallback: fallback,
  );
}

/// Adapts Kokoro's WAV synthesis output to generation-owned PCM playback.
///
/// Kokoro currently returns a complete WAV. Chunks are emitted after synthesis
/// so cancellation can suppress stale output immediately, while the platform
/// playback path remains incremental and app-owned.
final class PocketSpeechIncrementalTtsEngine implements IncrementalTtsEngine {
  PocketSpeechIncrementalTtsEngine(
    this._engine, {
    this.selectedVoice,
    this.speed,
    this.chunkBytes = 8192,
  });

  final PocketSpeechEngine _engine;
  final String? Function()? selectedVoice;
  final double Function()? speed;
  final int chunkBytes;
  int _operation = 0;
  bool _disposed = false;
  Future<void> _synthesisBarrier = Future<void>.value();

  @override
  Stream<PcmAudioChunk> synthesize(TtsSynthesisRequest request) async* {
    if (_disposed) throw StateError('Offline synthesis is disposed.');
    if (chunkBytes < 2) throw StateError('PCM chunk size is invalid.');
    final operation = ++_operation;
    final voice = _voiceFor(request.languageHint);
    final speed = (this.speed?.call() ?? 1.0).clamp(0.5, 2.0);
    final synthesis = _synthesisBarrier.then<Uint8List?>((_) async {
      if (_disposed || operation != _operation) return null;
      return _engine.synthesizeWav(request.text, voice: voice, speed: speed);
    });
    _synthesisBarrier = synthesis.then<void>((_) {}, onError: (_, _) {});
    final wav = await synthesis;
    if (wav == null || _disposed || operation != _operation) return;

    final decoded = _decodeMonoPcm16Wav(wav);
    final alignedChunkBytes = chunkBytes.isEven ? chunkBytes : chunkBytes - 1;
    for (
      var offset = 0;
      offset < decoded.pcm.length;
      offset += alignedChunkBytes
    ) {
      if (_disposed || operation != _operation) return;
      final end = (offset + alignedChunkBytes).clamp(0, decoded.pcm.length);
      yield PcmAudioChunk(
        generation: request.generation,
        bytes: Uint8List.sublistView(decoded.pcm, offset, end),
        sampleRate: decoded.sampleRate,
        channelCount: 1,
      );
    }
  }

  String _voiceFor(String languageHint) {
    final language = languageHint.toLowerCase().startsWith('es')
        ? 'es'
        : 'en-us';
    final selected = selectedVoice?.call();
    if (selected != null && KokoroCatalog.supportsVoice(selected)) {
      final selectedLanguage = KokoroCatalog.voice(selected).languageCode;
      if (selectedLanguage == language ||
          (language == 'en-us' && selectedLanguage.startsWith('en-'))) {
        return selected;
      }
    }
    return KokoroCatalog.defaultVoiceForLanguage(language).id;
  }

  @override
  Future<void> stop() async {
    _operation += 1;
    await _synthesisBarrier;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _operation += 1;
    await _synthesisBarrier;
    await _engine.dispose();
  }
}

final class _DecodedPcmWav {
  const _DecodedPcmWav({required this.pcm, required this.sampleRate});

  final Uint8List pcm;
  final int sampleRate;
}

_DecodedPcmWav _decodeMonoPcm16Wav(Uint8List wav) {
  if (wav.length < 12 ||
      _ascii(wav, 0, 4) != 'RIFF' ||
      _ascii(wav, 8, 4) != 'WAVE') {
    throw const FormatException('Offline synthesis returned invalid audio.');
  }
  final data = ByteData.sublistView(wav);
  int? sampleRate;
  var validFormat = false;
  Uint8List? pcm;
  var offset = 12;
  while (offset + 8 <= wav.length) {
    final id = _ascii(wav, offset, 4);
    final length = data.getUint32(offset + 4, Endian.little);
    final content = offset + 8;
    final end = content + length;
    if (end > wav.length) {
      throw const FormatException('Offline synthesis returned invalid audio.');
    }
    if (id == 'fmt ') {
      if (length < 16) {
        throw const FormatException(
          'Offline synthesis returned invalid audio.',
        );
      }
      final encoding = data.getUint16(content, Endian.little);
      final channels = data.getUint16(content + 2, Endian.little);
      final rate = data.getUint32(content + 4, Endian.little);
      final bits = data.getUint16(content + 14, Endian.little);
      validFormat = encoding == 1 && channels == 1 && bits == 16;
      if (rate < 8000 || rate > 48000) {
        throw const FormatException(
          'Offline synthesis returned invalid audio.',
        );
      }
      sampleRate = rate;
    } else if (id == 'data') {
      if (length.isOdd) {
        throw const FormatException(
          'Offline synthesis returned invalid audio.',
        );
      }
      pcm = Uint8List.fromList(wav.sublist(content, end));
    }
    offset = end + (length.isOdd ? 1 : 0);
  }
  if (!validFormat || sampleRate == null || pcm == null) {
    throw const FormatException('Offline synthesis returned invalid audio.');
  }
  return _DecodedPcmWav(pcm: pcm, sampleRate: sampleRate);
}

String _ascii(Uint8List bytes, int offset, int length) =>
    String.fromCharCodes(bytes.sublist(offset, offset + length));
