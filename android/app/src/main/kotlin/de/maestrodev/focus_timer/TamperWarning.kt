package de.maestrodev.focus_timer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings

/**
 * Warns at once when app blocking or notification holding is switched off
 * while a session or focus time runs (story #190). Android doesn't let an app
 * prevent that, but it shouldn't go unnoticed. Texts come from Android
 * string resources so they work without Flutter.
 */
object TamperWarning {
    private const val CHANNEL_ID = "focus_warnings"

    enum class Kind(
        val notificationId: Int,
        val title: Int,
        val text: Int,
        val settingsAction: String,
    ) {
        BLOCKER(
            7307,
            R.string.blocker_off_title,
            R.string.blocker_off_text,
            Settings.ACTION_ACCESSIBILITY_SETTINGS,
        ),
        GATE(
            7308,
            R.string.gate_off_title,
            R.string.gate_off_text,
            Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS,
        ),
    }

    /**
     * Posts the warning if focus is running and the service is really no
     * longer enabled – an app update or process kill unbinds it too, but
     * leaves it enabled.
     */
    fun showIfSwitchedOff(context: Context, kind: Kind) {
        if (!BlockingState.read(context).focusing(System.currentTimeMillis())) return
        if (isEnabled(context, kind)) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (!manager.areNotificationsEnabled()) return
        val open = PendingIntent.getActivity(
            context,
            kind.notificationId,
            Intent(kind.settingsAction).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.warning_channel),
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
        }
        manager.notify(
            kind.notificationId,
            builder
                .setSmallIcon(R.drawable.ic_stat_focus)
                .setContentTitle(context.getString(kind.title))
                .setContentText(context.getString(kind.text))
                .setStyle(Notification.BigTextStyle().bigText(context.getString(kind.text)))
                .setContentIntent(open)
                .setAutoCancel(true)
                .build(),
        )
    }

    /** Removes the warning once the service runs again. */
    fun dismiss(context: Context, kind: Kind) {
        context.getSystemService(NotificationManager::class.java)?.cancel(kind.notificationId)
    }

    private fun isEnabled(context: Context, kind: Kind): Boolean {
        val (setting, component) = when (kind) {
            Kind.BLOCKER -> Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES to
                ComponentName(context, FocusBlockerService::class.java)
            Kind.GATE -> "enabled_notification_listeners" to
                ComponentName(context, FocusNotificationGate::class.java)
        }
        val enabled = Settings.Secure.getString(context.contentResolver, setting) ?: return false
        return enabled.split(':').any { it.equals(component.flattenToString(), ignoreCase = true) }
    }
}
