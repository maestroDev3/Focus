package de.maestrodev.focus_timer

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import java.text.DateFormat
import java.util.Date

/**
 * Quick settings tile (story #196): one tap starts a session with the
 * defaults, exactly like the home screen widget; while a session runs the
 * tile is active, shows the end time and opens Focus. Long press opens Focus
 * through `QS_TILE_PREFERENCES` on [MainActivity].
 */
@TargetApi(Build.VERSION_CODES.N)
class FocusTileService : TileService() {
    override fun onStartListening() {
        super.onStartListening()
        render()
    }

    override fun onClick() {
        super.onClick()
        if (BlockingState.read(this).active) {
            openFocus()
        } else {
            HomeWidget.start(this)
            render()
        }
    }

    private fun render() {
        val tile = qsTile ?: return
        val state = BlockingState.read(this)
        val end = state.plannedEndMillis
        tile.label = getString(R.string.tile_label)
        if (state.active) {
            tile.state = Tile.STATE_ACTIVE
            setSubtitle(
                tile,
                if (end != null) {
                    getString(
                        R.string.tile_until,
                        DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(end)),
                    )
                } else {
                    getString(R.string.tile_paused)
                },
            )
        } else {
            tile.state = Tile.STATE_INACTIVE
            val minutes = getSharedPreferences("home_widget", Context.MODE_PRIVATE)
                .getInt("focusMinutes", DEFAULT_MINUTES)
            setSubtitle(tile, getString(R.string.tile_minutes, minutes))
        }
        tile.updateTile()
    }

    private fun setSubtitle(tile: Tile, text: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) tile.subtitle = text
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    private fun openFocus() {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startActivityAndCollapse(
                PendingIntent.getActivity(
                    this,
                    7307,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    companion object {
        private const val DEFAULT_MINUTES = 25

        /** Asks the system to redraw the tile, e.g. after a session started or ended. */
        fun refresh(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
            requestListeningState(context, ComponentName(context, FocusTileService::class.java))
        }
    }
}
