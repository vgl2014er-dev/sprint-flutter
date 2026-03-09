package sprint.app.direct

enum class DirectSessionRole {
    NONE,
    HOST,
    CLIENT,
}

enum class DirectSessionPhase {
    IDLE,
    HOSTING,
    CONNECTING,
    CONNECTED,
    DISCONNECTED,
    ERROR,
}

data class DirectSessionState(
    val role: DirectSessionRole = DirectSessionRole.NONE,
    val phase: DirectSessionPhase = DirectSessionPhase.IDLE,
    val localEndpointName: String? = null,
    val connectedHostAddress: String? = null,
    val lastDirectUpdateEpochMillis: Long? = null,
    val errorMessage: String? = null,
)
