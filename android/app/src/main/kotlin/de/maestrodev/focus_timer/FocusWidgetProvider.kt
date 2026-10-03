package de.maestrodev.focus_timer

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

/**
 * Home screen widget (story #120). Idle: today's progress and a “Focus”
 * button; running: label and a live countdown. Everything it shows comes
 * from the snapshot Focus publishes and the published blocking state, so it
 * works while Focus is closed.
 */
class FocusWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        HomeWidget.render(context, manager, ids)
    }
}

/**
 * Starts a session from the widget without opening Focus (user decision
 * 2026-10-02). Not exported: only the widget's own PendingIntent reaches it.
 */
class FocusWidgetStartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        HomeWidget.start(context)
    }
}

object HomeWidget {
    private const val PREFERENCES = "home_widget"
    private const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
    private const val BLOCKING_KEY = "flutter.blocking.state.v1"
    private const val DEFAULT_FOCUS_MINUTES = 25
    private const val ROUND_UP_MILLIS = 999L

    /** Stores the snapshot Focus published and redraws all widgets. */
    fun publish(
        context: Context,
        focusMinutes: Int,
        labelId: String?,
        progress: String,
        start: String,
        countdownTitle: String,
        countdownChannel: String,
    ) {
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
            .putInt("focusMinutes", focusMinutes)
            .putString("labelId", labelId)
            .putString("progress", progress)
            .putString("start", start)
            .putString("countdownTitle", countdownTitle)
            .putString("countdownChannel", countdownChannel)
            .apply()
        refresh(context)
    }

    /** The session the widget started since the last call (consumed once). */
    fun takePendingStart(context: Context): Map<String, Any?>? {
        val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val startMillis = prefs.getLong("pendingStartMillis", 0)
        if (startMillis == 0L) return null
        val pending = mapOf(
            "startMillis" to startMillis,
            "plannedMinutes" to prefs.getInt("pendingPlannedMinutes", DEFAULT_FOCUS_MINUTES),
            "labelId" to prefs.getString("pendingLabelId", null),
        )
        prefs.edit()
            .remove("pendingStartMillis")
            .remove("pendingPlannedMinutes")
            .remove("pendingLabelId")
            .apply()
        return pending
    }

    /**
     * One tap on “Focus”: records the start for Focus, makes blocking active
     * right away, schedules the end notification and shows the countdown. If
     * a session already runs, Focus opens instead.
     */
    fun start(context: Context) {
        if (BlockingState.read(context).active) {
            context.startActivity(openIntent(context))
            return
        }
        val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val minutes = prefs.getInt("focusMinutes", DEFAULT_FOCUS_MINUTES)
        val now = System.currentTimeMillis()
        val end = now + minutes * 60_000L
        prefs.edit()
            .putLong("pendingStartMillis", now)
            .putInt("pendingPlannedMinutes", minutes)
            .putString("pendingLabelId", prefs.getString("labelId", null))
            .commit()
        markSessionActive(context, end)
        SessionEndAlarm.schedule(context, end)
        SessionCountdown.show(
            context,
            channelName = prefs.getString("countdownChannel", null) ?: "Session countdown",
            title = prefs.getString("countdownTitle", null) ?: "Focusing",
            paused = false,
            endMillis = end,
            text = null,
        )
        refresh(context)
    }

    /** Redraws all Focus widgets from the current state. */
    fun refresh(context: Context) {
        val manager = AppWidgetManager.getInstance(context) ?: return
        val ids = manager.getAppWidgetIds(ComponentName(context, FocusWidgetProvider::class.java))
        if (ids.isNotEmpty()) render(context, manager, ids)
    }

    fun render(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val prefs = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val countdown = context.getSharedPreferences("session_countdown", Context.MODE_PRIVATE)
        val state = BlockingState.read(context)
        val now = System.currentTimeMillis()
        val end = state.plannedEndMillis
        val running = state.active && end != null && end > now
        val paused = state.active && end == null
        val views = RemoteViews(context.packageName, R.layout.widget_focus)
        val title = countdown.getString("title", null)
            ?: prefs.getString("countdownTitle", null) ?: "Focusing"
        if (running || paused) {
            views.setViewVisibility(R.id.widget_idle, View.GONE)
            views.setViewVisibility(R.id.widget_running, View.VISIBLE)
            views.setTextViewText(R.id.widget_title, title)
            views.setOnClickPendingIntent(R.id.widget_root, openPendingIntent(context))
            if (running && end != null) {
                views.setViewVisibility(R.id.widget_countdown, View.VISIBLE)
                views.setViewVisibility(R.id.widget_paused, View.GONE)
                // +999 ms: the chronometer drops partial seconds, Focus rounds
                // them up – this way widget and app show the same second.
                views.setChronometer(
                    R.id.widget_countdown,
                    SystemClock.elapsedRealtime() + (end - now) + ROUND_UP_MILLIS,
                    null,
                    true,
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    views.setChronometerCountDown(R.id.widget_countdown, true)
                }
            } else {
                views.setViewVisibility(R.id.widget_countdown, View.GONE)
                views.setViewVisibility(R.id.widget_paused, View.VISIBLE)
                views.setTextViewText(R.id.widget_paused, countdown.getString("text", null) ?: "")
            }
        } else {
            views.setViewVisibility(R.id.widget_idle, View.VISIBLE)
            views.setViewVisibility(R.id.widget_running, View.GONE)
            views.setTextViewText(R.id.widget_progress, prefs.getString("progress", null) ?: "")
            views.setTextViewText(R.id.widget_start, prefs.getString("start", null) ?: "Focus")
            views.setOnClickPendingIntent(R.id.widget_root, openPendingIntent(context))
            views.setOnClickPendingIntent(R.id.widget_start, startPendingIntent(context))
        }
        manager.updateAppWidget(ids, views)
    }

    /** Marks the published blocking state active, keeping apps and focus times. */
    private fun markSessionActive(context: Context, endMillis: Long) {
        val flutter = context.getSharedPreferences(FLUTTER_PREFERENCES, Context.MODE_PRIVATE)
        val json = try {
            flutter.getString(BLOCKING_KEY, null)?.let { JSONObject(it) }
        } catch (_: org.json.JSONException) {
            null
        } ?: JSONObject().put("v", 1).put("packages", JSONArray()).put("focusTimes", JSONArray())
        json.put("active", true).put("plannedEndMillis", endMillis)
        flutter.edit().putString(BLOCKING_KEY, json.toString()).commit()
    }

    private fun openIntent(context: Context): Intent =
        Intent(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)

    private fun openPendingIntent(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            7305,
            openIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun startPendingIntent(context: Context): PendingIntent =
        PendingIntent.getBroadcast(
            context,
            7306,
            Intent(context, FocusWidgetStartReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
