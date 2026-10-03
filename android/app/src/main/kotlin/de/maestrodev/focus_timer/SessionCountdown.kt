package de.maestrodev.focus_timer

import android.annotation.TargetApi
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews

/**
 * Ongoing, silent notification with the remaining focus time. While the
 * session runs, Android counts down by itself (chronometer) and removes the
 * notification at the end – Focus doesn't have to run. No buttons (user
 * decision 2026-10-02). The last notice is stored so it can come back after
 * a restart.
 */
object SessionCountdown {
    private const val CHANNEL_ID = "session_countdown"
    private const val NOTIFICATION_ID = 7304
    private const val PREFERENCES = "session_countdown"
    private const val ROUND_UP_MILLIS = 999L

    /** Stores and shows a notice; [endMillis] is null while paused. */
    fun show(
        context: Context,
        channelName: String,
        title: String,
        paused: Boolean,
        endMillis: Long?,
        text: String?,
    ) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
            .putBoolean("stored", true)
            .putString("channelName", channelName)
            .putString("title", title)
            .putBoolean("paused", paused)
            .putLong("endMillis", endMillis ?: 0)
            .putString("text", text)
            .apply()
        post(context, channelName, title, paused, endMillis, text)
    }

    /** Removes the notification and forgets the notice. */
    fun hide(context: Context) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().clear().apply()
        dismiss(context)
    }

    /** Removes only the notification, e.g. when “Session complete” takes over. */
    fun dismiss(context: Context) {
        context.getSystemService(NotificationManager::class.java)?.cancel(NOTIFICATION_ID)
    }

    /** Shows the stored notice again after a restart if the session still runs. */
    fun repostFromState(context: Context) {
        val stored = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        if (!stored.getBoolean("stored", false)) return
        val state = BlockingState.read(context)
        val paused = stored.getBoolean("paused", false)
        val end = state.plannedEndMillis
        val running = state.active && end != null && end > System.currentTimeMillis()
        val stillPaused = state.active && end == null && paused
        if (!running && !stillPaused) {
            hide(context)
            return
        }
        post(
            context,
            stored.getString("channelName", null) ?: "Session countdown",
            stored.getString("title", null) ?: "Focusing",
            paused = !running,
            endMillis = if (running) end else null,
            text = stored.getString("text", null),
        )
    }

    /**
     * Title plus a live countdown. Android's chronometer drops partial
     * seconds while the app rounds them up, so the base gets +999 ms to show
     * the same second as Focus.
     */
    @TargetApi(Build.VERSION_CODES.N)
    private fun countdownViews(context: Context, layout: Int, title: String, leftMillis: Long): RemoteViews =
        RemoteViews(context.packageName, layout).apply {
            setTextViewText(R.id.countdown_title, title)
            setChronometer(
                R.id.countdown_time,
                SystemClock.elapsedRealtime() + leftMillis + ROUND_UP_MILLIS,
                null,
                true,
            )
            setChronometerCountDown(R.id.countdown_time, true)
        }

    private fun post(
        context: Context,
        channelName: String,
        title: String,
        paused: Boolean,
        endMillis: Long?,
        text: String?,
    ) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (!manager.areNotificationsEnabled()) return
        val open = PendingIntent.getActivity(
            context,
            NOTIFICATION_ID,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, channelName, NotificationManager.IMPORTANCE_LOW)
                    .apply { setShowBadge(false) },
            )
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(Notification.PRIORITY_LOW)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_focus)
            .setContentTitle(title)
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
        if (!paused && endMillis != null) {
            val left = endMillis - System.currentTimeMillis()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // The remaining time is the main thing (user test 2026-10-03):
                // own views with a large live chronometer instead of the small
                // one in the header.
                builder
                    .setShowWhen(false)
                    .setStyle(Notification.DecoratedCustomViewStyle())
                    .setCustomContentView(countdownViews(context, R.layout.notification_countdown, title, left))
                    .setCustomBigContentView(
                        countdownViews(context, R.layout.notification_countdown_big, title, left),
                    )
            } else {
                builder.setWhen(endMillis).setShowWhen(true).setUsesChronometer(true)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && left > 0) {
                builder.setTimeoutAfter(left)
            }
        } else {
            builder.setShowWhen(false).setContentText(text)
        }
        manager.notify(NOTIFICATION_ID, builder.build())
    }
}
