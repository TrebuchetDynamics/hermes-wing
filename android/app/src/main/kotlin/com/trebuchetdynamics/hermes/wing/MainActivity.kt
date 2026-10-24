package com.trebuchetdynamics.hermes.wing

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionService
import android.speech.SpeechRecognizer
import com.trebuchetdynamics.hermes.wing.devicespeech.DeviceSpeechDiagnostics
import com.trebuchetdynamics.hermes.wing.durablekeys.DurableKeyStoreChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var managedFileSave: ManagedFileSaveChannel? = null
    private var initialConnectInput = false
    private var connectIntentEvents: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        initialConnectInput = hasLegacyInput(intent)
        // Flutter and plugins receive no retired URI, shared text or ClipData.
        if (initialConnectInput) setIntent(Intent(Intent.ACTION_MAIN))
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        managedFileSave = ManagedFileSaveChannel(this).also { handler ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
                "com.trebuchetdynamics.hermes.wing/managed_file_save",
            ).setMethodCallHandler(handler)
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CONNECT_INTENTS_METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeInitialConnectIntent" -> result.success(
                    initialConnectInput.also { initialConnectInput = false },
                )
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_SPEECH_METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "diagnostics" -> result.success(deviceSpeechDiagnostics())
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DURABLE_KEYS_METHOD_CHANNEL,
        ).setMethodCallHandler(DurableKeyStoreChannel())
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CONNECT_INTENTS_EVENT_CHANNEL,
        ).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    connectIntentEvents = events
                }

                override fun onCancel(arguments: Any?) {
                    connectIntentEvents = null
                }
            },
        )
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (managedFileSave?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        managedFileSave?.dispose()
        managedFileSave = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        val input = hasLegacyInput(intent)
        val safeIntent = if (input) Intent(Intent.ACTION_MAIN) else intent
        super.onNewIntent(safeIntent)
        setIntent(safeIntent)
        initialConnectInput = input
        if (input) connectIntentEvents?.success(true)
    }

    private fun hasLegacyInput(intent: Intent?): Boolean =
        intent != null && LegacyIntentSignal.isLegacyInput(
            action = intent.action,
            hasData = intent.data != null,
            type = intent.type,
        )

    private fun deviceSpeechDiagnostics(): Map<String, Any?> {
        val services = querySpeechRecognitionServices()
        return DeviceSpeechDiagnostics(
            recognitionServices = services.mapNotNull { service ->
                val info = service.serviceInfo ?: return@mapNotNull null
                "${info.packageName}/${info.name}"
            },
            microphonePermissionGranted = isMicrophonePermissionGranted(),
            onDeviceRecognitionAvailable = isOnDeviceRecognitionAvailable(),
        ).toMethodChannelMap()
    }

    private fun querySpeechRecognitionServices(): List<android.content.pm.ResolveInfo> {
        val recognitionIntent = Intent(RecognitionService.SERVICE_INTERFACE)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentServices(
                recognitionIntent,
                PackageManager.ResolveInfoFlags.of(0),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentServices(recognitionIntent, 0)
        }
    }

    private fun isOnDeviceRecognitionAvailable(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
            SpeechRecognizer.isOnDeviceRecognitionAvailable(this)
    }

    private fun isMicrophonePermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    companion object {
        private const val CONNECT_INTENTS_METHOD_CHANNEL =
            "com.trebuchetdynamics.hermes.wing/connect_intents"
        private const val CONNECT_INTENTS_EVENT_CHANNEL =
            "com.trebuchetdynamics.hermes.wing/connect_intents/events"
        private const val DEVICE_SPEECH_METHOD_CHANNEL =
            "com.trebuchetdynamics.hermes.wing/device_speech"
        private const val DURABLE_KEYS_METHOD_CHANNEL =
            "com.trebuchetdynamics.hermes.wing/durable_keys"
    }
}
