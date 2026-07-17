package com.trebuchetdynamics.hermes.wing

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionService
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import com.trebuchetdynamics.hermes.wing.devicespeech.DeviceSpeechDiagnostics
import com.trebuchetdynamics.hermes.wing.durablekeys.DurableKeyStoreChannel
import com.trebuchetdynamics.hermes.wing.pairing.PairingHandoffIntentParser
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var initialConnectIntent: Map<String, String>? = null
    private var connectIntentEvents: EventChannel.EventSink? = null
    private var qrScanPending = false

    override fun onCreate(savedInstanceState: Bundle?) {
        initialConnectIntent = connectPayloadFrom(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CONNECT_INTENTS_METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialConnectIntent" -> result.success(
                    initialConnectIntent ?: connectPayloadFrom(intent),
                )
                "scanQrCode" -> scanQrCode(result)
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val payload = connectPayloadFrom(intent) ?: return
        initialConnectIntent = payload
        connectIntentEvents?.success(payload)
    }

    private fun scanQrCode(result: MethodChannel.Result) {
        if (qrScanPending) {
            result.error("qr_scan_pending", "A QR scan is already open.", null)
            return
        }
        qrScanPending = true
        val options = GmsBarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .enableAutoZoom()
            .build()
        GmsBarcodeScanning.getClient(this, options).startScan()
            .addOnSuccessListener { barcode ->
                qrScanPending = false
                val payload = barcode.rawValue?.trim()
                if (payload.isNullOrEmpty()) {
                    result.error("qr_scan_empty", "The QR code contained no text.", null)
                } else {
                    result.success(payload)
                }
            }
            .addOnCanceledListener {
                qrScanPending = false
                result.success(null)
            }
            .addOnFailureListener { error ->
                qrScanPending = false
                result.error(
                    "qr_scan_failed",
                    error.message ?: "Could not open the QR scanner.",
                    null,
                )
            }
    }

    private fun deviceSpeechDiagnostics(): Map<String, Any?> {
        val services = querySpeechRecognitionServices()
        return DeviceSpeechDiagnostics(
            recognitionServices = services.mapNotNull { service ->
                val info = service.serviceInfo ?: return@mapNotNull null
                "${info.packageName}/${info.name}"
            },
            microphonePermissionGranted = isMicrophonePermissionGranted(),
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

    private fun isMicrophonePermissionGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun connectPayloadFrom(intent: Intent?): Map<String, String>? {
        if (intent == null) return null
        return PairingHandoffIntentParser.parse(
            action = intent.action,
            type = intent.type,
            data = intent.data?.toString(),
            text = intent.getStringExtra(Intent.EXTRA_TEXT),
        )?.toMethodChannelMap()
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
