package com.soulheals.sanctum

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter engine for audio_service.
 *
 * Extends AudioServiceActivity rather than FlutterActivity so the
 * background playback service and the UI share one engine. With a plain
 * FlutterActivity the service starts a second, headless engine and the
 * handler the UI talks to is not the handler that owns the player.
 */
class MainActivity : AudioServiceActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // SystemNavigator.pop() calls finish(), which destroys
                    // this activity and its Flutter engine — taking the
                    // audio handler and the player with it, so a session
                    // dies the moment the user "leaves". Backgrounding the
                    // task instead keeps the engine and the foreground
                    // service alive, which is what a media app does.
                    "moveToBackground" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private companion object {
        const val CHANNEL = "sanctum/app"
    }
}
