package com.trebuchetdynamics.hermes.wing

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class LegacyIntentSignalTest {
    @Test
    fun `only retired view and plain text share metadata signals reconnection`() {
        assertTrue(LegacyIntentSignal.isLegacyInput("android.intent.action.VIEW", true, null))
        assertTrue(LegacyIntentSignal.isLegacyInput("android.intent.action.SEND", false, "text/plain"))
        assertTrue(LegacyIntentSignal.isLegacyInput("android.intent.action.SEND", false, "TEXT/PLAIN"))
        assertFalse(LegacyIntentSignal.isLegacyInput("android.intent.action.VIEW", false, null))
        assertFalse(LegacyIntentSignal.isLegacyInput("android.intent.action.SEND", false, "image/png"))
        assertFalse(LegacyIntentSignal.isLegacyInput("android.intent.action.MAIN", false, null))
        assertFalse(LegacyIntentSignal.isLegacyInput(null, false, null))
    }
}
