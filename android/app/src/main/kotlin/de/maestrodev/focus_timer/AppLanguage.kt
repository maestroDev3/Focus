package de.maestrodev.focus_timer

import android.app.LocaleManager
import android.content.Context
import android.os.Build
import android.os.LocaleList

/**
 * The language chosen for Focus. From Android 13 it is the per-app language,
 * so the choice in Focus and in the Android settings is one and the same;
 * before that Focus keeps it in its own preferences.
 */
object AppLanguage {
    private const val PREFERENCES = "focus_language"
    private const val KEY = "tag"

    /** The chosen language tag, or null to follow the phone language. */
    fun get(context: Context): String? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val locales = context.getSystemService(LocaleManager::class.java).applicationLocales
            if (locales.isEmpty) null else locales[0].toLanguageTag()
        } else {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getString(KEY, null)
        }

    fun set(context: Context, tag: String?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.getSystemService(LocaleManager::class.java).applicationLocales =
                if (tag == null) LocaleList.getEmptyLocaleList() else LocaleList.forLanguageTags(tag)
        } else {
            context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit()
                .apply { if (tag == null) remove(KEY) else putString(KEY, tag) }
                .apply()
        }
    }
}
