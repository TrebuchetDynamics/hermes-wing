package com.trebuchetdynamics.hermes.wing.devicespeech

data class DeviceSpeechDiagnostics(
    val recognitionServices: List<String>,
    val microphonePermissionGranted: Boolean,
    val onDeviceRecognitionAvailable: Boolean,
) {
    fun toMethodChannelMap(): Map<String, Any?> {
        return mapOf(
            "recognitionServiceCount" to recognitionServices.size,
            "recognitionServices" to recognitionServices.take(10),
            "microphonePermissionGranted" to microphonePermissionGranted,
            "onDeviceRecognitionAvailable" to onDeviceRecognitionAvailable,
        )
    }
}
