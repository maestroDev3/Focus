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
import java.util.Calendar
import java.util.Locale

/**
 * Schedules a calm notification at the start of the next focus time. Uses an
 * inexact alarm (no exact-alarm permission); each reminder schedules the next
 * one, and [FocusTimeReminderReceiver] reschedules after a restart or update.
 * Focus times are read from the blocking state Flutter publishes.
 */
object FocusTimeReminder {
    const val ACTION_REMIND = "de.maestrodev.focus_timer.REMIND_FOCUS_TIME"
    const val EXTRA_START_SESSION = "startSession"
    private const val EXTRA_END_MINUTE = "endMinute"
    private const val CHANNEL_ID = "focus_times"
    private const val NOTIFICATION_ID = 7301
    private const val PREFERENCES = "focus_time_reminders"

    /** Stores the localized texts Flutter passes in, for reminders without Flutter. */
    fun saveTexts(context: Context, channelName: String, title: String, body: String) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString("channelName", channelName)
            .putString("title", title)
            .putString("body", body)
            .apply()
    }

    /** Replaces the pending reminder with one for the next focus time start. */
    fun reschedule(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val now = System.currentTimeMillis()
        val next = nextStart(BlockingState.read(context).focusTimes, now)
        if (next == null) {
            alarms.cancel(alarmIntent(context, 0))
            return
        }
        val (at, endMinute) = next
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, alarmIntent(context, endMinute))
    }

    /**
     * The next start after [nowMillis] and the end minute of that focus time.
     * Mirrors `nextFocusTimeStart` in lib/domain/focus_time.dart.
     */
    fun nextStart(times: List<FocusTimeRule>, nowMillis: Long): Pair<Long, Int>? {
        var best: Pair<Long, Int>? = null
        for (offset in 0..7) {
            val day = Calendar.getInstance().apply {
                timeInMillis = nowMillis
                add(Calendar.DAY_OF_YEAR, offset)
            }
            val weekday = (day.get(Calendar.DAY_OF_WEEK) + 5) % 7 + 1
            for (time in times) {
                if (weekday !in time.weekdays) continue
                val start = (day.clone() as Calendar).apply {
                    set(Calendar.HOUR_OF_DAY, time.startMinute / 60)
                    set(Calendar.MINUTE, time.startMinute % 60)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }.timeInMillis
                if (start > nowMillis && (best == null || start < best.first)) {
                    best = start to time.endMinute
                }
            }
        }
        return best
    }

    /** Posts the reminder; it disappears by itself when the focus time ends. */
    fun show(context: Context, endMinute: Int) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (!manager.areNotificationsEnabled()) return
        val texts = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val time = String.format(Locale.getDefault(), "%02d:%02d", endMinute / 60, endMinute % 60)
        val title = (texts.getString("title", null) ?: "Focus time until {time}")
            .replace("{time}", time)
        val body = texts.getString("body", null) ?: "Start a session?"
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                .putExtra(EXTRA_START_SESSION, true),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    texts.getString("channelName", null) ?: "Focus time reminders",
                    NotificationManager.IMPORTANCE_DEFAULT,
                ),
            )
            Notification.Builder(context, CHANNEL_ID).apply {
                millisUntil(endMinute)?.let { setTimeoutAfter(it) }
            }
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        manager.notify(
            NOTIFICATION_ID,
            builder
                .setSmallIcon(R.drawable.ic_stat_focus)
                .setContentTitle(title)
                .setContentText(body)
                .setContentIntent(open)
                .setAutoCancel(true)
                .build(),
        )
    }

    /** Dismisses a shown reminder, e.g. once a session started from it. */
    fun dismiss(context: Context) {
        context.getSystemService(NotificationManager::class.java)?.cancel(NOTIFICATION_ID)
    }

    private fun millisUntil(endMinute: Int): Long? {
        val now = System.currentTimeMillis()
        val end = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, endMinute / 60)
            set(Calendar.MINUTE, endMinute % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        return (end - now).takeIf { it > 0 }
    }

    private fun alarmIntent(context: Context, endMinute: Int): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            0,
            Intent(context, FocusTimeReminderReceiver::class.java)
                .setAction(ACTION_REMIND)
                .putExtra(EXTRA_END_MINUTE, endMinute),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    internal fun endMinuteOf(intent: Intent): Int = intent.getIntExtra(EXTRA_END_MINUTE, 0)
}

/** Shows due reminders and reschedules after a restart or app update. */
class FocusTimeReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == FocusTimeReminder.ACTION_REMIND) {
            FocusTimeReminder.show(context, FocusTimeReminder.endMinuteOf(intent))
        }
        FocusTimeReminder.reschedule(context)
    }
}
