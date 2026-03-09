package sprint.app.nearby

import sprint.app.domain.Player

enum class LocalSessionRole {
    NONE,
    HOST,
    CLIENT,
}

enum class LocalSessionPhase {
    IDLE,
    ADVERTISING,
    DISCOVERING,
    CONNECTING,
    AWAITING_APPROVAL,
    CONNECTED,
    DISCONNECTED,
    ERROR,
}

data class DiscoveredHost(
    val endpointId: String,
    val displayName: String,
)

data class LocalSessionState(
    val role: LocalSessionRole = LocalSessionRole.NONE,
    val phase: LocalSessionPhase = LocalSessionPhase.IDLE,
    val discoveredHosts: List<DiscoveredHost> = emptyList(),
    val pendingConnectionName: String? = null,
    val connectedHostName: String? = null,
    val localEndpointName: String? = null,
    val authToken: String? = null,
    val lastLocalUpdateEpochMillis: Long? = null,
    val errorMessage: String? = null,
)

data class LocalLeaderboardSnapshot(
    val hostDisplayName: String,
    val generatedAtEpochMillis: Long,
    val kFactor: Int,
    val lastSyncedEpochMillis: Long?,
    val players: List<Player>,
)
