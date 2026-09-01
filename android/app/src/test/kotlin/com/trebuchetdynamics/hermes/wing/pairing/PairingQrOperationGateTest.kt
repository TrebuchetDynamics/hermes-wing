package com.trebuchetdynamics.hermes.wing.pairing

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PairingQrOperationGateTest {
    @Test
    fun synchronousLauncherFailureReleasesGateForRetry() {
        val gate = PairingQrOperationGate()
        val failures = mutableListOf<String>()

        assertTrue(
            gate.tryStart(
                launch = { error("scanner unavailable") },
                onLaunchFailure = { failures += it.message.orEmpty() },
            ),
        )

        assertFalse(gate.isPending)
        assertEquals(listOf("scanner unavailable"), failures)
        assertTrue(gate.tryStart(launch = {}, onLaunchFailure = {}))
    }

    @Test
    fun completionAndCancellationBothPermitAnotherScan() {
        val gate = PairingQrOperationGate()
        assertTrue(gate.tryStart(launch = {}, onLaunchFailure = {}))
        assertFalse(gate.tryStart(launch = {}, onLaunchFailure = {}))

        gate.finish()
        assertTrue(gate.tryStart(launch = {}, onLaunchFailure = {}))
        gate.finish()
        assertFalse(gate.isPending)
    }
}
