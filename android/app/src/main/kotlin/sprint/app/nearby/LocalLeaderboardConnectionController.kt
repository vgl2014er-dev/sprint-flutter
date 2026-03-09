package sprint.app.nearby

import kotlinx.coroutines.flow.StateFlow

interface LocalLeaderboardConnectionController {
    val sessionState: StateFlow<LocalSessionState>
    val receivedSnapshot: StateFlow<LocalLeaderboardSnapshot?>

    fun startHosting(localEndpointName: String)
    fun stopHosting()
    fun startDiscovery(localEndpointName: String)
    fun connectToHost(endpointId: String)
    fun acceptPendingConnection()
    fun rejectPendingConnection()
    fun disconnect()
    fun useDatabaseMode()
    fun publishHostedSnapshot(snapshot: LocalLeaderboardSnapshot)
}
