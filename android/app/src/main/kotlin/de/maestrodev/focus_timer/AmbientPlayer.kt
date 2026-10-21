package de.maestrodev.focus_timer

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.view.KeyEvent

/**
 * Loops one bundled ambient sound (#122) while a session runs. Flutter tells
 * it what to play; it keeps playing while Focus is in the background as long
 * as Android keeps the app alive. `musicApp` (#266) instead sends the media
 * keys play / pause to the music app used last.
 */
object AmbientPlayer {
    private const val MUSIC_APP = "musicApp"

    private var player: MediaPlayer? = null
    private var current: String? = null

    /** [sound] is the name of `AmbientSound` in Dart, e.g. `softNoise`. */
    fun play(context: Context, sound: String, volume: Float) {
        if (sound == MUSIC_APP) {
            if (current == MUSIC_APP) return
            stop(context)
            sendMediaKey(context, KeyEvent.KEYCODE_MEDIA_PLAY)
            current = MUSIC_APP
            return
        }
        val level = volume.coerceIn(0f, 1f)
        val running = player
        if (running != null && current == sound) {
            running.setVolume(level, level)
            return
        }
        stop(context)
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

    /**
     * Stops the bundled sound, or pauses the music app – but only if Focus
     * started it, so music played outside sessions is never paused.
     */
    fun stop(context: Context) {
        if (current == MUSIC_APP) sendMediaKey(context, KeyEvent.KEYCODE_MEDIA_PAUSE)
        player?.run {
            stop()
            release()
        }
        player = null
        current = null
    }

    private fun sendMediaKey(context: Context, code: Int) {
        val audio = context.getSystemService(AudioManager::class.java) ?: return
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, code))
        audio.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, code))
    }

    /** `softNoise` → `R.raw.ambient_soft_noise`. */
    private fun resourceFor(context: Context, sound: String): Int? {
        val snake = sound.replace(Regex("([A-Z])")) { "_" + it.value.lowercase() }
        val id = context.resources.getIdentifier("ambient_$snake", "raw", context.packageName)
        return id.takeIf { it != 0 }
    }
}
