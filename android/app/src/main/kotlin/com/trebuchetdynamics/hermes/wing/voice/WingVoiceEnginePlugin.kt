package com.trebuchetdynamics.hermes.wing.voice

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Owns microphone PCM below Flutter so DSP, cancellation, and generation
 * checks happen before bytes cross the platform boundary.
 */
class WingVoiceEnginePlugin(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val lock = Any()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newCachedThreadPool()
    private val playbackExecutor = Executors.newSingleThreadExecutor()
    private val methodChannel = MethodChannel(messenger, METHOD_CHANNEL)
    private val eventChannel = EventChannel(messenger, EVENT_CHANNEL)

    @Volatile
    private var eventSink: EventChannel.EventSink? = null
    private var activeGeneration: Long? = null
    private var activeRecord: AudioRecord? = null
    private var activeEffects: List<android.media.audiofx.AudioEffect> = emptyList()
    private var activePlaybackGeneration: Long? = null
    private var activeTrack: AudioTrack? = null
    private var disposed = false

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "capabilities" -> result.success(capabilities())
            "startCapture" -> startCapture(call, result)
            "stopCapture" -> stopCapture(call, result)
            "startPlayback" -> startPlayback(call, result)
            "writePlaybackPcm" -> writePlaybackPcm(call, result)
            "stopPlayback" -> stopPlayback(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopActiveCapture()
    }

    private fun capabilities(): Map<String, Any> = mapOf(
        "sampleRate" to SAMPLE_RATE,
        "aecAvailable" to AcousticEchoCanceler.isAvailable(),
        "noiseSuppressorAvailable" to NoiseSuppressor.isAvailable(),
        "automaticGainControlAvailable" to AutomaticGainControl.isAvailable(),
    )

    private fun startCapture(call: MethodCall, result: MethodChannel.Result) {
        val generation = (call.argument<Number>("generation"))?.toLong()
        if (generation == null || generation <= 0) {
            result.error("invalid_generation", "Voice capture generation is invalid.", null)
            return
        }
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.RECORD_AUDIO) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.error("microphone_permission", "Microphone permission is required.", null)
            return
        }

        val minimum = AudioRecord.getMinBufferSize(
            SAMPLE_RATE,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minimum <= 0) {
            result.error("audio_configuration", "Voice capture is unavailable.", null)
            return
        }
        val record = try {
            AudioRecord.Builder()
                .setAudioSource(MediaRecorder.AudioSource.VOICE_COMMUNICATION)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(AudioFormat.CHANNEL_IN_MONO)
                        .build(),
                )
                .setBufferSizeInBytes(maxOf(minimum * 2, FRAME_BYTES * 4))
                .build()
        } catch (_: Throwable) {
            result.error("audio_initialization", "Voice capture could not initialize.", null)
            return
        }
        if (record.state != AudioRecord.STATE_INITIALIZED) {
            record.release()
            result.error("audio_initialization", "Voice capture could not initialize.", null)
            return
        }

        synchronized(lock) {
            if (disposed || activeGeneration != null) {
                record.release()
                result.error("capture_pending", "Voice capture is already active.", null)
                return
            }
            activeGeneration = generation
            activeRecord = record
            activeEffects = createEffects(record.audioSessionId)
        }
        try {
            record.startRecording()
        } catch (_: Throwable) {
            invalidateAndRelease(generation, record)
            result.error("audio_start", "Voice capture could not start.", null)
            return
        }
        result.success(true)
        executor.execute { readLoop(generation, record) }
    }

    private fun stopCapture(call: MethodCall, result: MethodChannel.Result) {
        val generation = (call.argument<Number>("generation"))?.toLong()
        if (generation == null) {
            result.error("invalid_generation", "Voice capture generation is invalid.", null)
            return
        }
        val stopped = invalidateAndRelease(generation, null)
        result.success(stopped)
    }

    private fun startPlayback(call: MethodCall, result: MethodChannel.Result) {
        val generation = (call.argument<Number>("generation"))?.toLong()
        val sampleRate = (call.argument<Number>("sampleRate"))?.toInt()
        val channelCount = (call.argument<Number>("channelCount"))?.toInt()
        if (
            generation == null || generation <= 0 ||
            sampleRate == null || sampleRate !in MIN_PLAYBACK_RATE..MAX_PLAYBACK_RATE ||
            channelCount != 1
        ) {
            result.error("invalid_playback", "Voice playback configuration is invalid.", null)
            return
        }
        val minimum = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
        )
        if (minimum <= 0) {
            result.error("playback_configuration", "Voice playback is unavailable.", null)
            return
        }
        val track = try {
            AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ASSISTANT)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build(),
                )
                .setTransferMode(AudioTrack.MODE_STREAM)
                .setBufferSizeInBytes(maxOf(minimum * 2, PLAYBACK_BUFFER_BYTES))
                .setSessionId(AudioManager.AUDIO_SESSION_ID_GENERATE)
                .build()
        } catch (_: Throwable) {
            result.error("playback_initialization", "Voice playback could not initialize.", null)
            return
        }
        if (track.state != AudioTrack.STATE_INITIALIZED) {
            track.release()
            result.error("playback_initialization", "Voice playback could not initialize.", null)
            return
        }
        synchronized(lock) {
            if (disposed || activePlaybackGeneration != null) {
                track.release()
                result.error("playback_pending", "Voice playback is already active.", null)
                return
            }
            activePlaybackGeneration = generation
            activeTrack = track
        }
        try {
            track.play()
        } catch (_: Throwable) {
            invalidateAndReleasePlayback(generation, track)
            result.error("playback_start", "Voice playback could not start.", null)
            return
        }
        result.success(true)
    }

    private fun writePlaybackPcm(call: MethodCall, result: MethodChannel.Result) {
        val generation = (call.argument<Number>("generation"))?.toLong()
        val pcm16 = call.argument<ByteArray>("pcm16")
        if (generation == null || pcm16 == null || pcm16.isEmpty() || pcm16.size % 2 != 0) {
            result.error("invalid_playback_data", "Voice playback data is invalid.", null)
            return
        }
        val track = synchronized(lock) {
            if (activePlaybackGeneration == generation) activeTrack else null
        }
        if (track == null) {
            // A stop can overtake a queued Dart write. Treat already-invalidated
            // output as cancelled rather than surfacing a stale playback error.
            result.success(null)
            return
        }
        playbackExecutor.execute {
            val written = if (ownsPlayback(generation, track)) {
                try {
                    track.write(pcm16, 0, pcm16.size, AudioTrack.WRITE_BLOCKING)
                } catch (_: Throwable) {
                    AudioTrack.ERROR_INVALID_OPERATION
                }
            } else {
                0
            }
            mainHandler.post {
                if (!ownsPlayback(generation, track)) {
                    result.success(null)
                } else if (written == pcm16.size) {
                    result.success(null)
                } else {
                    schedulePlaybackRelease(generation, track) {
                        result.error("playback_write", "Voice playback stopped unexpectedly.", null)
                    }
                }
            }
        }
    }

    private fun stopPlayback(call: MethodCall, result: MethodChannel.Result) {
        val generation = (call.argument<Number>("generation"))?.toLong()
        if (generation == null) {
            result.error("invalid_generation", "Voice playback generation is invalid.", null)
            return
        }
        schedulePlaybackRelease(generation, null) { result.success(null) }
    }

    private fun readLoop(generation: Long, record: AudioRecord) {
        val buffer = ByteArray(FRAME_BYTES)
        while (owns(generation, record)) {
            val read = try {
                record.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING)
            } catch (_: Throwable) {
                AudioRecord.ERROR_INVALID_OPERATION
            }
            if (read <= 0) {
                if (owns(generation, record)) {
                    postErrorAndRelease(generation, record, "audio_read")
                    return
                }
                break
            }
            val chunk = buffer.copyOf(read)
            mainHandler.post {
                if (owns(generation, record)) {
                    eventSink?.success(
                        mapOf("generation" to generation, "pcm16" to chunk),
                    )
                }
            }
        }
        invalidateAndRelease(generation, record)
    }

    private fun postErrorAndRelease(
        generation: Long,
        record: AudioRecord,
        code: String,
    ) {
        mainHandler.post {
            if (owns(generation, record)) {
                try {
                    eventSink?.error(code, "Voice capture stopped unexpectedly.", null)
                } finally {
                    invalidateAndRelease(generation, record)
                }
            }
        }
    }

    private fun owns(generation: Long, record: AudioRecord): Boolean = synchronized(lock) {
        !disposed && activeGeneration == generation && activeRecord === record
    }

    private fun createEffects(sessionId: Int): List<android.media.audiofx.AudioEffect> {
        val effects = mutableListOf<android.media.audiofx.AudioEffect>()
        fun adopt(effect: android.media.audiofx.AudioEffect?) {
            if (effect == null) return
            try {
                effect.enabled = true
                effects += effect
            } catch (_: Throwable) {
                effect.release()
            }
        }
        if (AcousticEchoCanceler.isAvailable()) adopt(AcousticEchoCanceler.create(sessionId))
        if (NoiseSuppressor.isAvailable()) adopt(NoiseSuppressor.create(sessionId))
        // AGC availability is reported but it is not enabled by default because
        // gain pumping can degrade ASR and double-talk detection.
        return effects
    }

    private fun invalidateAndRelease(
        generation: Long,
        expectedRecord: AudioRecord?,
    ): Boolean {
        val record: AudioRecord
        val effects: List<android.media.audiofx.AudioEffect>
        synchronized(lock) {
            if (activeGeneration != generation) return false
            if (expectedRecord != null && activeRecord !== expectedRecord) return false
            record = activeRecord ?: return false
            // Invalidate ownership before invoking any platform teardown.
            activeGeneration = null
            activeRecord = null
            effects = activeEffects
            activeEffects = emptyList()
        }
        try {
            record.stop()
        } catch (_: Throwable) {
            // Release remains mandatory after a synchronous stop failure.
        }
        effects.forEach { effect ->
            try {
                effect.release()
            } catch (_: Throwable) {
                // Continue releasing the remaining resources.
            }
        }
        try {
            record.release()
        } catch (_: Throwable) {
            // Ownership is already invalidated and cannot be reused.
        }
        return true
    }

    private fun stopActiveCapture() {
        val generation = synchronized(lock) { activeGeneration } ?: return
        invalidateAndRelease(generation, null)
    }

    private fun ownsPlayback(generation: Long, track: AudioTrack): Boolean = synchronized(lock) {
        !disposed && activePlaybackGeneration == generation && activeTrack === track
    }

    private fun invalidateAndReleasePlayback(
        generation: Long,
        expectedTrack: AudioTrack?,
    ): Boolean {
        val track = invalidatePlayback(generation, expectedTrack) ?: return false
        releasePlayback(track)
        return true
    }

    private fun invalidatePlayback(
        generation: Long,
        expectedTrack: AudioTrack?,
    ): AudioTrack? {
        synchronized(lock) {
            if (activePlaybackGeneration != generation) return null
            if (expectedTrack != null && activeTrack !== expectedTrack) return null
            val track = activeTrack ?: return null
            // Invalidate ownership before platform teardown or queued writes.
            activePlaybackGeneration = null
            activeTrack = null
            return track
        }
    }

    private fun releasePlayback(track: AudioTrack) {
        try {
            track.pause()
        } catch (_: Throwable) {
            // Continue with flush, stop, and release.
        }
        try {
            track.flush()
        } catch (_: Throwable) {
            // Continue releasing this exact track.
        }
        try {
            track.stop()
        } catch (_: Throwable) {
            // Release remains mandatory after a synchronous stop failure.
        }
        try {
            track.release()
        } catch (_: Throwable) {
            // Ownership is invalidated and the track cannot be reused.
        }
    }

    private fun schedulePlaybackRelease(
        generation: Long,
        expectedTrack: AudioTrack?,
        onReleased: () -> Unit,
    ) {
        val track = invalidatePlayback(generation, expectedTrack)
        if (track == null) {
            onReleased()
            return
        }
        playbackExecutor.execute {
            releasePlayback(track)
            mainHandler.post(onReleased)
        }
    }

    private fun stopActivePlayback() {
        val generation = synchronized(lock) { activePlaybackGeneration } ?: return
        schedulePlaybackRelease(generation, null) {}
    }

    fun dispose() {
        synchronized(lock) {
            if (disposed) return
            disposed = true
        }
        stopActiveCapture()
        stopActivePlayback()
        eventSink = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        executor.shutdownNow()
        playbackExecutor.shutdown()
    }

    companion object {
        private const val METHOD_CHANNEL = "wing/voice_engine"
        private const val EVENT_CHANNEL = "wing/voice_engine/events"
        private const val SAMPLE_RATE = 16_000
        private const val FRAME_BYTES = 640 // 20 ms, mono PCM16 at 16 kHz.
        private const val PLAYBACK_BUFFER_BYTES = 3_840 // 80 ms, mono PCM16 at 24 kHz.
        private const val MIN_PLAYBACK_RATE = 8_000
        private const val MAX_PLAYBACK_RATE = 48_000
    }
}
