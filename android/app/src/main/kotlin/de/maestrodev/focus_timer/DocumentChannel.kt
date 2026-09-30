package de.maestrodev.focus_timer

import android.app.Activity
import android.content.Intent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Saves and opens backup files through the Storage Access Framework, so
 * Focus needs no storage permission.
 */
class DocumentChannel(private val activity: Activity, messenger: BinaryMessenger) {
    private var pending: MethodChannel.Result? = null
    private var pendingContent: String? = null

    init {
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            if (pending != null) {
                result.error("busy", "A file dialog is already open.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "saveText" -> {
                    pending = result
                    pendingContent = call.argument<String>("content")
                    activity.startActivityForResult(
                        Intent(Intent.ACTION_CREATE_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType("application/json")
                            .putExtra(Intent.EXTRA_TITLE, call.argument<String>("fileName")),
                        SAVE_REQUEST,
                    )
                }
                "openText" -> {
                    pending = result
                    activity.startActivityForResult(
                        Intent(Intent.ACTION_OPEN_DOCUMENT)
                            .addCategory(Intent.CATEGORY_OPENABLE)
                            .setType("*/*"),
                        OPEN_REQUEST,
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Returns true if the result belonged to a file dialog of this channel. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != SAVE_REQUEST && requestCode != OPEN_REQUEST) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (requestCode == SAVE_REQUEST) false else null)
            return true
        }
        try {
            if (requestCode == SAVE_REQUEST) {
                activity.contentResolver.openOutputStream(uri, "wt")?.use { stream ->
                    stream.write((pendingContent ?: "").toByteArray(Charsets.UTF_8))
                }
                result.success(true)
            } else {
                val text = activity.contentResolver.openInputStream(uri)?.use { stream ->
                    stream.readBytes().toString(Charsets.UTF_8)
                }
                result.success(text)
            }
        } catch (error: Exception) {
            result.error("io", error.message, null)
        } finally {
            pendingContent = null
        }
        return true
    }

    companion object {
        private const val NAME = "de.maestrodev.focus_timer/documents"
        private const val SAVE_REQUEST = 4101
        private const val OPEN_REQUEST = 4102
    }
}
