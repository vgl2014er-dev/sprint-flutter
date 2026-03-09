package sprint.app.direct

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.util.Log
import java.io.BufferedReader
import java.io.BufferedWriter
import java.io.IOException
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.nio.charset.StandardCharsets
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import sprint.app.nearby.LocalLeaderboardSnapshot
import sprint.app.nearby.LocalLeaderboardSnapshotCodec

class DirectLeaderboardConnectionManager(
    context: Context,
    private val port: Int = DEFAULT_PORT,
) : DirectLeaderboardConnectionController {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val connectivityManager =
        context.applicationContext.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val socketLock = Any()

    private val _sessionState = MutableStateFlow(DirectSessionState())
    override val sessionState: StateFlow<DirectSessionState> = _sessionState.asStateFlow()

    private val _receivedSnapshot = MutableStateFlow<LocalLeaderboardSnapshot?>(null)
    override val receivedSnapshot: StateFlow<LocalLeaderboardSnapshot?> = _receivedSnapshot.asStateFlow()

    private var activeRole: DirectSessionRole = DirectSessionRole.NONE
    private var localEndpointName: String? = null
    private var latestHostedSnapshot: LocalLeaderboardSnapshot? = null

    private var serverSocket: ServerSocket? = null
    private var connectedSocket: Socket? = null
    private var connectedWriter: BufferedWriter? = null
    private var socketReader: BufferedReader? = null
    private var hostAcceptJob: Job? = null
    private var readJob: Job? = null

    override fun startHosting(localEndpointName: String) {
        this.localEndpointName = localEndpointName
        latestHostedSnapshot = null
        activeRole = DirectSessionRole.HOST
        _sessionState.value = DirectSessionState(
            role = DirectSessionRole.HOST,
            phase = DirectSessionPhase.HOSTING,
            localEndpointName = localEndpointName,
        )

        stopHostAcceptLoop()
        closeServerSocket()
        closeConnectedSocket()

        hostAcceptJob = scope.launch {
            try {
                val hostServerSocket = ServerSocket().apply {
                    reuseAddress = true
                    bind(InetSocketAddress(port))
                }
                synchronized(socketLock) {
                    serverSocket = hostServerSocket
                }
                while (isActive && activeRole == DirectSessionRole.HOST) {
                    val clientSocket = hostServerSocket.accept()
                    handleHostClientConnected(clientSocket)
                }
            } catch (error: IOException) {
                if (activeRole == DirectSessionRole.HOST) {
                    publishError(DirectSessionRole.HOST, error.message ?: "Direct host failed")
                }
            }
        }
    }

    override fun stopHosting() {
        activeRole = DirectSessionRole.NONE
        stopHostAcceptLoop()
        closeServerSocket()
        closeConnectedSocket()
        _sessionState.value = DirectSessionState()
    }

    override fun connectViaUsbTether(localEndpointName: String) {
        this.localEndpointName = localEndpointName
        activeRole = DirectSessionRole.CLIENT
        closeConnectedSocket()
        _sessionState.value = DirectSessionState(
            role = DirectSessionRole.CLIENT,
            phase = DirectSessionPhase.CONNECTING,
            localEndpointName = localEndpointName,
        )

        scope.launch {
            val candidates = resolveDirectHostCandidates()
            var lastErrorMessage: String? = null
            for (hostAddress in candidates) {
                try {
                    val socket = Socket()
                    socket.connect(InetSocketAddress(hostAddress, port), CONNECT_TIMEOUT_MS)
                    handleClientConnected(socket, hostAddress)
                    return@launch
                } catch (error: IOException) {
                    lastErrorMessage = error.message ?: "Failed to connect to $hostAddress"
                }
            }
            publishError(
                DirectSessionRole.CLIENT,
                lastErrorMessage ?: "Unable to find reachable USB tether host",
            )
        }
    }

    override fun disconnect() {
        closeConnectedSocket()
        _sessionState.value = when (activeRole) {
            DirectSessionRole.CLIENT -> _sessionState.value.copy(
                role = DirectSessionRole.CLIENT,
                phase = DirectSessionPhase.DISCONNECTED,
                connectedHostAddress = null,
                errorMessage = null,
            )

            DirectSessionRole.HOST -> _sessionState.value.copy(
                role = DirectSessionRole.HOST,
                phase = DirectSessionPhase.HOSTING,
                connectedHostAddress = null,
                errorMessage = null,
            )

            DirectSessionRole.NONE -> DirectSessionState()
        }
    }

    override fun useDatabaseMode() {
        activeRole = DirectSessionRole.NONE
        stopHostAcceptLoop()
        closeServerSocket()
        closeConnectedSocket()
        _receivedSnapshot.value = null
        _sessionState.value = DirectSessionState()
    }

    override fun publishHostedSnapshot(snapshot: LocalLeaderboardSnapshot) {
        val hostName = _sessionState.value.localEndpointName ?: snapshot.hostDisplayName
        val hostedSnapshot = snapshot.copy(hostDisplayName = hostName)
        latestHostedSnapshot = hostedSnapshot
        if (activeRole != DirectSessionRole.HOST) {
            return
        }
        sendSnapshot(hostedSnapshot)
    }

    private fun handleHostClientConnected(clientSocket: Socket) {
        closeConnectedSocket()
        synchronized(socketLock) {
            connectedSocket = clientSocket
            connectedWriter = clientSocket.getOutputStream().bufferedWriter(StandardCharsets.UTF_8)
            socketReader = clientSocket.getInputStream().bufferedReader(StandardCharsets.UTF_8)
        }

        _sessionState.value = _sessionState.value.copy(
            role = DirectSessionRole.HOST,
            phase = DirectSessionPhase.CONNECTED,
            connectedHostAddress = clientSocket.inetAddress?.hostAddress,
            errorMessage = null,
        )
        latestHostedSnapshot?.let(::sendSnapshot)
        startReadLoop()
    }

    private fun handleClientConnected(socket: Socket, hostAddress: String) {
        closeConnectedSocket()
        synchronized(socketLock) {
            connectedSocket = socket
            connectedWriter = socket.getOutputStream().bufferedWriter(StandardCharsets.UTF_8)
            socketReader = socket.getInputStream().bufferedReader(StandardCharsets.UTF_8)
        }

        _sessionState.value = _sessionState.value.copy(
            role = DirectSessionRole.CLIENT,
            phase = DirectSessionPhase.CONNECTED,
            connectedHostAddress = hostAddress,
            errorMessage = null,
        )
        startReadLoop()
    }

    private fun startReadLoop() {
        readJob?.cancel()
        readJob = scope.launch {
            val reader = synchronized(socketLock) { socketReader } ?: return@launch
            try {
                while (isActive && activeRole != DirectSessionRole.NONE) {
                    val line = reader.readLine() ?: break
                    if (activeRole == DirectSessionRole.CLIENT) {
                        handleSnapshotMessage(line)
                    }
                }
            } catch (error: IOException) {
                if (activeRole == DirectSessionRole.CLIENT) {
                    publishError(DirectSessionRole.CLIENT, error.message ?: "Direct read failed")
                } else {
                    Log.w(TAG, "Direct host read loop ended: ${error.message}")
                }
            } finally {
                if (activeRole == DirectSessionRole.CLIENT) {
                    _sessionState.value = _sessionState.value.copy(
                        role = DirectSessionRole.CLIENT,
                        phase = DirectSessionPhase.DISCONNECTED,
                        connectedHostAddress = null,
                        errorMessage = "Direct connection lost",
                    )
                } else if (activeRole == DirectSessionRole.HOST) {
                    _sessionState.value = _sessionState.value.copy(
                        role = DirectSessionRole.HOST,
                        phase = DirectSessionPhase.HOSTING,
                        connectedHostAddress = null,
                    )
                }
                closeConnectedSocket()
            }
        }
    }

    private fun handleSnapshotMessage(line: String) {
        val snapshot = LocalLeaderboardSnapshotCodec.decode(line.toByteArray(StandardCharsets.UTF_8))
            ?: run {
                publishError(DirectSessionRole.CLIENT, "Received invalid direct payload")
                return
            }
        _receivedSnapshot.value = snapshot
        _sessionState.value = _sessionState.value.copy(
            role = DirectSessionRole.CLIENT,
            phase = DirectSessionPhase.CONNECTED,
            lastDirectUpdateEpochMillis = System.currentTimeMillis(),
            errorMessage = null,
        )
    }

    private fun sendSnapshot(snapshot: LocalLeaderboardSnapshot) {
        val writer = synchronized(socketLock) { connectedWriter } ?: return
        try {
            writer.write(String(LocalLeaderboardSnapshotCodec.encode(snapshot), StandardCharsets.UTF_8))
            writer.write("\n")
            writer.flush()
        } catch (error: IOException) {
            publishError(DirectSessionRole.HOST, error.message ?: "Failed to send direct payload")
        }
    }

    private fun resolveDirectHostCandidates(): List<String> {
        val candidates = linkedSetOf<String>()
        fun collectDefaultGateway(properties: LinkProperties?) {
            properties
                ?.routes
                ?.firstOrNull { route -> route.isDefaultRoute }
                ?.gateway
                ?.hostAddress
                ?.takeIf { address -> address.isNotBlank() }
                ?.let(candidates::add)
        }

        connectivityManager.allNetworks.forEach { network ->
            val properties = connectivityManager.getLinkProperties(network)
            val interfaceName = properties?.interfaceName.orEmpty()
            if (interfaceName.contains("rndis", ignoreCase = true) ||
                interfaceName.contains("usb", ignoreCase = true)
            ) {
                collectDefaultGateway(properties)
            }
        }

        collectDefaultGateway(connectivityManager.getLinkProperties(connectivityManager.activeNetwork))

        DIRECT_HOST_FALLBACKS.forEach(candidates::add)
        return candidates.toList()
    }

    private fun publishError(role: DirectSessionRole, message: String) {
        Log.e(TAG, message)
        _sessionState.value = _sessionState.value.copy(
            role = role,
            phase = DirectSessionPhase.ERROR,
            errorMessage = message,
        )
    }

    private fun stopHostAcceptLoop() {
        hostAcceptJob?.cancel()
        hostAcceptJob = null
    }

    private fun closeServerSocket() {
        synchronized(socketLock) {
            serverSocket?.closeQuietly()
            serverSocket = null
        }
    }

    private fun closeConnectedSocket() {
        readJob?.cancel()
        readJob = null
        synchronized(socketLock) {
            socketReader?.closeQuietly()
            socketReader = null
            connectedWriter?.closeQuietly()
            connectedWriter = null
            connectedSocket?.closeQuietly()
            connectedSocket = null
        }
    }

    private fun AutoCloseable.closeQuietly() {
        try {
            close()
        } catch (_: Exception) {
            // ignore close failures
        }
    }

    companion object {
        private const val TAG = "DirectLeaderboardConn"
        private const val DEFAULT_PORT = 43871
        private const val CONNECT_TIMEOUT_MS = 1500
        private val DIRECT_HOST_FALLBACKS = listOf(
            "192.168.42.129",
            "192.168.42.1",
            "192.168.43.1",
            "192.168.44.1",
        )
    }
}
