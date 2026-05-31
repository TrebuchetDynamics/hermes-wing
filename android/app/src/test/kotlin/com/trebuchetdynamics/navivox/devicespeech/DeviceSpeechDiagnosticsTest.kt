package com.trebuchetdynamics.navivox.devicespeech

import org.junit.Assert.assertEquals
import org.junit.Test

class DeviceSpeechDiagnosticsTest {
    @Test
    fun exposesServiceCountServiceIdsAndMicrophonePermission() {
        val diagnostics = DeviceSpeechDiagnostics(
            recognitionServices = listOf("pkg.one/Service", "pkg.two/Service"),
            microphonePermissionGranted = true,
        )

        assertEquals(
            mapOf(
                "recognitionServiceCount" to 2,
                "recognitionServices" to listOf("pkg.one/Service", "pkg.two/Service"),
                "microphonePermissionGranted" to true,
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
        ).toMethodChannelMap()

        assertEquals(12, diagnostics["recognitionServiceCount"])
        assertEquals(serviceIds.take(10), diagnostics["recognitionServices"])
    }
}
