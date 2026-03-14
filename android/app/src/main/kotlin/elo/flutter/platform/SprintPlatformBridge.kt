package elo.flutter.platform

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.view.WindowManager
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import elo.flutter.domain.Player
import elo.flutter.nearby.DiscoveredHost
import elo.flutter.nearby.LocalConnectionMedium
import elo.flutter.nearby.LocalLeaderboardConnectionController
import elo.flutter.nearby.LocalLeaderboardConnectionManager
import elo.flutter.nearby.LocalLeaderboardSnapshot
import elo.flutter.nearby.LocalSessionPhase
import elo.flutter.nearby.LocalSessionRole
import elo.flutter.nearby.LocalSessionState
import elo.flutter.nearby.LocalControlMessage

class SprintPlatformBridge(
    private val activity: FlutterFragmentActivity,
    messenger: BinaryMessenger,
    private val localController: LocalLeaderboardConnectionController = LocalLeaderboardConnectionManager(activity),
) : MethodChannel.MethodCallHandler {

    private val methodChannel = MethodChannel(messenger, CHANNEL_NAME)
    private val bridgeScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var stateCollectionJob: Job? = null
    private var pendingNearbyAction: PendingNearbyAction? = null
    private var immersiveShowStatusBar: Boolean = true

    private val nearbyPermissionLauncher = activity.registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { grants ->
        val granted = grants.values.all { it }
        val action = pendingNearbyAction
        pendingNearbyAction = null

        if (granted && action != null) {
            executeNearbyAction(action)
            return@registerForActivityResult
        }

        if (!granted) {
            emitError("Nearby connection permissions are required for local display mode")
        }
    }

    fun attach() {
        methodChannel.setMethodCallHandler(this)
        startStateCollectors()
    }

    fun detach() {
        methodChannel.setMethodCallHandler(null)
        stateCollectionJob?.cancel()
        stateCollectionJob = null
        bridgeScope.cancel()
        localController.useDatabaseMode()
    }

    fun applyImmersiveMode(showStatusBar: Boolean = immersiveShowStatusBar) {
        immersiveShowStatusBar = showStatusBar
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            activity.window.attributes = activity.window.attributes.apply {
                layoutInDisplayCutoutMode = if (showStatusBar) {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT
                } else {
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                }
            }
        }
        WindowCompat.setDecorFitsSystemWindows(activity.window, false)
        WindowInsetsControllerCompat(activity.window, activity.window.decorView).apply {
            hide(WindowInsetsCompat.Type.navigationBars())
            if (showStatusBar) {
                show(WindowInsetsCompat.Type.statusBars())
            } else {
                hide(WindowInsetsCompat.Type.statusBars())
            }
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "nearbyStartHost" -> {
                val localName = call.stringArg("localEndpointName")
                ensureNearbyPermissionsAndRun(PendingNearbyAction.StartHost(localName))
                result.success(null)
            }

            "nearbyStopHost" -> {
                localController.stopHosting()
                result.success(null)
            }

            "nearbyScanHosts" -> {
                val localName = call.stringArg("localEndpointName")
                ensureNearbyPermissionsAndRun(PendingNearbyAction.ScanHosts(localName))
                result.success(null)
            }

            "nearbyConnectHost" -> {
                val endpointId = call.requiredStringArg("endpointId", result) ?: return
                ensureNearbyPermissionsAndRun(PendingNearbyAction.ConnectHost(endpointId))
                result.success(null)
            }

            "nearbyAcceptConnection" -> {
                localController.acceptPendingConnection()
                result.success(null)
            }

            "nearbyRejectConnection" -> {
                localController.rejectPendingConnection()
                result.success(null)
            }

            "nearbyDisconnect" -> {
                localController.disconnect()
                result.success(null)
            }

            "nearbyUseDb" -> {
                localController.useDatabaseMode()
                result.success(null)
            }

            "publishLocalSnapshot" -> {
                val snapshot = call.requiredSnapshotArg(result) ?: return
                localController.publishHostedSnapshot(snapshot)
                result.success(null)
            }

            "sendLocalControl" -> {
                val control = call.requiredControlArg(result) ?: return
                localController.sendControl(control)
                result.success(null)
            }

            "setImmersiveMode" -> {
                val showStatusBar = call.argument<Boolean>("showStatusBar") ?: true
                applyImmersiveMode(showStatusBar = showStatusBar)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun startStateCollectors() {
        if (stateCollectionJob != null) {
            return
        }

        stateCollectionJob = bridgeScope.launch {
            launch {
                localController.sessionState.collect { sessionState ->
                    emitPlatformEvent(
                        "local_session_state",
                        sessionState.toWireMap(),
                    )
                }
            }
            launch {
                localController.receivedSnapshot.collect { snapshot ->
                    if (snapshot != null) {
                        emitPlatformEvent("local_snapshot", snapshot.toWireMap())
                    }
                }
            }
            launch {
                localController.controlEvents.collect { control ->
                    emitPlatformEvent(
                        "local_control_event",
                        mapOf("action" to control.toWireValue()),
                    )
                }
            }
        }
    }

    private fun ensureNearbyPermissionsAndRun(action: PendingNearbyAction) {
        val missingPermissions = requiredNearbyPermissions().filterNot(::isPermissionGranted)
        if (missingPermissions.isEmpty()) {
            executeNearbyAction(action)
            return
        }

        pendingNearbyAction = action
        nearbyPermissionLauncher.launch(missingPermissions.toTypedArray())
    }

    private fun executeNearbyAction(action: PendingNearbyAction) {
        when (action) {
            is PendingNearbyAction.StartHost -> localController.startHosting(action.localEndpointName)
            is PendingNearbyAction.ScanHosts -> localController.startDiscovery(action.localEndpointName)
            is PendingNearbyAction.ConnectHost -> localController.connectToHost(action.endpointId)
        }
    }

    private fun requiredNearbyPermissions(): List<String> {
        val permissions = mutableListOf(
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions += Manifest.permission.NEARBY_WIFI_DEVICES
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions += Manifest.permission.BLUETOOTH_ADVERTISE
            permissions += Manifest.permission.BLUETOOTH_CONNECT
            permissions += Manifest.permission.BLUETOOTH_SCAN
        }
        return permissions.distinct()
    }

    private fun isPermissionGranted(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun emitError(message: String) {
        emitPlatformEvent(
            "error",
            mapOf("message" to message),
        )
    }

    private fun emitPlatformEvent(type: String, data: Map<String, Any?>) {
        methodChannel.invokeMethod(
            "onPlatformEvent",
            mapOf(
                "type" to type,
                "data" to data,
            ),
        )
    }

    private fun LocalSessionState.toWireMap(): Map<String, Any?> = mapOf(
        "role" to role.toWireValue(),
        "phase" to phase.toWireValue(),
        "connectionMedium" to connectionMedium.toWireValue(),
        "discoveredHosts" to discoveredHosts.map { host -> host.toWireMap() },
        "pendingConnectionName" to pendingConnectionName,
        "connectedHostName" to connectedHostName,
        "localEndpointName" to localEndpointName,
        "authToken" to authToken,
        "lastLocalUpdateEpochMillis" to lastLocalUpdateEpochMillis,
        "errorMessage" to errorMessage,
    )

    private fun LocalLeaderboardSnapshot.toWireMap(): Map<String, Any?> = mapOf(
        "hostDisplayName" to hostDisplayName,
        "generatedAtEpochMillis" to generatedAtEpochMillis,
        "kFactor" to kFactor,
        "lastSyncedEpochMillis" to lastSyncedEpochMillis,
        "players" to players.map { player -> player.toWireMap() },
    )

    private fun DiscoveredHost.toWireMap(): Map<String, Any?> = mapOf(
        "endpointId" to endpointId,
        "displayName" to displayName,
    )

    private fun Player.toWireMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "name" to name,
        "elo" to elo,
        "wins" to wins,
        "losses" to losses,
        "draws" to draws,
        "matchesPlayed" to matchesPlayed,
    )

    private fun LocalSessionRole.toWireValue(): String = when (this) {
        LocalSessionRole.NONE -> "none"
        LocalSessionRole.HOST -> "host"
        LocalSessionRole.CLIENT -> "client"
    }

    private fun LocalSessionPhase.toWireValue(): String = when (this) {
        LocalSessionPhase.IDLE -> "idle"
        LocalSessionPhase.ADVERTISING -> "advertising"
        LocalSessionPhase.DISCOVERING -> "discovering"
        LocalSessionPhase.CONNECTING -> "connecting"
        LocalSessionPhase.AWAITING_APPROVAL -> "awaiting-approval"
        LocalSessionPhase.CONNECTED -> "connected"
        LocalSessionPhase.DISCONNECTED -> "disconnected"
        LocalSessionPhase.ERROR -> "error"
    }

    private fun LocalConnectionMedium.toWireValue(): String = when (this) {
        LocalConnectionMedium.UNKNOWN -> "unknown"
        LocalConnectionMedium.BLE -> "ble"
        LocalConnectionMedium.BT -> "bt"
        LocalConnectionMedium.WIFI -> "wifi"
    }

    private fun MethodCall.stringArg(key: String): String {
        val value = argument<String>(key)?.trim().orEmpty()
        return if (value.isBlank()) DEFAULT_ENDPOINT_NAME else value
    }

    private fun MethodCall.requiredStringArg(
        key: String,
        result: MethodChannel.Result,
    ): String? {
        val value = argument<String>(key)?.trim()
        if (value.isNullOrBlank()) {
            result.error("bad_payload", "Missing $key", null)
            return null
        }
        return value
    }

    private fun MethodCall.requiredSnapshotArg(result: MethodChannel.Result): LocalLeaderboardSnapshot? {
        val root = arguments as? Map<*, *>
        val snapshotRaw = root?.get("snapshot") as? Map<*, *>
        if (snapshotRaw == null) {
            result.error("bad_payload", "Missing snapshot", null)
            return null
        }
        val snapshot = snapshotRaw.toSnapshot()
        if (snapshot == null) {
            result.error("bad_payload", "Invalid snapshot payload", null)
            return null
        }
        return snapshot
    }

    private fun MethodCall.requiredControlArg(
        result: MethodChannel.Result,
    ): LocalControlMessage? {
        val action = argument<String>("action")?.trim()
        val control = controlFromWireValue(action)
        if (control == null) {
            result.error("bad_payload", "Invalid control action", null)
            return null
        }
        return control
    }

    private fun Map<*, *>.toSnapshot(): LocalLeaderboardSnapshot? {
        val hostDisplayName = this["hostDisplayName"]?.toString()?.trim().orEmpty()
        if (hostDisplayName.isBlank()) {
            return null
        }

        val players = (this["players"] as? List<*>)
            .orEmpty()
            .mapNotNull { item -> (item as? Map<*, *>)?.toPlayer() }

        return LocalLeaderboardSnapshot(
            hostDisplayName = hostDisplayName,
            generatedAtEpochMillis = this["generatedAtEpochMillis"].toLongValue(default = System.currentTimeMillis()),
            kFactor = this["kFactor"].toIntValue(default = 32),
            lastSyncedEpochMillis = this["lastSyncedEpochMillis"].toNullableLongValue(),
            players = players,
        )
    }

    private fun Map<*, *>.toPlayer(): Player? {
        val id = this["id"]?.toString()?.trim().orEmpty()
        val name = this["name"]?.toString()?.trim().orEmpty()
        if (id.isBlank() || name.isBlank()) {
            return null
        }

        return Player(
            id = id,
            name = name,
            elo = this["elo"].toIntValue(default = 1200),
            wins = this["wins"].toIntValue(default = 0),
            losses = this["losses"].toIntValue(default = 0),
            draws = this["draws"].toIntValue(default = 0),
            matchesPlayed = this["matchesPlayed"].toIntValue(default = 0),
        )
    }

    private fun Any?.toIntValue(default: Int): Int = when (this) {
        is Int -> this
        is Number -> this.toInt()
        is String -> this.toIntOrNull() ?: default
        else -> default
    }

    private fun Any?.toLongValue(default: Long): Long = when (this) {
        is Long -> this
        is Number -> this.toLong()
        is String -> this.toLongOrNull() ?: default
        else -> default
    }

    private fun Any?.toNullableLongValue(): Long? = when (this) {
        null -> null
        is Long -> this
        is Number -> this.toLong()
        is String -> this.toLongOrNull()
        else -> null
    }

    private fun LocalControlMessage.toWireValue(): String = when (this) {
        LocalControlMessage.START_MATCH_BEEP -> "start_match_beep"
    }

    private fun controlFromWireValue(value: String?): LocalControlMessage? {
        return when (value) {
            "start_match_beep" -> LocalControlMessage.START_MATCH_BEEP
            else -> null
        }
    }

    sealed interface PendingNearbyAction {
        data class StartHost(val localEndpointName: String) : PendingNearbyAction
        data class ScanHosts(val localEndpointName: String) : PendingNearbyAction
        data class ConnectHost(val endpointId: String) : PendingNearbyAction
    }

    companion object {
        private const val CHANNEL_NAME = "sprint/platform_methods"
        private const val DEFAULT_ENDPOINT_NAME = "Sprint Device"
    }
}


