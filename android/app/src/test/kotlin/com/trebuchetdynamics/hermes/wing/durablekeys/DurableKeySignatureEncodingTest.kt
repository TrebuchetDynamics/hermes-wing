package com.trebuchetdynamics.hermes.wing.durablekeys

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test
import java.math.BigInteger

class DurableKeySignatureEncodingTest {
    @Test
    fun convertsDerEcdsaSignatureToJoseRawSignature() {
        val r = ByteArray(32) { 0x11 }
        val s = ByteArray(32) { 0x22 }
        val der = byteArrayOf(
            0x30,
            0x44,
            0x02,
            0x20,
            *r,
            0x02,
            0x20,
            *s,
        )

        val jose = DurableKeySignatureEncoding.derToJose(der)

        assertEquals(64, jose.size)
        assertArrayEquals(r + s, jose)
    }

    @Test
    fun stripsPositiveIntegerPaddingAndPadsShortValues() {
        val r = byteArrayOf(0x00, 0x80.toByte())
        val s = byteArrayOf(0x01)
        val der = byteArrayOf(
            0x30,
            0x07,
            0x02,
            0x02,
            *r,
            0x02,
            0x01,
            *s,
        )

        val jose = DurableKeySignatureEncoding.derToJose(der)

        assertEquals(64, jose.size)
        assertEquals(0x80.toByte(), jose[31])
        assertEquals(0x01.toByte(), jose[63])
    }

    @Test
    fun encodesP256CoordinatesAsPaddedBase64UrlWithoutPadding() {
        val encoded = DurableKeySignatureEncoding.p256CoordinateToBase64Url(BigInteger.ONE)

        assertEquals("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE", encoded)
        assertFalse(encoded.contains("="))
        assertFalse(encoded.contains("+"))
        assertFalse(encoded.contains("/"))
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsOversizedP256Coordinates() {
        DurableKeySignatureEncoding.p256CoordinateToBase64Url(BigInteger.ONE.shiftLeft(256))
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsNegativeP256Coordinates() {
        DurableKeySignatureEncoding.p256CoordinateToBase64Url(BigInteger.valueOf(-1))
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsNegativeDerIntegers() {
        DurableKeySignatureEncoding.derToJose(
            byteArrayOf(
                0x30,
                0x06,
                0x02,
                0x01,
                0x80.toByte(),
                0x02,
                0x01,
                0x01,
            ),
        )
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsMalformedDer() {
        DurableKeySignatureEncoding.derToJose(byteArrayOf(0x01, 0x02, 0x03))
    }
}
