package com.trebuchetdynamics.hermes.wing

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionService
import android.speech.SpeechRecognizer
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import com.google.mlkit.vision.common.InputImage
import com.trebuchetdynamics.hermes.wing.devicespeech.DeviceSpeechDiagnostics
import com.trebuchetdynamics.hermes.wing.durablekeys.DurableKeyStoreChannel
import com.trebuchetdynamics.hermes.wing.pairing.PairingHandoffIntentParser
import com.trebuchetdynamics.hermes.wing.pairing.PairingQrImagePolicy
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var initialConnectIntent: Map<String, String>? = null
    private var connectIntentEvents: EventChannel.EventSink? = null
    private var qrOperationPending = false
    private var qrImageResult: MethodChannel.Result? = null

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
                "importQrImage" -> importQrImage(result)
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

    @Deprecated("Deprecated in Android; retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != QR_IMAGE_REQUEST_CODE) return
        val result = qrImageResult ?: return
        val uri = data?.data
        if (resultCode != android.app.Activity.RESULT_OK || uri == null) {
            finishQrImage(result, null)
        } else {
            decodeQrImage(uri, result)
        }
    }

    private fun scanQrCode(result: MethodChannel.Result) {
        if (qrOperationPending) {
            result.error("qr_scan_pending", "A QR scan is already open.", null)
            return
        }
        qrOperationPending = true
        val options = GmsBarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .enableAutoZoom()
            .build()
        GmsBarcodeScanning.getClient(this, options).startScan()
            .addOnSuccessListener { barcode ->
                qrOperationPending = false
                val payload = barcode.rawValue?.trim()
                if (payload.isNullOrEmpty()) {
                    result.error("qr_scan_empty", "The QR code contained no text.", null)
                } else {
                    result.success(payload)
                }
            }
            .addOnCanceledListener {
                qrOperationPending = false
                result.success(null)
            }
            .addOnFailureListener { error ->
                qrOperationPending = false
                result.error(
                    "qr_scan_failed",
                    error.message ?: "Could not open the QR scanner.",
                    null,
                )
            }
    }

    private fun importQrImage(result: MethodChannel.Result) {
        if (qrOperationPending) {
            result.error("qr_scan_pending", "A QR operation is already open.", null)
            return
        }
        qrOperationPending = true
        qrImageResult = result
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "image/*"
            }
            @Suppress("DEPRECATION")
            startActivityForResult(intent, QR_IMAGE_REQUEST_CODE)
        } catch (error: Exception) {
            finishQrImageError(
                result,
                "qr_image_picker_failed",
                error.message ?: "Could not open the image picker.",
            )
        }
    }

    private fun decodeQrImage(uri: Uri, result: MethodChannel.Result) {
        val mimeType = try {
            contentResolver.getType(uri)
        } catch (_: Exception) {
            null
        }
        val localImage = try {
            copyQrImageToBoundedCache(uri)
        } catch (_: Exception) {
            finishQrImageError(result, "qr_image_unreadable", "Could not read the selected image.")
            return
        }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(localImage.path, bounds)
        if (!PairingQrImagePolicy.accepts(
                mimeType,
                localImage.length(),
                bounds.outWidth,
                bounds.outHeight,
            )
        ) {
            localImage.delete()
            finishQrImageError(
                result,
                "qr_image_rejected",
                "Choose a bounded image containing a QR code.",
            )
            return
        }
        val image = try {
            InputImage.fromFilePath(this, Uri.fromFile(localImage))
        } catch (_: Exception) {
            localImage.delete()
            finishQrImageError(result, "qr_image_unreadable", "Could not read the selected image.")
            return
        }
        val options = BarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .build()
        val scanner = BarcodeScanning.getClient(options)
        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                val payload = barcodes.firstNotNullOfOrNull { barcode ->
                    barcode.rawValue?.trim()?.takeIf { it.isNotEmpty() }
                }
                if (payload == null) {
                    finishQrImageError(
                        result,
                        "qr_image_empty",
                        "The selected image did not contain a readable QR code.",
                    )
                } else {
                    finishQrImage(result, payload)
                }
            }
            .addOnFailureListener { error ->
                finishQrImageError(
                    result,
                    "qr_image_decode_failed",
                    error.message ?: "Could not decode the selected image.",
                )
            }
            .addOnCompleteListener {
                scanner.close()
                localImage.delete()
            }
    }

    private fun copyQrImageToBoundedCache(uri: Uri): File {
        val target = File.createTempFile("pairing-qr-", ".image", cacheDir)
        try {
            val input = contentResolver.openInputStream(uri)
                ?: throw IllegalArgumentException("Selected image is unavailable")
            input.use { source ->
                target.outputStream().use { destination ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var copied = 0L
                    while (true) {
                        val count = source.read(buffer)
                        if (count < 0) break
                        copied += count
                        if (copied > PairingQrImagePolicy.MAX_ENCODED_BYTES) {
                            throw IllegalArgumentException("Selected image is too large")
                        }
                        destination.write(buffer, 0, count)
                    }
                }
            }
            return target
        } catch (error: Exception) {
            target.delete()
            throw error
        }
    }

    private fun finishQrImage(result: MethodChannel.Result, payload: String?) {
        if (qrImageResult !== result) return
        qrImageResult = null
        qrOperationPending = false
        result.success(payload)
    }

    private fun finishQrImageError(
        result: MethodChannel.Result,
        code: String,
        message: String,
    ) {
        if (qrImageResult !== result) return
        qrImageResult = null
        qrOperationPending = false
        result.error(code, message, null)
    }

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
        private const val QR_IMAGE_REQUEST_CODE = 41027
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
