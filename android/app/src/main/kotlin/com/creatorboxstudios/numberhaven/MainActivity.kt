package com.creatorboxstudios.numberhaven

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.creatorboxstudios.numberhaven/audio_lifecycle"
    private var methodChannel: MethodChannel? = null
    private var isScreenReceiverRegistered = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                pauseGameAudio()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        try {
            val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
            registerReceiver(screenReceiver, filter)
            isScreenReceiverRegistered = true
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        if (isScreenReceiverRegistered) {
            try {
                unregisterReceiver(screenReceiver)
                isScreenReceiverRegistered = false
            } catch (_: Exception) {}
        }
        super.onDestroy()
    }

    private fun pauseGameAudio() {
        try {
            methodChannel?.invokeMethod("pauseAudio", null)
        } catch (_: Exception) {}
    }

    private fun resumeGameAudio() {
        try {
            methodChannel?.invokeMethod("resumeAudio", null)
        } catch (_: Exception) {}
    }

    override fun onPause() {
        super.onPause()
        pauseGameAudio()
    }

    override fun onStop() {
        super.onStop()
        pauseGameAudio()
    }

    override fun onResume() {
        super.onResume()
        resumeGameAudio()
    }
}
