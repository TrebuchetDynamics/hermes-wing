package com.trebuchetdynamics.hermes.wing.pairing

internal class PairingQrOperationGate {
    var isPending: Boolean = false
        private set

    fun tryStart(
        launch: () -> Unit,
        onLaunchFailure: (Exception) -> Unit,
    ): Boolean {
        if (isPending) return false
        isPending = true
        try {
            launch()
        } catch (error: Exception) {
            isPending = false
            onLaunchFailure(error)
        }
        return true
    }

    fun finish() {
        isPending = false
    }
}
