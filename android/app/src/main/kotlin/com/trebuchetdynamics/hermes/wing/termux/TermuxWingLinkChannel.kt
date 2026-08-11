package com.trebuchetdynamics.hermes.wing.termux

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class TermuxWingLinkChannel(
    private val context: Context,
) : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "availability" -> result.success(
                mapOf(
                    "termux_installed" to isTermuxInstalled(),
                    "run_command_permission_granted" to isRunCommandPermissionGranted(),
                ),
            )
            "dispatch" -> dispatch(call.argument<String>("operation"), result)
            else -> result.notImplemented()
        }
    }

    private fun dispatch(operation: String?, result: MethodChannel.Result) {
        val command = operation?.let(TermuxWingLinkCommand::forOperation)
        if (command == null) {
            result.error("termux_operation_unsupported", "Wing Link operation is not supported.", null)
            return
        }
        if (!isTermuxInstalled()) {
            result.error("termux_not_installed", "Termux is not installed.", null)
            return
        }
        if (!isRunCommandPermissionGranted()) {
            result.error(
                "termux_permission_required",
                "Allow Hermes Wing to run commands in the Termux app permissions.",
                null,
            )
            return
        }

        val intent = Intent().apply {
            setClassName(TERMUX_PACKAGE, TERMUX_RUN_COMMAND_SERVICE)
            action = ACTION_RUN_COMMAND
            putExtra(EXTRA_COMMAND_PATH, command.path)
            putExtra(EXTRA_ARGUMENTS, command.arguments.toTypedArray())
            putExtra(EXTRA_WORKDIR, command.workingDirectory)
            putExtra(EXTRA_BACKGROUND, command.background)
            putExtra(EXTRA_COMMAND_LABEL, "Hermes Wing: Wing Link ${operation}")
            putExtra(
                EXTRA_COMMAND_DESCRIPTION,
                "Runs a fixed Wing Link host-supervisor operation. No shell or arbitrary arguments are accepted.",
            )
        }
        try {
            if (context.startService(intent) == null) {
                result.error("termux_dispatch_failed", "Termux did not accept the command.", null)
                return
            }
            result.success(mapOf("dispatched" to true))
        } catch (_: SecurityException) {
            result.error(
                "termux_permission_required",
                "Grant RUN_COMMAND and set allow-external-apps=true in Termux.",
                null,
            )
        } catch (_: RuntimeException) {
            result.error("termux_dispatch_failed", "Could not dispatch the Wing Link command.", null)
        }
    }

    private fun isTermuxInstalled(): Boolean = try {
        context.packageManager.getApplicationInfo(TERMUX_PACKAGE, 0)
        true
    } catch (_: PackageManager.NameNotFoundException) {
        false
    }

    private fun isRunCommandPermissionGranted(): Boolean =
        context.checkSelfPermission(RUN_COMMAND_PERMISSION) == PackageManager.PERMISSION_GRANTED

    companion object {
        const val CHANNEL_NAME = "com.trebuchetdynamics.hermes.wing/termux_wing_link"

        private const val TERMUX_PACKAGE = "com.termux"
        private const val TERMUX_RUN_COMMAND_SERVICE = "com.termux.app.RunCommandService"
        private const val RUN_COMMAND_PERMISSION = "com.termux.permission.RUN_COMMAND"
        private const val ACTION_RUN_COMMAND = "com.termux.RUN_COMMAND"
        private const val EXTRA_COMMAND_PATH = "com.termux.RUN_COMMAND_PATH"
        private const val EXTRA_ARGUMENTS = "com.termux.RUN_COMMAND_ARGUMENTS"
        private const val EXTRA_WORKDIR = "com.termux.RUN_COMMAND_WORKDIR"
        private const val EXTRA_BACKGROUND = "com.termux.RUN_COMMAND_BACKGROUND"
        private const val EXTRA_COMMAND_LABEL = "com.termux.RUN_COMMAND_COMMAND_LABEL"
        private const val EXTRA_COMMAND_DESCRIPTION = "com.termux.RUN_COMMAND_COMMAND_DESCRIPTION"
    }
}
