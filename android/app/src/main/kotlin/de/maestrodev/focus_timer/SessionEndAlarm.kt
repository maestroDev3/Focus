package de.maestrodev.focus_timer

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Posts “Session complete” at the planned end of the running session, also
 * while Focus is closed. Uses an exact alarm when Android allows it (user
 * decision 2026-10-02), otherwise an inexact one. [SessionEndReceiver]
 * reschedules from the published blocking state after a restart or update.
 */
object SessionEndAlarm {
    const val ACTION_SESSION_END = "de.maestrodev.focus_timer.SESSION_END"
    private const val CHANNEL_ID = "session_end"
    private const val NOTIFICATION_ID = 7303
    private const val PREFERENCES = "session_end"

    /** Stores the localized texts Flutter passes in, for the receiver. */
    fun saveTexts(context: Context, channelName: String, title: String, body: String) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString("channelName", channelName)
            .putString("title", title)
            .putString("body", body)
            .apply()
    }

    /** Replaces any pending end notification with one at [endMillis]. */
    fun schedule(context: Context, endMillis: Long) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = alarmIntent(context)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarms.canScheduleExactAlarms()
        try {
            if (exact) {
                alarms.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endMillis, intent)
                return
            }
        } catch (_: SecurityException) {
            // Permission revoked in the meantime – fall back to an inexact alarm.
        }
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endMillis, intent)
    }

    fun cancel(context: Context) {
        context.getSystemService(AlarmManager::class.java)?.cancel(alarmIntent(context))
    }

    /** Schedules again from the published state, e.g. after a restart. */
    fun rescheduleFromState(context: Context) {
        val state = BlockingState.read(context)
        val end = state.plannedEndMillis
        if (state.active && end != null && end > System.currentTimeMillis()) {
            schedule(context, end)
        } else {
            cancel(context)
        }
    }

    /** Posts the notification; tapping it opens Focus, which completes the session. */
    fun show(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (!manager.areNotificationsEnabled()) return
        val texts = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val open = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    texts.getString("channelName", null) ?: "Session end",
                    NotificationManager.IMPORTANCE_HIGH,
                ),
            )
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_HIGH)
        }
        manager.notify(
            NOTIFICATION_ID,
            builder
                .setSmallIcon(R.drawable.ic_stat_focus)
                .setContentTitle(texts.getString("title", null) ?: "Session complete")
                .setContentText(texts.getString("body", null) ?: "Well done – time for a break.")
                .setContentIntent(open)
                .setAutoCancel(true)
                .build(),
        )
    }

    private fun alarmIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            NOTIFICATION_ID,
            Intent(context, SessionEndReceiver::class.java).setAction(ACTION_SESSION_END),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}

/** Shows the due end notification and reschedules after a restart or update. */
class SessionEndReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == SessionEndAlarm.ACTION_SESSION_END) {
            SessionEndAlarm.show(context)
        } else {
            SessionEndAlarm.rescheduleFromState(context)
        }
    }
}
