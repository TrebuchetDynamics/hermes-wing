package com.trebuchetdynamics.navivox.pairing

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PairingHandoffIntentParserTest {
    @Test
    fun directAppOpenClassifiesNavivoxConnectPayload() {
        val payload = "navivox://connect?base_url=http://127.0.0.1:8765&token=secret-token"

        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = payload,
            text = null,
        )

        assertEquals(
            PairingHandoffPayload(
                payload = payload,
                source = PairingHandoffPayload.Source.DirectAppOpen,
            ),
            parsed,
        )
        assertEquals(
            mapOf("payload" to payload, "source" to "direct_app_open"),
            parsed?.toMethodChannelMap(),
        )
    }

    @Test
    fun directAppOpenRejectsOtherUris() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = "https://example.invalid/navivox/connect?token=secret-token",
            text = null,
        )

        assertNull(parsed)
    }

    @Test
    fun directAppOpenRejectsNavivoxUrisWithOtherHosts() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = "navivox://connectevil?token=secret-token",
            text = null,
        )

        assertNull(parsed)
    }

    @Test
    fun sharedTextClassifiesTextPayloadAndTrimsOuterWhitespace() {
        val payload = "navivox://connect?base_url=http://127.0.0.1:8765&token=secret-token"

        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_SEND,
            type = "text/plain",
            data = null,
            text = "  $payload  ",
        )

        assertEquals(
            PairingHandoffPayload(
                payload = payload,
                source = PairingHandoffPayload.Source.SharedText,
            ),
            parsed,
        )
        assertEquals(
            mapOf("payload" to payload, "source" to "shared_text"),
            parsed?.toMethodChannelMap(),
        )
    }

    @Test
    fun sharedTextRejectsNonTextMimeTypes() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_SEND,
            type = "image/png",
            data = null,
            text = "navivox://connect?token=secret-token",
        )

        assertNull(parsed)
    }
}
