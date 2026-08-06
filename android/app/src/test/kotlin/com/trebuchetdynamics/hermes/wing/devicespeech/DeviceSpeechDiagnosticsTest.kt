package com.trebuchetdynamics.hermes.wing.devicespeech

import org.junit.Assert.assertEquals
import org.junit.Test

class DeviceSpeechDiagnosticsTest {
    @Test
    fun exposesServiceCountServiceIdsAndMicrophonePermission() {
        val diagnostics = DeviceSpeechDiagnostics(
            recognitionServices = listOf("pkg.one/Service", "pkg.two/Service"),
            microphonePermissionGranted = true,
            onDeviceRecognitionAvailable = true,
        )

        assertEquals(
            mapOf(
                "recognitionServiceCount" to 2,
                "recognitionServices" to listOf("pkg.one/Service", "pkg.two/Service"),
                "microphonePermissionGranted" to true,
                "onDeviceRecognitionAvailable" to true,
            ),
            diagnostics.toMethodChannelMap(),
        )
    }

    @Test
    fun limitsReportedServiceIdsButKeepsFullCount() {
        val serviceIds = (1..12).map { "pkg.$it/Service" }

        val diagnostics = DeviceSpeechDiagnostics(
            recognitionServices = serviceIds,
            microphonePermissionGranted = false,
            onDeviceRecognitionAvailable = false,
        ).toMethodChannelMap()

        assertEquals(12, diagnostics["recognitionServiceCount"])
        assertEquals(serviceIds.take(10), diagnostics["recognitionServices"])
    }
}
