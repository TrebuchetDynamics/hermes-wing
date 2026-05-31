package com.trebuchetdynamics.navivox.durablekeys

@JvmInline
value class DurableKeyAlias private constructor(val value: String) {
    companion object {
        private const val PREFIX = "navivox_durable_"
        private const val MIN_RANDOM_SUFFIX_LENGTH = 32

        fun parse(raw: String?): DurableKeyAlias {
            val alias = raw?.trim().orEmpty()
            if (!alias.startsWith(PREFIX) || alias.length < PREFIX.length + MIN_RANDOM_SUFFIX_LENGTH) {
                throw IllegalArgumentException("A durable key alias is required")
            }
            return DurableKeyAlias(alias)
        }
    }
}
