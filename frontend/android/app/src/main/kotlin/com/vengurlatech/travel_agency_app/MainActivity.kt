package com.vengurlatech.travel_agency_app

import android.app.Activity
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "trip_alarm/ringtone"
    private val pickRequestCode = 7341
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickRingtone" -> {
                        // Only one picker at a time; reject a second concurrent call.
                        if (pendingResult != null) {
                            result.error("busy", "A picker is already open", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        launchPicker(call.argument<String>("current"))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchPicker(currentUri: String?) {
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            // Offer alarm, ringtone and notification sounds (incl. any music the
            // user has set as a ringtone via the system).
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_TYPE,
                RingtoneManager.TYPE_ALARM or
                    RingtoneManager.TYPE_RINGTONE or
                    RingtoneManager.TYPE_NOTIFICATION,
            )
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select trip alarm sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            if (!currentUri.isNullOrEmpty()) {
                putExtra(
                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                    Uri.parse(currentUri),
                )
            }
        }
        try {
            startActivityForResult(intent, pickRequestCode)
        } catch (e: Exception) {
            pendingResult?.error("unavailable", "No ringtone picker on this device", null)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) return
        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            // Cancelled — null means "keep the existing choice".
            result.success(null)
            return
        }

        val uri: Uri? = data.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        if (uri == null) {
            result.success(null)
            return
        }
        val title = try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        } catch (e: Exception) {
            null
        }
        result.success(mapOf("uri" to uri.toString(), "title" to (title ?: "Custom sound")))
    }
}
