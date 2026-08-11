package com.trebuchetdynamics.hermes.wing.termux

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class TermuxWingLinkCommandTest {
    @Test
    fun mapsOnlyBoundedWingLinkOperations() {
        assertEquals(listOf("status"), TermuxWingLinkCommand.forOperation("status")?.arguments)
        assertEquals(listOf("start"), TermuxWingLinkCommand.forOperation("start")?.arguments)
        assertEquals(listOf("setup", "--json"), TermuxWingLinkCommand.forOperation("setup")?.arguments)

        assertNull(TermuxWingLinkCommand.forOperation("stop"))
        assertNull(TermuxWingLinkCommand.forOperation("bash"))
        assertNull(TermuxWingLinkCommand.forOperation("setup --profile work"))
    }

    @Test
    fun commandUsesFixedPrivateTermuxPathsAndNoInputCapture() {
        val command = requireNotNull(TermuxWingLinkCommand.forOperation("setup"))

        assertEquals("\$PREFIX/bin/wing-link", command.path)
        assertEquals("~", command.workingDirectory)
        assertTrue(command.background)
        assertNull(command.stdin)
        assertTrue(command.captureResult.not())
    }
}
