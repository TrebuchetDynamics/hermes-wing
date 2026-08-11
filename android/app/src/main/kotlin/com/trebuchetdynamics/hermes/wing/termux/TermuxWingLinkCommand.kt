package com.trebuchetdynamics.hermes.wing.termux

data class TermuxCommandSpec(
    val path: String,
    val arguments: List<String>,
    val workingDirectory: String = "~",
    val background: Boolean = true,
    val stdin: String? = null,
    val captureResult: Boolean = false,
)

object TermuxWingLinkCommand {
    fun forOperation(operation: String): TermuxCommandSpec? {
        val arguments = when (operation) {
            "status" -> listOf("status")
            "start" -> listOf("start")
            "setup" -> listOf("setup", "--json")
            else -> return null
        }
        return TermuxCommandSpec(
            path = "\$PREFIX/bin/wing-link",
            arguments = arguments,
        )
    }
}
