package de.maestrodev.focus_timer

import android.content.Context
import org.json.JSONObject
import java.util.Calendar

/**
 * A recurring focus time as written by Flutter: ISO weekdays (1 = Monday) and
 * start/end as minutes of the day. Mirrors `FocusTime` in
 * lib/domain/focus_time.dart.
 */
data class FocusTimeRule(
    val weekdays: Set<Int>,
    val startMinute: Int,
    val endMinute: Int,
    /** Apps of the focus time's own list (#144); null = the default list. */
    val packages: Set<String>? = null,
) {
    /** Whether this focus time runs at [nowMillis] in the phone's time zone. */
    fun isActiveAt(nowMillis: Long): Boolean {
        val (weekday, minute) = localWeekdayAndMinute(nowMillis)
        return weekday in weekdays && minute >= startMinute && minute < endMinute
    }

    /** Milliseconds until this focus time ends today, measured from [nowMillis]. */
    fun millisUntilEnd(nowMillis: Long): Long {
        val end = Calendar.getInstance().apply {
            timeInMillis = nowMillis
            set(Calendar.HOUR_OF_DAY, endMinute / 60)
            set(Calendar.MINUTE, endMinute % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        return end.timeInMillis - nowMillis
    }

    private fun localWeekdayAndMinute(nowMillis: Long): Pair<Int, Int> {
        val calendar = Calendar.getInstance().apply { timeInMillis = nowMillis }
        // Calendar: Sunday = 1 … Saturday = 7; ISO: Monday = 1 … Sunday = 7.
        val weekday = (calendar.get(Calendar.DAY_OF_WEEK) + 5) % 7 + 1
        val minute = calendar.get(Calendar.HOUR_OF_DAY) * 60 + calendar.get(Calendar.MINUTE)
        return weekday to minute
    }
}

/**
 * Blocking state written by Flutter (`blocking.state.v1`), read here without
 * Flutter running. Decisions depend only on timestamps and the weekly focus
 * times, so blocking starts and ends on time even if Focus was killed.
 */
data class BlockingState(
    val active: Boolean,
    val packages: Set<String>,
    val plannedEndMillis: Long?,
    val focusTimes: List<FocusTimeRule> = emptyList(),
) {
    private fun sessionBlocks(nowMillis: Long): Boolean =
        active && (plannedEndMillis == null || nowMillis < plannedEndMillis)

    private fun activeFocusTime(nowMillis: Long): FocusTimeRule? =
        focusTimes.firstOrNull { it.isActiveAt(nowMillis) }

    /** Whether a session or a focus time runs at [nowMillis]. */
    fun focusing(nowMillis: Long): Boolean =
        sessionBlocks(nowMillis) || activeFocusTime(nowMillis) != null

    /**
     * Whether [packageName] must be blocked at [nowMillis]. Mirrors `blocksAt`
     * in lib/domain/blocking.dart.
     */
    fun blocks(packageName: String, nowMillis: Long): Boolean {
        if (sessionBlocks(nowMillis) && packageName in packages) return true
        val focusTime = activeFocusTime(nowMillis) ?: return false
        return packageName in packagesDuring(focusTime)
    }

    /** The apps [time] blocks: its own list, or the default list. */
    private fun packagesDuring(time: FocusTimeRule): Set<String> = time.packages ?: packages

    /**
     * How long to snooze a notification of [packageName], or null to show it.
     * Mirrors `snoozeFor` in lib/domain/blocking.dart: at most one minute per
     * round, so held notifications reappear soon after the session or focus
     * time ends.
     */
    fun snoozeMillis(packageName: String, nowMillis: Long): Long? {
        if (active && packageName in packages) {
            val end = plannedEndMillis ?: return SNOOZE_STEP_MILLIS
            val left = end - nowMillis
            if (left > 0) return minOf(left, SNOOZE_STEP_MILLIS)
        }
        val focusTime = activeFocusTime(nowMillis) ?: return null
        if (packageName !in packagesDuring(focusTime)) return null
        val left = focusTime.millisUntilEnd(nowMillis)
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
                    focusTimes = readFocusTimes(obj),
                )
            } catch (error: org.json.JSONException) {
                INACTIVE
            }
        }

        /** Focus times are optional: states written before #128 have none. */
        private fun readFocusTimes(obj: JSONObject): List<FocusTimeRule> {
            val times = obj.optJSONArray("focusTimes") ?: return emptyList()
            return (0 until times.length()).map { index ->
                val time = times.getJSONObject(index)
                val days = time.getJSONArray("weekdays")
                val apps = time.optJSONArray("packages")
                FocusTimeRule(
                    weekdays = (0 until days.length()).map { days.getInt(it) }.toSet(),
                    startMinute = time.getInt("start"),
                    endMinute = time.getInt("end"),
                    packages = apps?.let { list -> (0 until list.length()).map { list.getString(it) }.toSet() },
                )
            }
        }
    }
}
