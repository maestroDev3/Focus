package de.maestrodev.focus_timer

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Mindful opening (#119): outside sessions and focus times a paused app first
 * shows Focus' breathing pause. After “Open” the app stays free for five
 * minutes. Also counts per app how often it was opened today.
 */
object MindfulOpening {
    private const val PREFERENCES = "mindful_opening"
    private const val RELEASE_MILLIS = 5 * 60_000L
    private const val DAY_KEY = "day"

    /**
     * Whether opening [app] at [nowMillis] shows the pause first. Mirrors
     * `needsMindfulPause` in lib/domain/blocking.dart.
     */
    fun needsPause(context: Context, state: BlockingState, app: String, nowMillis: Long): Boolean =
        state.mindful &&
            app in state.packages &&
            nowMillis >= releasedUntil(context, app) &&
            !state.focusing(nowMillis)

    /** “Open” after the pause: [app] opens without pause for five minutes. */
    fun release(context: Context, app: String, nowMillis: Long) {
        preferences(context).edit().putLong("release.$app", nowMillis + RELEASE_MILLIS).apply()
    }

    /** Counts one more opening of [app] today and returns today's count. */
    fun countOpening(context: Context, app: String, nowMillis: Long): Int {
        val preferences = preferences(context)
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(Date(nowMillis))
        val editor = preferences.edit()
        val newDay = preferences.getString(DAY_KEY, null) != today
        if (newDay) {
            // A new day: forget yesterday's counts, keep the releases.
            preferences.all.keys.filter { it.startsWith("count.") }.forEach { editor.remove(it) }
            editor.putString(DAY_KEY, today)
        }
        val count = (if (newDay) 0 else preferences.getInt("count.$app", 0)) + 1
        editor.putInt("count.$app", count).apply()
        return count
    }

    private fun releasedUntil(context: Context, app: String): Long =
        preferences(context).getLong("release.$app", 0)

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
}
