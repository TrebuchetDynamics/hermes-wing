package com.trebuchetdynamics.hermes.wing.pairing

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PairingQrImagePolicyTest {
    @Test
    fun acceptsBoundedImagesIncludingUnknownProviderSize() {
        assertTrue(PairingQrImagePolicy.accepts("image/png", 1024, 1200, 1200))
        assertTrue(PairingQrImagePolicy.accepts("IMAGE/JPEG", null, 800, 800))
        assertTrue(PairingQrImagePolicy.accepts("image/webp", -1, 800, 800))
    }

    @Test
    fun rejectsNonImagesOversizedFilesAndDecompressionBounds() {
        assertFalse(PairingQrImagePolicy.accepts("application/pdf", 1024, 1200, 1200))
        assertFalse(
            PairingQrImagePolicy.accepts(
                "image/png",
                PairingQrImagePolicy.MAX_ENCODED_BYTES + 1,
                1200,
                1200,
            ),
        )
        assertFalse(PairingQrImagePolicy.accepts("image/png", 1024, 8193, 100))
        assertFalse(PairingQrImagePolicy.accepts("image/png", 1024, 6000, 6000))
        assertFalse(PairingQrImagePolicy.accepts("image/png", 0, 1200, 1200))
    }
}
