package de.maestrodev.focus_timer

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer

/**
 * Loops one bundled ambient sound (#122) while a session runs. Flutter tells
 * it what to play; it keeps playing while Focus is in the background as long
 * as Android keeps the app alive.
 */
object AmbientPlayer {
    private var player: MediaPlayer? = null
    private var current: String? = null

    /** [sound] is the name of `AmbientSound` in Dart, e.g. `softNoise`. */
    fun play(context: Context, sound: String, volume: Float) {
        val level = volume.coerceIn(0f, 1f)
        val running = player
        if (running != null && current == sound) {
            running.setVolume(level, level)
            return
        }
        stop()
        val resource = resourceFor(context, sound) ?: return
        player = MediaPlayer.create(
            context,
            resource,
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build(),
            0,
        )?.apply {
            isLooping = true
            setVolume(level, level)
            start()
        }
        current = sound
    }

    fun stop() {
        player?.run {
            stop()
            release()
        }
        player = null
        current = null
    }

    /** `softNoise` → `R.raw.ambient_soft_noise`. */
    private fun resourceFor(context: Context, sound: String): Int? {
        val snake = sound.replace(Regex("([A-Z])")) { "_" + it.value.lowercase() }
        val id = context.resources.getIdentifier("ambient_$snake", "raw", context.packageName)
        return id.takeIf { it != 0 }
    }
}
