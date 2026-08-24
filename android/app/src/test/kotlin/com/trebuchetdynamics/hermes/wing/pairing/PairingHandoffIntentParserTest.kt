package com.trebuchetdynamics.hermes.wing.pairing

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class PairingHandoffIntentParserTest {
    @Test
    fun directAppOpenClassifiesWingConnectPayload() {
        val payload = "wing://connect?base_url=http://127.0.0.1:8765&token=secret-token"

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
    fun directAppOpenMatchesSchemeAndHostCaseInsensitively() {
        val payload = "WING://CONNECT?base_url=http://127.0.0.1:8765&token=secret-token"

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
    }

    @Test
    fun directAppOpenAtTheLimitIsAccepted() {
        val prefix = "wing://connect?code="
        val payload = prefix + "x".repeat(4096 - prefix.length)

        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = payload,
            text = null,
        )

        assertEquals(payload, parsed?.payload)
    }

    @Test
    fun oversizedDirectAppOpenIsRejected() {
        val prefix = "wing://connect?code="
        val payload = prefix + "x".repeat(4097 - prefix.length)

        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = payload,
            text = null,
        )

        assertNull(parsed)
    }

    @Test
    fun directAppOpenRejectsOtherUris() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = "https://example.invalid/wing/connect?token=secret-token",
            text = null,
        )

        assertNull(parsed)
    }

    @Test
    fun directAppOpenRejectsWingUrisWithOtherHosts() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = "wing://connectevil?token=secret-token",
            text = null,
        )

        assertNull(parsed)
    }

    @Test
    fun directAppOpenRejectsWingUrisWithoutAuthority() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_VIEW,
            type = null,
            data = "wing:connect?token=secret-token",
            text = null,
        )

        assertNull(parsed)
    }

    @Test
    fun sharedTextClassifiesTextPayloadAndTrimsOuterWhitespace() {
        val payload = "wing://connect?base_url=http://127.0.0.1:8765&token=secret-token"

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
    fun sharedTextMatchesMimeTypeCaseInsensitively() {
        val payload = "wing://connect?base_url=http://127.0.0.1:8765&token=secret-token"

        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_SEND,
            type = "Text/Plain",
            data = null,
            text = payload,
        )

        assertEquals(
            PairingHandoffPayload(
                payload = payload,
                source = PairingHandoffPayload.Source.SharedText,
            ),
            parsed,
        )
    }

    @Test
    fun oversizedSharedTextIsRejected() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_SEND,
            type = "text/plain",
            data = null,
            text = "x".repeat(4097),
        )

        assertNull(parsed)
    }

    @Test
    fun sharedTextAtTheLimitIsAccepted() {
        val payload = "x".repeat(4096)
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_SEND,
            type = "text/plain",
            data = null,
            text = payload,
        )

        assertEquals(payload, parsed?.payload)
    }

    @Test
    fun sharedTextRejectsBlankPayloads() {
        val parsed = PairingHandoffIntentParser.parse(
            action = PairingHandoffIntentParser.ACTION_SEND,
            type = "text/plain",
            data = null,
            text = "  \n  ",
        )

        assertNull(parsed)
    }

    @Test
    fun sharedTextRejectsNonPlainTextMimeTypes() {
        for (type in listOf("image/png", "text/html")) {
            val parsed = PairingHandoffIntentParser.parse(
                action = PairingHandoffIntentParser.ACTION_SEND,
                type = type,
                data = null,
                text = "wing://connect?token=secret-token",
            )

            assertNull(parsed)
        }
    }
}
