package com.trebuchetdynamics.hermes.wing

import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.junit.Assert.*
import org.junit.Test

class ManagedFileSaveJobTest {
    @Test fun exactReadbackIsRequiredForTextAndBinary() {
        for (bytes in listOf("hello\n".toByteArray(), byteArrayOf(0, -1, -128))) {
            val saved = ByteArrayOutputStream()
            assertArrayEquals(bytes, ManagedFileSaveJob().writeAndReadBack(bytes,
                { saved }, { ByteArrayInputStream(saved.toByteArray()) }))
            try {
                ManagedFileSaveJob().writeAndReadBack(bytes,
                    { ByteArrayOutputStream() }, { ByteArrayInputStream(byteArrayOf(1)) })
                fail("Corrupt readback must fail")
            } catch (_: IllegalStateException) { }
        }
    }

    @Test fun cancellationClosesStalledIOAndAllowsAnotherAttempt() {
        val started = CountDownLatch(1)
        val closed = CountDownLatch(1)
        val job = ManagedFileSaveJob()
        val executor = Executors.newSingleThreadExecutor()
        try {
            val result = executor.submit<Boolean> {
                try {
                    job.writeAndReadBack(byteArrayOf(1), { object : OutputStream() {
                        override fun write(value: Int) { started.countDown(); check(closed.await(5, TimeUnit.SECONDS)) }
                        override fun close() { closed.countDown() }
                    } }, { ByteArrayInputStream(byteArrayOf(1)) })
                    false
                } catch (_: IllegalStateException) { true }
            }
            assertTrue(started.await(5, TimeUnit.SECONDS))
            job.requestCancel()
            job.close()
            assertTrue(result.get(5, TimeUnit.SECONDS))
            assertArrayEquals(byteArrayOf(2), executor.submit<ByteArray> {
                ManagedFileSaveJob().writeAndReadBack(byteArrayOf(2),
                    { ByteArrayOutputStream() }, { ByteArrayInputStream(byteArrayOf(2)) })
            }.get(5, TimeUnit.SECONDS))
        } finally { executor.shutdownNow() }
    }
}
