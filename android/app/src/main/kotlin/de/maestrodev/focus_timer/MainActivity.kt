package de.maestrodev.focus_timer

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.content.pm.ResolveInfo
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import java.io.ByteArrayOutputStream
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var blockingChannel: MethodChannel? = null
    private var documents: DocumentChannel? = null
    private var pendingBlockedPackage: String? = null
    private var remindersChannel: MethodChannel? = null
    private var pendingStartRequest = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        documents = DocumentChannel(this, messenger)
        MethodChannel(messenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installedApps" -> result.success(installedApps())
                "appIcon" -> result.success(appIcon(call.arguments as? String))
                else -> result.notImplemented()
            }
        }
        pendingStartRequest =
            intent?.getBooleanExtra(FocusTimeReminder.EXTRA_START_SESSION, false) == true
        MethodChannel(messenger, SESSION_END_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    SessionEndAlarm.saveTexts(
                        this,
                        channelName = call.argument<String>("channelName") ?: "",
                        title = call.argument<String>("title") ?: "",
                        body = call.argument<String>("body") ?: "",
                    )
                    val end = call.argument<Number>("endMillis")?.toLong()
                    if (end != null) SessionEndAlarm.schedule(this, end)
                    requestNotificationPermission()
                    result.success(null)
                }
                "cancel" -> {
                    SessionEndAlarm.cancel(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        remindersChannel = MethodChannel(messenger, REMINDERS_CHANNEL)
        remindersChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "reschedule" -> {
                    FocusTimeReminder.saveTexts(
                        this,
                        channelName = call.argument<String>("channelName") ?: "",
                        title = call.argument<String>("title") ?: "",
                        body = call.argument<String>("body") ?: "",
                    )
                    FocusTimeReminder.reschedule(this)
                    result.success(null)
                }
                "requestPermission" -> {
                    requestNotificationPermission()
                    result.success(null)
                }
                "initialStartRequest" -> {
                    result.success(pendingStartRequest)
                    pendingStartRequest = false
                }
                else -> result.notImplemented()
            }
        }
        pendingBlockedPackage = intent?.getStringExtra(EXTRA_BLOCKED_PACKAGE)
        blockingChannel = MethodChannel(messenger, BLOCKING_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBlockerEnabled" -> result.success(isBlockerEnabled())
                    "openBlockerSettings" -> {
                        openBlockerSettings()
                        result.success(null)
                    }
                    "isNotificationGateEnabled" -> result.success(isNotificationGateEnabled())
                    "openNotificationGateSettings" -> {
                        openNotificationGateSettings()
                        result.success(null)
                    }
                    "openAppInfo" -> {
                        openSettingsPage(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            ),
                        )
                        result.success(null)
                    }
                    "initialBlockedPackage" -> {
                        result.success(pendingBlockedPackage)
                        pendingBlockedPackage = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    @Suppress("OVERRIDE_DEPRECATION", "DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (documents?.onActivityResult(requestCode, resultCode, data) != true) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(EXTRA_BLOCKED_PACKAGE)?.let { app ->
            blockingChannel?.invokeMethod("blockedAppOpened", app)
        }
        if (intent.getBooleanExtra(FocusTimeReminder.EXTRA_START_SESSION, false)) {
            remindersChannel?.invokeMethod("startRequested", null)
        }
    }

    /** Asks once for POST_NOTIFICATIONS (Android 13+) so reminders and the session end can show. */
    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), NOTIFICATION_REQUEST)
    }

    /**
     * Opens the accessibility settings with Focus highlighted. CLEAR_TASK
     * resets a settings screen left open in the background – otherwise some
     * launchers (Samsung One UI) only bring that old screen to the front.
     */
    private fun openBlockerSettings() {
        val blocker = ComponentName(this, FocusBlockerService::class.java).flattenToString()
        openSettingsPage(highlighting(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS), blocker))
    }

    /** Opens Focus' own notification access switch (Android 11+), else the list. */
    private fun openNotificationGateSettings() {
        val gate = ComponentName(this, FocusNotificationGate::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val detail = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
                .putExtra(
                    Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME,
                    gate.flattenToString(),
                )
            if (openSettingsPage(detail)) return
        }
        openSettingsPage(
            highlighting(
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS),
                gate.flattenToString(),
            ),
        )
    }

    /** Adds the extras that scroll to and highlight [key] in a settings list. */
    private fun highlighting(intent: Intent, key: String): Intent =
        intent
            .putExtra(EXTRA_FRAGMENT_ARG_KEY, key)
            .putExtra(EXTRA_SHOW_FRAGMENT_ARGUMENTS, Bundle().apply {
                putString(EXTRA_FRAGMENT_ARG_KEY, key)
            })

    /** Starts [intent] as a fresh settings task; false if no screen handles it. */
    private fun openSettingsPage(intent: Intent): Boolean =
        try {
            startActivity(
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK),
            )
            true
        } catch (_: ActivityNotFoundException) {
            false
        }

    private fun isBlockerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        val blocker = ComponentName(this, FocusBlockerService::class.java).flattenToString()
        return enabled.split(':').any { it.equals(blocker, ignoreCase = true) }
    }

    private fun isNotificationGateEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val gate = ComponentName(this, FocusNotificationGate::class.java).flattenToString()
        return enabled.split(':').any { it.equals(gate, ignoreCase = true) }
    }

    /** The launcher icon of [app] as a 96×96 PNG, or null if it is unknown. */
    private fun appIcon(app: String?): ByteArray? {
        if (app == null) return null
        return try {
            val icon = packageManager.getApplicationIcon(app)
            val bitmap = Bitmap.createBitmap(ICON_SIZE, ICON_SIZE, Bitmap.Config.ARGB_8888)
            icon.setBounds(0, 0, ICON_SIZE, ICON_SIZE)
            icon.draw(Canvas(bitmap))
            ByteArrayOutputStream().use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
                out.toByteArray()
            }
        } catch (error: PackageManager.NameNotFoundException) {
            null
        }
    }

    /** Apps with a launcher entry (visible via the <queries> entry in the manifest). */
    private fun installedApps(): List<Map<String, String>> {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities: List<ResolveInfo> =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.queryIntentActivities(
                    launcher,
                    PackageManager.ResolveInfoFlags.of(0),
                )
            } else {
                @Suppress("DEPRECATION")
                packageManager.queryIntentActivities(launcher, 0)
            }
        return activities
            .map { it.activityInfo.packageName to it.loadLabel(packageManager).toString() }
            .filter { (app, _) -> app != packageName }
            .distinctBy { (app, _) -> app }
            .sortedBy { (_, label) -> label.lowercase() }
            .map { (app, label) -> mapOf("packageName" to app, "label" to label) }
    }

    companion object {
        const val EXTRA_BLOCKED_PACKAGE = "blockedPackage"
        private const val ICON_SIZE = 96
        private const val APPS_CHANNEL = "de.maestrodev.focus_timer/apps"
        private const val BLOCKING_CHANNEL = "de.maestrodev.focus_timer/blocking"
        private const val REMINDERS_CHANNEL = "de.maestrodev.focus_timer/reminders"
        private const val SESSION_END_CHANNEL = "de.maestrodev.focus_timer/session_end"
        private const val NOTIFICATION_REQUEST = 7302

        // Undocumented but widely supported (AOSP, Samsung): highlight an entry
        // in a settings list.
        private const val EXTRA_FRAGMENT_ARG_KEY = ":settings:fragment_args_key"
        private const val EXTRA_SHOW_FRAGMENT_ARGUMENTS = ":settings:show_fragment_args"
    }
}
