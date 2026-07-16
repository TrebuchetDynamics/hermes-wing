package com.trebuchetdynamics.hermes.wing.durablekeys

import org.junit.Assert.assertEquals
import org.junit.Test

class DurableKeyAliasTest {
    @Test
    fun parsesTrimmedDurableAlias() {
        val raw = "wing_durable_12345678901234567890123456789012"

        val alias = DurableKeyAlias.parse("  $raw  ")

        assertEquals(raw, alias.value)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsMissingAlias() {
        DurableKeyAlias.parse(null)
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsAliasWithWrongPrefix() {
        DurableKeyAlias.parse("other_12345678901234567890123456789012")
    }

    @Test(expected = IllegalArgumentException::class)
    fun rejectsAliasWithoutLongRandomSuffix() {
        DurableKeyAlias.parse("wing_durable_short")
    }
}
