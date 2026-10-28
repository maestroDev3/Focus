package de.maestrodev.focus_timer

import android.annotation.TargetApi
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
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

    /** Written by the Focus settings (“Show on lock screen”, default on). */
    private const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
    private const val LOCK_SCREEN_KEY = "flutter.settings.lockScreen.v1"

    /** Written by the Focus settings (“Status bar countdown”, default off). */
    private const val LIVE_UPDATE_KEY = "flutter.settings.liveUpdate.v1"

    /** `Notification.EXTRA_REQUEST_PROMOTED_ONGOING` (Android 16). */
    private const val EXTRA_REQUEST_PROMOTED_ONGOING = "android.requestPromotedOngoing"
    private const val BAKLAVA = 36

    /** Champagne gold, the theme's primary (`lib/ui/theme.dart`). */
    private val CHAMPAGNE = 0xFFC9A96E.toInt()

    private fun showsOnLockScreen(context: Context): Boolean =
        context.getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(LOCK_SCREEN_KEY, true)

    private fun wantsLiveUpdate(context: Context): Boolean =
        context.getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(LIVE_UPDATE_KEY, false)

    /**
     * Whether Android 16+ lets Focus post Live Updates (status bar chip, lock
     * screen, Samsung's Now Bar). Looked up reflectively, so it builds with
     * older SDKs too.
     */
    private fun canPromote(manager: NotificationManager): Boolean =
        Build.VERSION.SDK_INT >= BAKLAVA && runCatching {
            NotificationManager::class.java.getMethod("canPostPromotedNotifications")
                .invoke(manager) as Boolean
        }.getOrDefault(false)

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
    private fun countdownViews(
        context: Context,
        layout: Int,
        title: String,
        leftMillis: Long,
        untilText: String? = null,
    ): RemoteViews =
        RemoteViews(context.packageName, layout).apply {
            setTextViewText(R.id.countdown_title, title)
            if (untilText != null) setTextViewText(R.id.countdown_until, untilText)
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
            // Focus's champagne, so the entry reads as Focus, not system grey.
            .setColor(CHAMPAGNE)
        // Label and time are no secret: shown in full on the lock screen
        // unless the user switched it off – then not at all (story #220).
        val onLockScreen = showsOnLockScreen(context)
        builder.setVisibility(
            if (onLockScreen) Notification.VISIBILITY_PUBLIC else Notification.VISIBILITY_SECRET,
        )
        // The large time wins by default; the "Status bar countdown" setting
        // opts into the Live Update, whose standard template keeps the time
        // small in the header (user decision 2026-10-27).
        val promoted = onLockScreen && wantsLiveUpdate(context) && canPromote(manager)
        if (promoted) {
            builder.addExtras(Bundle().apply { putBoolean(EXTRA_REQUEST_PROMOTED_ONGOING, true) })
        }
        if (!paused && endMillis != null) {
            val left = endMillis - System.currentTimeMillis()
            if (promoted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder
                    .setWhen(endMillis + ROUND_UP_MILLIS)
                    .setShowWhen(true)
                    .setUsesChronometer(true)
                    .setChronometerCountDown(true)
                    .setContentText(text)
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                // The remaining time is the main thing (user test 2026-10-03):
                // own views with a large live chronometer instead of the small
                // one in the header.
                builder
                    .setShowWhen(false)
                    .setStyle(Notification.DecoratedCustomViewStyle())
                    .setCustomContentView(
                        countdownViews(context, R.layout.notification_countdown, title, left, text),
                    )
                    .setCustomBigContentView(
                        countdownViews(context, R.layout.notification_countdown_big, title, left, text),
                    )
            } else {
                builder
                    .setWhen(endMillis)
                    .setShowWhen(true)
                    .setUsesChronometer(true)
                    .setContentText(text)
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
