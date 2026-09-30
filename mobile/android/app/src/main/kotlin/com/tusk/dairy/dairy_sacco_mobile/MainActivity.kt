package com.tusk.dairy.dairy_sacco_mobile

import android.app.PendingIntent
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageInstaller
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        /** Android's answer about an install we started (see [install]). */
        const val ACTION_INSTALL_STATUS = "com.tusk.dairy.INSTALL_STATUS"
    }

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dairygo/app_update")
            .apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "updatesDir" -> result.success(updatesDir().absolutePath)
                        "canInstall" -> result.success(canInstall())
                        "openInstallSettings" -> result.success(openInstallSettings())
                        // Copying the APK takes a moment: off the UI thread.
                        "install" -> {
                            val path = call.argument<String>("path")
                            Thread {
                                val started = install(path)
                                runOnUiThread { result.success(started) }
                            }.start()
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleInstallStatus(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleInstallStatus(intent)
    }

    /** Where downloaded updates are kept: private to the app. */
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

    /**
     * Installs a downloaded APK over this app through a PackageInstaller
     * session, the way app stores do. Android still checks it is signed with
     * the same key as this app.
     *
     * On Android 12 and newer, once DairyGo itself installed the version on
     * the phone, Android lets the next update go ahead without asking; the
     * app is closed and [UpdatedReceiver] opens it again. Otherwise Android
     * shows its confirm screen ([handleInstallStatus]).
     */
    private fun install(path: String?): Boolean {
        if (path == null) return false
        val file = File(path).canonicalFile
        // Only files the updater downloaded, never a path from elsewhere.
        if (file.parentFile != updatesDir().canonicalFile || !file.isFile) return false

        val installer = packageManager.packageInstaller
        // An earlier attempt left waiting (for example a confirm screen that
        // was put away) is replaced by this one.
        for (old in installer.mySessions) {
            try {
                installer.abandonSession(old.sessionId)
            } catch (e: SecurityException) {
                // Already finished.
            }
        }

        val params = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL)
        params.setAppPackageName(packageName)
        params.setSize(file.length())
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            params.setInstallReason(PackageManager.INSTALL_REASON_USER)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            params.setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
        }

        return try {
            val id = installer.createSession(params)
            installer.openSession(id).use { session ->
                file.inputStream().use { input ->
                    session.openWrite("DairyGo.apk", 0, file.length()).use { output ->
                        input.copyTo(output)
                        session.fsync(output)
                    }
                }
                // Ask to be opened again once the new version is in place.
                UpdatedReceiver.relaunchMarker(this).createNewFile()
                val status = Intent(this, MainActivity::class.java).setAction(ACTION_INSTALL_STATUS)
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
                session.commit(PendingIntent.getActivity(this, id, status, flags).intentSender)
            }
            true
        } catch (e: Exception) {
            UpdatedReceiver.relaunchMarker(this).delete()
            false
        }
    }

    /** Android's answer about an install: show its confirm screen when it
     *  needs one, and tell the app how it ended. After a successful update
     *  this runs in the new version, with nothing more to do. */
    private fun handleInstallStatus(intent: Intent?) {
        if (intent?.action != ACTION_INSTALL_STATUS) return
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        val message = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
        setIntent(Intent(Intent.ACTION_MAIN))
        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val confirm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_INTENT)
                }
                try {
                    confirm?.let { startActivity(it) }
                    report("confirming", null)
                } catch (e: ActivityNotFoundException) {
                    report("failed", "The installer could not be opened")
                }
            }
            PackageInstaller.STATUS_SUCCESS -> report("installed", null)
            PackageInstaller.STATUS_FAILURE_ABORTED -> {
                UpdatedReceiver.relaunchMarker(this).delete()
                report("cancelled", null)
            }
            else -> {
                UpdatedReceiver.relaunchMarker(this).delete()
                report("failed", message)
            }
        }
    }

    private fun report(status: String, message: String?) {
        channel?.invokeMethod("installStatus", mapOf("status" to status, "message" to message))
    }
}
