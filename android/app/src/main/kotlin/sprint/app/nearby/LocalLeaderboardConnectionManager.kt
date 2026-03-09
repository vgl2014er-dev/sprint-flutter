package sprint.app.nearby

import android.content.Context
import android.util.Log
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.AdvertisingOptions
import com.google.android.gms.nearby.connection.ConnectionInfo
import com.google.android.gms.nearby.connection.ConnectionLifecycleCallback
import com.google.android.gms.nearby.connection.ConnectionResolution
import com.google.android.gms.nearby.connection.ConnectionsClient
import com.google.android.gms.nearby.connection.DiscoveredEndpointInfo
import com.google.android.gms.nearby.connection.DiscoveryOptions
import com.google.android.gms.nearby.connection.EndpointDiscoveryCallback
import com.google.android.gms.nearby.connection.Payload
import com.google.android.gms.nearby.connection.PayloadCallback
import com.google.android.gms.nearby.connection.PayloadTransferUpdate
import com.google.android.gms.nearby.connection.Strategy
import com.google.android.gms.common.api.Status
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class LocalLeaderboardConnectionManager(
    context: Context,
    private val serviceId: String = context.packageName,
    private val connectionsClient: ConnectionsClient = Nearby.getConnectionsClient(context.applicationContext),
) : LocalLeaderboardConnectionController {

    private val _sessionState = MutableStateFlow(LocalSessionState())
    override val sessionState: StateFlow<LocalSessionState> = _sessionState.asStateFlow()

    private val _receivedSnapshot = MutableStateFlow<LocalLeaderboardSnapshot?>(null)
    override val receivedSnapshot: StateFlow<LocalLeaderboardSnapshot?> = _receivedSnapshot.asStateFlow()

    private var activeRole: LocalSessionRole = LocalSessionRole.NONE
    private var localEndpointName: String? = null
    private var pendingEndpointId: String? = null
    private var connectedEndpointId: String? = null
    private var latestHostedSnapshot: LocalLeaderboardSnapshot? = null

    override fun startHosting(localEndpointName: String) {
        this.localEndpointName = localEndpointName
        latestHostedSnapshot = null
        resetSession(role = LocalSessionRole.HOST, phase = LocalSessionPhase.ADVERTISING)
        connectionsClient.stopDiscovery()
        connectionsClient.stopAdvertising()
        connectionsClient.stopAllEndpoints()
        connectionsClient.startAdvertising(
            localEndpointName,
            serviceId,
            connectionLifecycleCallback,
            AdvertisingOptions.Builder().setStrategy(Strategy.P2P_STAR).build(),
        ).addOnFailureListener { error ->
            publishError(LocalSessionRole.HOST, localEndpointName, error.message ?: "Failed to start hosting")
        }
    }

    override fun stopHosting() {
        connectionsClient.stopAdvertising()
        connectedEndpointId?.let(connectionsClient::disconnectFromEndpoint)
        connectionsClient.stopAllEndpoints()
        pendingEndpointId = null
        connectedEndpointId = null
        activeRole = LocalSessionRole.NONE
        _sessionState.value = LocalSessionState()
    }

    override fun startDiscovery(localEndpointName: String) {
        this.localEndpointName = localEndpointName
        activeRole = LocalSessionRole.CLIENT
        pendingEndpointId = null
        connectedEndpointId = null
        _sessionState.value = LocalSessionState(
            role = LocalSessionRole.CLIENT,
            phase = LocalSessionPhase.DISCOVERING,
            localEndpointName = localEndpointName,
        )
        connectionsClient.stopAdvertising()
        connectionsClient.stopDiscovery()
        connectionsClient.startDiscovery(
            serviceId,
            endpointDiscoveryCallback,
            DiscoveryOptions.Builder().setStrategy(Strategy.P2P_STAR).build(),
        ).addOnFailureListener { error ->
            publishError(LocalSessionRole.CLIENT, localEndpointName, error.message ?: "Failed to scan for hosts")
        }
    }

    override fun connectToHost(endpointId: String) {
        val endpointName = sessionState.value.discoveredHosts.firstOrNull { it.endpointId == endpointId }?.displayName
        val requesterName = localEndpointName ?: DEFAULT_ENDPOINT_NAME
        activeRole = LocalSessionRole.CLIENT
        _sessionState.value = sessionState.value.copy(
            role = LocalSessionRole.CLIENT,
            phase = LocalSessionPhase.CONNECTING,
            pendingConnectionName = endpointName,
            errorMessage = null,
            localEndpointName = requesterName,
        )
        connectionsClient.requestConnection(
            requesterName,
            endpointId,
            connectionLifecycleCallback,
        ).addOnFailureListener { error ->
            publishError(
                LocalSessionRole.CLIENT,
                requesterName,
                error.message ?: "Failed to request connection",
            )
        }
    }

    override fun acceptPendingConnection() {
        val endpointId = pendingEndpointId ?: return
        connectionsClient.acceptConnection(endpointId, payloadCallback)
            .addOnFailureListener { error ->
                publishError(
                    activeRole,
                    localEndpointName,
                    error.message ?: "Failed to accept connection",
                )
            }
    }

    override fun rejectPendingConnection() {
        val endpointId = pendingEndpointId ?: return
        connectionsClient.rejectConnection(endpointId)
            .addOnFailureListener { error ->
                publishError(
                    activeRole,
                    localEndpointName,
                    error.message ?: "Failed to reject connection",
                )
            }
        pendingEndpointId = null
        _sessionState.value = _sessionState.value.copy(
            phase = phaseAfterPendingCleared(activeRole),
            pendingConnectionName = null,
            authToken = null,
            errorMessage = null,
        )
    }

    override fun disconnect() {
        connectedEndpointId?.let(connectionsClient::disconnectFromEndpoint)
        pendingEndpointId = null
        connectedEndpointId = null
        connectionsClient.stopAllEndpoints()
        connectionsClient.stopDiscovery()

        _sessionState.value = when (activeRole) {
            LocalSessionRole.CLIENT -> _sessionState.value.copy(
                role = LocalSessionRole.CLIENT,
                phase = LocalSessionPhase.DISCONNECTED,
                pendingConnectionName = null,
                connectedHostName = null,
                authToken = null,
            )

            LocalSessionRole.HOST -> _sessionState.value.copy(
                role = LocalSessionRole.HOST,
                phase = LocalSessionPhase.ADVERTISING,
                pendingConnectionName = null,
                connectedHostName = null,
                authToken = null,
            )

            LocalSessionRole.NONE -> LocalSessionState()
        }
    }

    override fun useDatabaseMode() {
        connectionsClient.stopAdvertising()
        connectionsClient.stopDiscovery()
        connectionsClient.stopAllEndpoints()
        pendingEndpointId = null
        connectedEndpointId = null
        activeRole = LocalSessionRole.NONE
        _receivedSnapshot.value = null
        _sessionState.value = LocalSessionState()
    }

    override fun publishHostedSnapshot(snapshot: LocalLeaderboardSnapshot) {
        val hostName = _sessionState.value.localEndpointName ?: snapshot.hostDisplayName
        val hostedSnapshot = snapshot.copy(hostDisplayName = hostName)
        latestHostedSnapshot = hostedSnapshot
        val endpointId = connectedEndpointId ?: return
        connectionsClient.sendPayload(endpointId, Payload.fromBytes(LocalLeaderboardSnapshotCodec.encode(hostedSnapshot)))
            .addOnFailureListener { error ->
                publishError(
                    LocalSessionRole.HOST,
                    hostName,
                    error.message ?: "Failed to send local leaderboard update",
                )
            }
    }

    private fun resetSession(role: LocalSessionRole, phase: LocalSessionPhase) {
        activeRole = role
        pendingEndpointId = null
        connectedEndpointId = null
        _sessionState.value = LocalSessionState(
            role = role,
            phase = phase,
            localEndpointName = localEndpointName,
        )
    }

    private fun publishError(
        role: LocalSessionRole,
        localEndpointName: String?,
        message: String,
    ) {
        Log.e(TAG, message)
        _sessionState.value = _sessionState.value.copy(
            role = role,
            phase = LocalSessionPhase.ERROR,
            localEndpointName = localEndpointName,
            errorMessage = message,
        )
    }

    private fun phaseAfterPendingCleared(role: LocalSessionRole): LocalSessionPhase = when (role) {
        LocalSessionRole.HOST -> LocalSessionPhase.ADVERTISING
        LocalSessionRole.CLIENT -> LocalSessionPhase.DISCOVERING
        LocalSessionRole.NONE -> LocalSessionPhase.IDLE
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            if (activeRole != LocalSessionRole.CLIENT) return
            val host = DiscoveredHost(
                endpointId = endpointId,
                displayName = info.endpointName.ifBlank { DEFAULT_ENDPOINT_NAME },
            )
            _sessionState.value = _sessionState.value.copy(
                role = LocalSessionRole.CLIENT,
                phase = if (_sessionState.value.phase == LocalSessionPhase.ERROR) {
                    LocalSessionPhase.DISCOVERING
                } else {
                    _sessionState.value.phase
                },
                discoveredHosts = (_sessionState.value.discoveredHosts + host)
                    .distinctBy { it.endpointId }
                    .sortedBy { it.displayName },
                errorMessage = null,
            )
        }

        override fun onEndpointLost(endpointId: String) {
            if (activeRole != LocalSessionRole.CLIENT) return
            _sessionState.value = _sessionState.value.copy(
                discoveredHosts = _sessionState.value.discoveredHosts.filterNot { it.endpointId == endpointId },
            )
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) {
            if (connectedEndpointId != null || (pendingEndpointId != null && pendingEndpointId != endpointId)) {
                connectionsClient.rejectConnection(endpointId)
                return
            }

            pendingEndpointId = endpointId
            @Suppress("DEPRECATION")
            val authToken = info.authenticationToken
            _sessionState.value = _sessionState.value.copy(
                role = activeRole,
                phase = LocalSessionPhase.AWAITING_APPROVAL,
                pendingConnectionName = info.endpointName,
                authToken = authToken,
                errorMessage = null,
            )
        }

        override fun onConnectionResult(endpointId: String, resolution: ConnectionResolution) {
            val status = resolution.status
            if (status.isSuccess) {
                pendingEndpointId = null
                connectedEndpointId = endpointId
                if (activeRole == LocalSessionRole.CLIENT) {
                    connectionsClient.stopDiscovery()
                }
                _sessionState.value = _sessionState.value.copy(
                    role = activeRole,
                    phase = LocalSessionPhase.CONNECTED,
                    connectedHostName = _sessionState.value.pendingConnectionName,
                    pendingConnectionName = null,
                    authToken = null,
                    discoveredHosts = emptyList(),
                    errorMessage = null,
                )
                latestHostedSnapshot?.let(::publishHostedSnapshot)
                return
            }

            pendingEndpointId = null
            connectedEndpointId = null
            val errorMessage = status.statusMessage?.takeIf { it.isNotBlank() }
                ?: "Connection failed (${status.statusCode})"
            _sessionState.value = _sessionState.value.copy(
                role = activeRole,
                phase = if (activeRole == LocalSessionRole.CLIENT) {
                    LocalSessionPhase.DISCONNECTED
                } else {
                    LocalSessionPhase.ADVERTISING
                },
                pendingConnectionName = null,
                connectedHostName = null,
                authToken = null,
                errorMessage = errorMessage,
            )
        }

        override fun onDisconnected(endpointId: String) {
            if (connectedEndpointId == endpointId) {
                connectedEndpointId = null
            }
            _sessionState.value = _sessionState.value.copy(
                role = activeRole,
                phase = if (activeRole == LocalSessionRole.CLIENT) {
                    LocalSessionPhase.DISCONNECTED
                } else {
                    LocalSessionPhase.ADVERTISING
                },
                connectedHostName = null,
                authToken = null,
                errorMessage = if (activeRole == LocalSessionRole.CLIENT) {
                    "Local connection lost"
                } else {
                    null
                },
            )
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            val bytes = payload.asBytes() ?: return
            val snapshot = LocalLeaderboardSnapshotCodec.decode(bytes)
            if (snapshot == null) {
                publishError(
                    LocalSessionRole.CLIENT,
                    localEndpointName,
                    "Received invalid local leaderboard payload",
                )
                return
            }
            _receivedSnapshot.value = snapshot
            _sessionState.value = _sessionState.value.copy(
                role = LocalSessionRole.CLIENT,
                phase = LocalSessionPhase.CONNECTED,
                connectedHostName = snapshot.hostDisplayName,
                lastLocalUpdateEpochMillis = System.currentTimeMillis(),
                errorMessage = null,
            )
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) = Unit
    }

    companion object {
        private const val TAG = "LocalLeaderboardConn"
        private const val DEFAULT_ENDPOINT_NAME = "Sprint Device"
    }
}
