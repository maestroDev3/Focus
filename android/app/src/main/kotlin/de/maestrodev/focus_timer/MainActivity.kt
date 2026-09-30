package de.maestrodev.focus_timer

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var blockingChannel: MethodChannel? = null
    private var pendingBlockedPackage: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, APPS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installedApps" -> result.success(installedApps())
                else -> result.notImplemented()
            }
        }
        pendingBlockedPackage = intent?.getStringExtra(EXTRA_BLOCKED_PACKAGE)
        blockingChannel = MethodChannel(messenger, BLOCKING_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "isBlockerEnabled" -> result.success(isBlockerEnabled())
                    "openBlockerSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(null)
                    }
                    "isNotificationGateEnabled" -> result.success(isNotificationGateEnabled())
                    "openNotificationGateSettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(EXTRA_BLOCKED_PACKAGE)?.let { app ->
            blockingChannel?.invokeMethod("blockedAppOpened", app)
        }
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
        private const val APPS_CHANNEL = "de.maestrodev.focus_timer/apps"
        private const val BLOCKING_CHANNEL = "de.maestrodev.focus_timer/blocking"
    }
}
