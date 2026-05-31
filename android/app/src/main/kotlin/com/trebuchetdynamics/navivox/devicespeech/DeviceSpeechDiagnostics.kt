package com.trebuchetdynamics.navivox.devicespeech

data class DeviceSpeechDiagnostics(
    val recognitionServices: List<String>,
    val microphonePermissionGranted: Boolean,
) {
    fun toMethodChannelMap(): Map<String, Any?> {
        return mapOf(
            "recognitionServiceCount" to recognitionServices.size,
            "recognitionServices" to recognitionServices.take(10),
            "microphonePermissionGranted" to microphonePermissionGranted,
        )
    }
}
