package de.maestrodev.focus_timer

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

/**
 * Notices when a paused app comes to the foreground during a focus session or
 * a focus time and brings the user back to Focus. Only window state changes
 * are observed; screen content is never read.
 */
class FocusBlockerService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val app = event.packageName?.toString() ?: return
        if (app == packageName) return
        if (!BlockingState.read(this).blocks(app, System.currentTimeMillis())) return

        startActivity(
            Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP,
                )
                putExtra(MainActivity.EXTRA_BLOCKED_PACKAGE, app)
            },
        )
    }

    override fun onInterrupt() = Unit
}
