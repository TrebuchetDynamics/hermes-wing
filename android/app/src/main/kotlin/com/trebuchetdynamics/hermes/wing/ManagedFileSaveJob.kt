package com.trebuchetdynamics.hermes.wing

import java.io.ByteArrayOutputStream
import java.io.Closeable
import java.io.InputStream
import java.io.OutputStream

/** Attempt-owned I/O. Closing a cancelled job interrupts its open stream. */
class ManagedFileSaveJob : Closeable {
    @Volatile var cancelled = false
        private set
    @Volatile private var stream: Closeable? = null

    fun requestCancel() { cancelled = true }

    override fun close() {
        requestCancel()
        stream?.close()
    }

    fun writeAndReadBack(
        bytes: ByteArray,
        openOutput: () -> OutputStream,
        openInput: () -> InputStream,
    ): ByteArray {
        check(!cancelled && bytes.size <= MAX_BYTES)
        useStream(openOutput) { output ->
            var offset = 0
            while (offset < bytes.size) {
                check(!cancelled)
                val count = minOf(65536, bytes.size - offset)
                output.write(bytes, offset, count)
                offset += count
            }
            check(!cancelled)
            output.flush()
        }
        check(!cancelled)
        val actual = useStream(openInput) { input ->
            val readback = ByteArrayOutputStream()
            val buffer = ByteArray(65536)
            while (true) {
                check(!cancelled)
                val count = input.read(buffer)
                if (count < 0) break
                check(readback.size() + count <= MAX_BYTES)
                readback.write(buffer, 0, count)
            }
            readback.toByteArray()
        }
        check(!cancelled && actual.contentEquals(bytes))
        return actual
    }

    private fun <T : Closeable, R> useStream(open: () -> T, action: (T) -> R): R {
        val resource = open()
        stream = resource
        try {
            check(!cancelled)
            return action(resource)
        } finally {
            try { resource.close() } finally { stream = null }
        }
    }

    companion object { const val MAX_BYTES = 8 * 1024 * 1024 }
}
