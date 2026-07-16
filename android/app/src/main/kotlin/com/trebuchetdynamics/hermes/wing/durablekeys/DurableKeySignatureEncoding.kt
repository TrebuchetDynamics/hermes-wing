package com.trebuchetdynamics.hermes.wing.durablekeys

import java.math.BigInteger

object DurableKeySignatureEncoding {
    fun derToJose(der: ByteArray): ByteArray {
        if (der.size < 8 || der[0] != 0x30.toByte()) {
            throw IllegalArgumentException("Invalid DER ECDSA signature")
        }
        var offset = 1
        val sequenceLength = readLength(der, offset)
        offset += sequenceLength.bytesRead
        if (sequenceLength.length != der.size - offset) {
            throw IllegalArgumentException("Invalid DER ECDSA sequence length")
        }
        val r = readInteger(der, offset)
        offset = r.nextOffset
        val s = readInteger(der, offset)
        if (s.nextOffset != der.size) {
            throw IllegalArgumentException("Unexpected trailing DER bytes")
        }
        return toFixedWidth(r.value) + toFixedWidth(s.value)
    }

    private fun readInteger(der: ByteArray, offset: Int): IntegerResult {
        if (offset >= der.size || der[offset] != 0x02.toByte()) {
            throw IllegalArgumentException("Invalid DER ECDSA integer")
        }
        val length = readLength(der, offset + 1)
        val valueStart = offset + 1 + length.bytesRead
        val valueEnd = valueStart + length.length
        if (valueEnd > der.size || length.length <= 0) {
            throw IllegalArgumentException("Invalid DER ECDSA integer length")
        }
        val value = der.copyOfRange(valueStart, valueEnd)
        if (value[0].toInt() and 0x80 != 0) {
            throw IllegalArgumentException("Invalid negative DER ECDSA integer")
        }
        return IntegerResult(
            value = value,
            nextOffset = valueEnd,
        )
    }

    private fun readLength(der: ByteArray, offset: Int): LengthResult {
        if (offset >= der.size) throw IllegalArgumentException("Missing DER length")
        val first = der[offset].toInt() and 0xff
        if (first and 0x80 == 0) return LengthResult(first, 1)
        val byteCount = first and 0x7f
        if (byteCount == 0 || byteCount > 2 || offset + byteCount >= der.size) {
            throw IllegalArgumentException("Invalid DER length")
        }
        var length = 0
        repeat(byteCount) { index ->
            length = (length shl 8) or (der[offset + 1 + index].toInt() and 0xff)
        }
        return LengthResult(length, 1 + byteCount)
    }

    fun p256CoordinateToBase64Url(value: BigInteger): String {
        return base64UrlNoPadding(value.toFixedWidth())
    }

    private fun toFixedWidth(value: ByteArray): ByteArray {
        return BigInteger(1, value).toFixedWidth()
    }

    private fun BigInteger.toFixedWidth(): ByteArray {
        if (signum() < 0) {
            throw IllegalArgumentException("P-256 integer must be non-negative")
        }
        val unsigned = toByteArray().dropWhile { it == 0.toByte() }.toByteArray()
        if (unsigned.size > 32) {
            throw IllegalArgumentException("P-256 integer is too large")
        }
        return ByteArray(32 - unsigned.size) + unsigned
    }

    private fun base64UrlNoPadding(bytes: ByteArray): String {
        val output = StringBuilder((bytes.size * 4 + 2) / 3)
        var index = 0
        while (index < bytes.size) {
            val first = bytes[index].toInt() and 0xff
            val hasSecond = index + 1 < bytes.size
            val hasThird = index + 2 < bytes.size
            val second = if (hasSecond) bytes[index + 1].toInt() and 0xff else 0
            val third = if (hasThird) bytes[index + 2].toInt() and 0xff else 0
            val chunk = (first shl 16) or (second shl 8) or third
            output.append(BASE64_URL_ALPHABET[(chunk ushr 18) and 0x3f])
            output.append(BASE64_URL_ALPHABET[(chunk ushr 12) and 0x3f])
            if (hasSecond) output.append(BASE64_URL_ALPHABET[(chunk ushr 6) and 0x3f])
            if (hasThird) output.append(BASE64_URL_ALPHABET[chunk and 0x3f])
            index += 3
        }
        return output.toString()
    }

    private const val BASE64_URL_ALPHABET =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

    private data class LengthResult(val length: Int, val bytesRead: Int)
    private data class IntegerResult(val value: ByteArray, val nextOffset: Int)
}
