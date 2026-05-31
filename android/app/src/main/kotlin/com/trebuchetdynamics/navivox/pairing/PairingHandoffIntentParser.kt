package com.trebuchetdynamics.navivox.pairing

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
        val payload = data?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        val uri = runCatching { URI(payload) }.getOrNull() ?: return null
        if (uri.scheme != "navivox" || uri.host != "connect") return null
        return PairingHandoffPayload(
            payload = payload,
            source = PairingHandoffPayload.Source.DirectAppOpen,
        )
    }

    private fun parseSharedText(type: String?, text: String?): PairingHandoffPayload? {
        if (!type.orEmpty().startsWith("text/")) return null
        val payload = text?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        return PairingHandoffPayload(
            payload = payload,
            source = PairingHandoffPayload.Source.SharedText,
        )
    }
}
