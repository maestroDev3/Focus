package de.maestrodev.focus_timer

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APPS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installedApps" -> result.success(installedApps())
                    else -> result.notImplemented()
                }
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
        private const val APPS_CHANNEL = "de.maestrodev.focus_timer/apps"
    }
}
