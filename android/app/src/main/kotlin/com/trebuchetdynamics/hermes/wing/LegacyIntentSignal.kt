package com.trebuchetdynamics.hermes.wing

/** Classifies retired ingress using metadata only, never URI or shared-text contents. */
internal object LegacyIntentSignal {
    fun isLegacyInput(action: String?, hasData: Boolean, type: String?): Boolean =
        when (action) {
            "android.intent.action.VIEW" -> hasData
            "android.intent.action.SEND" -> type.equals("text/plain", ignoreCase = true)
            else -> false
        }
}
