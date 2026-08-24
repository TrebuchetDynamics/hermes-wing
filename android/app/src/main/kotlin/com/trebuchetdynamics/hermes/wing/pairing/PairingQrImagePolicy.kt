package com.trebuchetdynamics.hermes.wing.pairing

import java.util.Locale

internal object PairingQrImagePolicy {
    const val MAX_ENCODED_BYTES = 20L * 1024L * 1024L
    const val MAX_DIMENSION = 8192
    const val MAX_PIXELS = 25_000_000L

    fun accepts(
        mimeType: String?,
        encodedBytes: Long?,
        width: Int,
        height: Int,
    ): Boolean {
        if (mimeType?.lowercase(Locale.ROOT)?.startsWith("image/") != true) return false
        if (encodedBytes != null && encodedBytes >= 0L && encodedBytes !in 1..MAX_ENCODED_BYTES) {
            return false
        }
        if (width !in 1..MAX_DIMENSION || height !in 1..MAX_DIMENSION) return false
        return width.toLong() * height.toLong() <= MAX_PIXELS
    }
}
