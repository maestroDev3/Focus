package de.maestrodev.focus_timer

import android.content.Context
import org.json.JSONObject

/**
 * Blocking state written by Flutter (`blocking.state.v1`), read here without
 * Flutter running. Decisions depend only on timestamps, so blocking ends on
 * time even if Focus was killed.
 */
data class BlockingState(
    val active: Boolean,
    val packages: Set<String>,
    val plannedEndMillis: Long?,
) {
    /** Whether [packageName] must be blocked at [nowMillis]. */
    fun blocks(packageName: String, nowMillis: Long): Boolean =
        active &&
            packageName in packages &&
            (plannedEndMillis == null || nowMillis < plannedEndMillis)

    /**
     * How long to snooze a notification of [packageName], or null to show it.
     * Mirrors  in lib/domain/blocking.dart: at most one minute per
     * round, so held notifications reappear soon after the session ends.
     */
    fun snoozeMillis(packageName: String, nowMillis: Long): Long? {
        if (!active || packageName !in packages) return null
        val end = plannedEndMillis ?: return SNOOZE_STEP_MILLIS
        val left = end - nowMillis
        if (left <= 0) return null
        return minOf(left, SNOOZE_STEP_MILLIS)
    }

    /** Milliseconds until the planned end, or null while paused / inactive. */
    fun remainingMillis(nowMillis: Long): Long? =
        plannedEndMillis?.let { (it - nowMillis).coerceAtLeast(0) }

    companion object {
        private const val SNOOZE_STEP_MILLIS = 60_000L
        private const val PREFERENCES = "FlutterSharedPreferences"
        private const val KEY = "flutter.blocking.state.v1"
        private val INACTIVE = BlockingState(false, emptySet(), null)

        fun read(context: Context): BlockingState {
            val json = context
                .getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
                .getString(KEY, null) ?: return INACTIVE
            return try {
                val obj = JSONObject(json)
                if (obj.optInt("v") != 1) return INACTIVE
                val list = obj.getJSONArray("packages")
                BlockingState(
                    active = obj.getBoolean("active"),
                    packages = (0 until list.length()).map { list.getString(it) }.toSet(),
                    plannedEndMillis =
                        if (obj.isNull("plannedEndMillis")) null else obj.getLong("plannedEndMillis"),
                )
            } catch (error: org.json.JSONException) {
                INACTIVE
            }
        }
    }
}
