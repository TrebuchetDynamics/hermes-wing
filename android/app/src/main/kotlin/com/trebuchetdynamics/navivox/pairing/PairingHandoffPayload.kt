package com.trebuchetdynamics.navivox.pairing

data class PairingHandoffPayload(
    val payload: String,
    val source: Source,
) {
    enum class Source(val methodChannelValue: String) {
        DirectAppOpen("direct_app_open"),
        SharedText("shared_text"),
    }

    fun toMethodChannelMap(): Map<String, String> {
        return mapOf(
            "payload" to payload,
            "source" to source.methodChannelValue,
        )
    }
}
