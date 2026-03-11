package elo.flutter

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import elo.flutter.platform.SprintPlatformBridge

class MainActivity : FlutterFragmentActivity() {
    private var platformBridge: SprintPlatformBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        platformBridge?.detach()
        platformBridge = SprintPlatformBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        ).also { bridge ->
            bridge.attach()
            bridge.applyImmersiveMode()
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            platformBridge?.applyImmersiveMode()
        }
    }

    override fun onDestroy() {
        platformBridge?.detach()
        platformBridge = null
        super.onDestroy()
    }
}
