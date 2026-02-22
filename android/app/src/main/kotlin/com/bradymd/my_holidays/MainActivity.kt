package com.bradymd.my_holidays

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.bradymd.my_holidays/share"
    private var initialFilePath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        initialFilePath = handleIntent(intent)

        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, channelName).setMethodCallHandler { call, result ->
                if (call.method == "getInitialFile") {
                    result.success(initialFilePath)
                    initialFilePath = null
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val path = handleIntent(intent) ?: return
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, channelName).invokeMethod("openFile", path)
        }
    }

    private fun handleIntent(intent: Intent): String? {
        if (intent.action != Intent.ACTION_VIEW) return null
        val uri = intent.data ?: return null

        // For file:// URIs, check extension directly
        if (uri.scheme == "file") {
            val path = uri.path ?: return null
            return if (path.endsWith(".myholiday")) path else null
        }

        // For content:// URIs, copy to temp file — Flutter will validate contents
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val tempFile = File(cacheDir, "import.myholiday")
            tempFile.outputStream().use { output -> inputStream.copyTo(output) }
            inputStream.close()
            tempFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }
}
