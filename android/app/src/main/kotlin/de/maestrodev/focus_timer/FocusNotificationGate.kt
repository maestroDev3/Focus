package de.maestrodev.focus_timer

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Holds back notifications of paused apps while a session is active. They are
 * snoozed for at most a minute per round; when the snooze expires Android
 * posts them again and they are snoozed again while the session lasts. After
 * the session ends (timer or cancel) they simply reappear – nothing is lost.
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
