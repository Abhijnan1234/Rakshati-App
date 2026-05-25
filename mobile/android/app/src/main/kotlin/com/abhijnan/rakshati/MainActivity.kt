package com.abhijnan.rakshati

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {
    private var pendingSharedText: String? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pendingSharedText = extractSharedText(intent) ?: pendingSharedText

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                when (call.method) {
                    "getInitialSharedText" -> result.success(pendingSharedText)
                    "clearInitialSharedText" -> {
                        pendingSharedText = null
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent, emitToStream = true)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun handleIncomingIntent(intent: Intent?, emitToStream: Boolean) {
        val sharedText = extractSharedText(intent) ?: return
        pendingSharedText = sharedText
        if (emitToStream) {
            eventSink?.success(sharedText)
        }
    }

    private fun extractSharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) {
            return null
        }

        val mimeType = intent.type ?: return null
        if (!mimeType.startsWith("text/")) {
            return null
        }

        val directText = intent.getStringExtra(Intent.EXTRA_TEXT)
        if (!directText.isNullOrBlank()) {
            return directText
        }

        val charSequenceText = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
        if (!charSequenceText.isNullOrBlank()) {
            return charSequenceText
        }

        return null
    }

    companion object {
        private const val METHOD_CHANNEL = "rakshati/share"
        private const val EVENT_CHANNEL = "rakshati/share_stream"
    }
}
