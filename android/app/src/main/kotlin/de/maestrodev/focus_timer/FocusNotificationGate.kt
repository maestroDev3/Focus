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
        activeNotifications?.forEach(::holdIfPaused)
    }

    override fun onNotificationPosted(notification: StatusBarNotification?) {
        notification?.let(::holdIfPaused)
    }

    private fun holdIfPaused(notification: StatusBarNotification) {
        // Ongoing notifications (music, calls, downloads) are left alone.
        if (notification.packageName == packageName || notification.isOngoing) return
        val millis = BlockingState.read(this)
            .snoozeMillis(notification.packageName, System.currentTimeMillis())
            ?: return
        snoozeNotification(notification.key, millis)
    }
}
