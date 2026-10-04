package de.maestrodev.focus_timer

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

/**
 * Notices when a paused app comes to the foreground during a focus session or
 * a focus time and brings the user back to Focus – or, with mindful opening
 * on, outside them shows Focus' breathing pause first. Only window state changes
 * are observed; screen content is never read.
 */
class FocusBlockerService : AccessibilityService() {
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val app = event.packageName?.toString() ?: return
        if (app == packageName) return
        val now = System.currentTimeMillis()
        val state = BlockingState.read(this)
        if (state.blocks(app, now)) {
            bringFocusToFront { putExtra(MainActivity.EXTRA_BLOCKED_PACKAGE, app) }
            return
        }
        if (!MindfulOpening.needsPause(this, state, app, now)) return
        // One app often reports several window changes at once: count once.
        if (app == lastMindfulApp && now - lastMindfulMillis < MINDFUL_DEBOUNCE_MILLIS) return
        lastMindfulApp = app
        lastMindfulMillis = now
        val count = MindfulOpening.countOpening(this, app, now)
        bringFocusToFront {
            putExtra(MainActivity.EXTRA_MINDFUL_PACKAGE, app)
            putExtra(MainActivity.EXTRA_MINDFUL_COUNT, count)
        }
    }

    private var lastMindfulApp: String? = null
    private var lastMindfulMillis = 0L

    private fun bringFocusToFront(extras: Intent.() -> Unit) {
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP,
                )
                extras()
            },
        )
    }

    override fun onInterrupt() = Unit

    private companion object {
        const val MINDFUL_DEBOUNCE_MILLIS = 2_000L
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        TamperWarning.dismiss(this, TamperWarning.Kind.BLOCKER)
    }

    /** Switched off in the settings (or unbound): warn if focus is running. */
    override fun onUnbind(intent: Intent?): Boolean {
        TamperWarning.showIfSwitchedOff(this, TamperWarning.Kind.BLOCKER)
        return super.onUnbind(intent)
    }
}
