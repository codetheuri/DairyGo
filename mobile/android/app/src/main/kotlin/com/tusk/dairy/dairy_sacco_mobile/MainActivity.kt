package com.tusk.dairy.dairy_sacco_mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dairygo/app_update")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updatesDir" -> result.success(updatesDir().absolutePath)
                    "canInstall" -> result.success(canInstall())
                    "openInstallSettings" -> result.success(openInstallSettings())
                    "install" -> result.success(install(call.argument<String>("path")))
                    else -> result.notImplemented()
                }
            }
    }

    /** Where downloaded updates are kept: private to the app, shared with the
     *  installer only through the FileProvider (res/xml/update_paths.xml). */
    private fun updatesDir(): File = File(filesDir, "updates").apply { mkdirs() }

    /** Whether the user has allowed DairyGo to install updates (Android 8+
     *  asks per app; older versions ask during the install). */
    private fun canInstall(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    /** Opens the "Install unknown apps" switch for DairyGo. */
    private fun openInstallSettings(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            startActivity(
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:$packageName")),
            )
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** Hands a downloaded APK to Android's installer, which asks the user to
     *  confirm and checks it is signed with the same key as this app. */
    private fun install(path: String?): Boolean {
        if (path == null) return false
        val file = File(path).canonicalFile
        // Only files the updater downloaded, never a path from elsewhere.
        if (file.parentFile != updatesDir().canonicalFile || !file.isFile) return false
        val uri = FileProvider.getUriForFile(this, "$packageName.updates", file)
        val intent = Intent(Intent.ACTION_VIEW)
            .setDataAndType(uri, "application/vnd.android.package-archive")
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
