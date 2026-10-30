package de.maestrodev.focus_timer

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Holds back notifications of paused apps during a session or a focus time.
 * They are snoozed for at most a minute per round; when the snooze expires
 * Android posts them again and they are snoozed again while the block lasts.
 * Once it ends (timer, cancel or end of the focus time) they simply reappear –
 * nothing is lost.
 */
class FocusNotificationGate : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        connected = this
        TamperWarning.dismiss(this, TamperWarning.Kind.GATE)
        activeNotifications?.forEach(::holdIfPaused)
    }

    /** Access revoked (or unbound): warn if focus is running. */
    override fun onListenerDisconnected() {
        if (connected === this) connected = null
        TamperWarning.showIfSwitchedOff(this, TamperWarning.Kind.GATE)
        super.onListenerDisconnected()
    }

    override fun onNotificationPosted(notification: StatusBarNotification?) {
        notification?.let(::holdIfPaused)
    }

    /** Frees every snoozed notification that no block holds any more. */
    private fun refreshHeldNow() {
        val state = BlockingState.read(this)
        val now = System.currentTimeMillis()
        getSnoozedNotifications()?.forEach { notification ->
            if (state.snoozeMillis(notification.packageName, now) == null) {
                // A ~0 snooze hands it back to the shade right away.
                snoozeNotification(notification.key, 1)
            }
        }
    }

    private fun holdIfPaused(notification: StatusBarNotification) {
        // Ongoing notifications (music, calls, downloads) are left alone.
        if (notification.packageName == packageName || notification.isOngoing) return
        val millis = BlockingState.read(this)
            .snoozeMillis(notification.packageName, System.currentTimeMillis())
            ?: return
        snoozeNotification(notification.key, millis)
    }

    companion object {
        /** The connected service, so the app can ask for a re-check. */
        @Volatile private var connected: FocusNotificationGate? = null

        /**
         * Re-checks held notifications against the current blocking state
         * (#373); called after every state write. Without notification
         * access there is nothing to free.
         */
        fun refreshHeld() {
            connected?.refreshHeldNow()
        }
    }
}
