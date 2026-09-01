package com.trebuchetdynamics.hermes.wing.pairing

import java.net.URI

object PairingHandoffIntentParser {
    const val ACTION_VIEW = "android.intent.action.VIEW"
    const val ACTION_SEND = "android.intent.action.SEND"
    const val EXTRA_TEXT = "android.intent.extra.TEXT"

    fun parse(
        action: String?,
        type: String?,
        data: String?,
        text: String?,
    ): PairingHandoffPayload? {
        return when (action) {
            ACTION_VIEW -> parseDirectAppOpen(data)
            ACTION_SEND -> parseSharedText(type, text)
            else -> null
        }
    }

    private fun parseDirectAppOpen(data: String?): PairingHandoffPayload? {
        if (data == null || data.length > MAX_HANDOFF_INPUT_LENGTH) return null
        val payload = data.trim().takeIf { it.isNotEmpty() } ?: return null
        val uri = runCatching { URI(payload) }.getOrNull() ?: return null
        if (!uri.isWingConnectUri()) return null
        return PairingHandoffPayload(
            payload = payload,
            source = PairingHandoffPayload.Source.DirectAppOpen,
        )
    }

    private fun URI.isWingConnectUri(): Boolean {
        return scheme.equalsIgnoringCase(WING_SCHEME) &&
            host.equalsIgnoringCase(WING_CONNECT_HOST)
    }

    private fun String?.equalsIgnoringCase(expected: String): Boolean {
        return this?.equals(expected, ignoreCase = true) == true
    }

    private const val WING_SCHEME = "wing"
    private const val WING_CONNECT_HOST = "connect"

    private fun parseSharedText(type: String?, text: String?): PairingHandoffPayload? {
        if (!type.isPlainTextMimeType()) return null
        if (text == null || text.length > MAX_HANDOFF_INPUT_LENGTH) return null
        val payload = text.trim().takeIf { it.isNotEmpty() } ?: return null
        return PairingHandoffPayload(
            payload = payload,
            source = PairingHandoffPayload.Source.SharedText,
        )
    }

    private fun String?.isPlainTextMimeType(): Boolean {
        return equals(TEXT_PLAIN_MIME_TYPE, ignoreCase = true)
    }

    private const val TEXT_PLAIN_MIME_TYPE = "text/plain"
    private const val MAX_HANDOFF_INPUT_LENGTH = 4096
}
