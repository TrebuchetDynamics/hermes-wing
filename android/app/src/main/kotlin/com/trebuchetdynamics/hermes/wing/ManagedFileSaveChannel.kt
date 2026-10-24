package com.trebuchetdynamics.hermes.wing

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Future
import java.util.concurrent.SynchronousQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.RejectedExecutionException

/** A single explicit document creation. URIs never cross into Dart or diagnostics. */
class ManagedFileSaveChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    private class Save(val id: Int, var picker: MethodChannel.Result?) {
        val job = ManagedFileSaveJob()
        val cancelled get() = job.cancelled
        var uri: Uri? = null
        @Volatile var verified = false
        val signal = CancellationSignal()
        @Volatile var descriptor: ParcelFileDescriptor? = null
        var task: Future<*>? = null
        var writeResult: MethodChannel.Result? = null
    }
    private var active: Save? = null
    // A stuck provider cannot queue every retry behind the old attempt. The
    // bounded pool rejects excess work rather than accumulating blocked jobs.
    private val io = ThreadPoolExecutor(0, 2, 30, TimeUnit.SECONDS, SynchronousQueue<Runnable>())
    private val cancellation = ThreadPoolExecutor(0, 2, 30, TimeUnit.SECONDS,
        SynchronousQueue<Runnable>(), ThreadPoolExecutor.DiscardPolicy())
    // A broken delete provider must neither queue unbounded work nor block
    // descriptor/signal cancellation. Partial-document removal is best effort.
    private val deletion = ThreadPoolExecutor(0, 1, 30, TimeUnit.SECONDS,
        SynchronousQueue<Runnable>(), ThreadPoolExecutor.DiscardPolicy())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<Int>("id")
        when (call.method) {
            "choose" -> {
                val name = call.argument<String>("name")
                if (active != null || id == null || name == null ||
                    name.length !in 1..120 || !Regex("[A-Za-z0-9._-]+").matches(name) ||
                    name.startsWith(".") || name.startsWith("-")) {
                    result.error("unavailable", "Document save unavailable", null)
                    return
                }
                active = Save(id, result)
                try {
                    // CREATE_DOCUMENT creates a new document rather than silently
                    // replacing an existing one; the system owns destination consent.
                    activity.startActivityForResult(Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/octet-stream"
                        putExtra(Intent.EXTRA_TITLE, name)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    }, REQUEST)
                } catch (_: Exception) {
                    active = null
                    result.error("unavailable", "Document picker unavailable", null)
                }
            }
            "writeAndReadBack" -> {
                val save = active
                val bytes = call.argument<ByteArray>("bytes")
                if (save == null || save.id != id || save.uri == null ||
                    save.cancelled || save.verified || save.writeResult != null ||
                    bytes == null || bytes.size > ManagedFileSaveJob.MAX_BYTES) {
                    result.error("unavailable", "Document save unavailable", null)
                    return
                }
                save.writeResult = result
                try {
                    save.task = io.submit {
                        try {
                            val uri = save.uri!!
                            val actual = save.job.writeAndReadBack(bytes, {
                                val fd = activity.contentResolver.openFileDescriptor(uri, "w", save.signal)
                                    ?: error("Document output unavailable")
                                save.descriptor = fd
                                ParcelFileDescriptor.AutoCloseOutputStream(fd)
                            }, {
                                val fd = activity.contentResolver.openFileDescriptor(uri, "r", save.signal)
                                    ?: error("Document input unavailable")
                                save.descriptor = fd
                                ParcelFileDescriptor.AutoCloseInputStream(fd)
                            })
                            save.verified = true
                            activity.runOnUiThread {
                                save.writeResult?.success(if (save.cancelled) null else actual)
                                save.writeResult = null
                            }
                        } catch (_: Exception) {
                            activity.runOnUiThread {
                                save.writeResult?.error("failed", "Document save could not be verified", null)
                                save.writeResult = null
                            }
                        } finally {
                            try { save.descriptor?.close() } catch (_: Exception) { }
                            save.descriptor = null
                        }
                    }
                } catch (_: RejectedExecutionException) {
                    save.writeResult?.error("busy", "Document provider is still releasing previous saves", null)
                    save.writeResult = null
                }
            }
            "cancel", "release" -> {
                val save = active
                if (save != null && save.id == id) {
                    cancel(save)
                    // Keep a cancelled chooser reserved until its result arrives;
                    // an older picker must never select a newer attempt's target.
                    if (save.picker == null) {
                        active = null
                        if (!save.verified) discard(save)
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(request: Int, code: Int, data: Intent?): Boolean {
        if (request != REQUEST) return false
        val save = active ?: return true
        val picker = save.picker
        save.picker = null
        val uri = data?.data
        if (code == Activity.RESULT_OK && uri?.scheme == "content") save.uri = uri
        if (save.cancelled || save.uri == null) {
            active = null
            discard(save)
            picker?.success(false)
        } else {
            picker?.success(true)
        }
        return true
    }

    private fun discard(save: Save) {
        val uri = save.uri ?: return
        deletion.execute {
            try { DocumentsContract.deleteDocument(activity.contentResolver, uri) } catch (_: Exception) {
                // Provider may retain a partial document; never report a verified save.
            }
        }
    }

    private fun cancel(save: Save) {
        save.job.requestCancel()
        save.writeResult?.success(null)
        save.writeResult = null
        save.task?.cancel(true)
        cancellation.execute {
            try { save.job.close() } catch (_: Exception) { }
            try { save.descriptor?.close() } catch (_: Exception) { }
            try { save.signal.cancel() } catch (_: Exception) { }
        }
    }

    fun dispose() {
        active?.let { save ->
            cancel(save)
            save.picker?.success(false)
            if (!save.verified) discard(save)
        }
        active = null
        io.shutdownNow()
        cancellation.shutdown()
        deletion.shutdown()
    }

    companion object {
        private const val REQUEST = 8421
    }
}
