package com.trebuchetdynamics.hermes.wing.voicefixture

import android.content.Intent
import android.media.AudioFormat
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionService
import android.speech.SpeechRecognizer
import android.speech.tts.SynthesisCallback
import android.speech.tts.SynthesisRequest
import android.speech.tts.TextToSpeech
import android.speech.tts.TextToSpeechService

/** Deterministic Android voice services installed only during headless tests. */
class HeadlessSpeechRecognitionService : RecognitionService() {
    private val handler = Handler(Looper.getMainLooper())

    override fun onStartListening(intent: Intent?, callback: Callback) {
        val preferences = getSharedPreferences("headless_voice_test", MODE_PRIVATE)
        val index = preferences.getInt("recognition_index", 0)
        preferences.edit().putInt("recognition_index", index + 1).apply()
        val transcript = listOf(
            "android first voice",
            "android second voice",
            "navi stop listening",
        ).getOrElse(index) { "navi stop listening" }

        callback.readyForSpeech(Bundle())
        handler.postDelayed({
            callback.beginningOfSpeech()
            callback.endOfSpeech()
            callback.results(Bundle().apply {
                putStringArrayList(
                    SpeechRecognizer.RESULTS_RECOGNITION,
                    arrayListOf(transcript),
                )
                putFloatArray(SpeechRecognizer.CONFIDENCE_SCORES, floatArrayOf(0.95f))
            })
        }, 150)
    }

    override fun onStopListening(callback: Callback) = Unit

    override fun onCancel(callback: Callback) = Unit
}

/** Silent TTS engine whose completion still crosses Android's TTS API. */
class HeadlessTextToSpeechService : TextToSpeechService() {
    override fun onIsLanguageAvailable(
        language: String?,
        country: String?,
        variant: String?,
    ): Int = TextToSpeech.LANG_COUNTRY_AVAILABLE

    override fun onLoadLanguage(
        language: String?,
        country: String?,
        variant: String?,
    ): Int = TextToSpeech.LANG_COUNTRY_AVAILABLE

    override fun onGetLanguage(): Array<String> = arrayOf("eng", "USA", "")

    override fun onSynthesizeText(
        request: SynthesisRequest,
        callback: SynthesisCallback,
    ) {
        if (callback.start(16_000, AudioFormat.ENCODING_PCM_16BIT, 1) == TextToSpeech.ERROR) {
            return
        }
        callback.audioAvailable(ByteArray(320), 0, 320)
        callback.done()
    }

    override fun onStop() = Unit
}
