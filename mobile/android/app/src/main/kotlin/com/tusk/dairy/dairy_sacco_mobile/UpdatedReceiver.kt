package com.tusk.dairy.dairy_sacco_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.io.File

/**
 * Runs in the new version right after an update is installed: when the
 * update was started from inside the app, opens DairyGo again, so updating
 * feels like a restart.
 *
 * Some phones (Android 10 and newer) do not let an app open itself from the
 * background; there the user opens DairyGo from its icon.
 */
class UpdatedReceiver : BroadcastReceiver() {
    companion object {
        /** Left by MainActivity.install: the update came from the app. */
        fun relaunchMarker(context: Context) = File(context.filesDir, "relaunch-after-update")
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        // Updated some other way (for example an APK opened from WhatsApp):
        // that installer offers to open the app itself.
        if (!relaunchMarker(context).delete()) return
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: return
        launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(launch)
        } catch (e: Exception) {
            // Not allowed on this phone: the app opens from its icon.
        }
    }
}
