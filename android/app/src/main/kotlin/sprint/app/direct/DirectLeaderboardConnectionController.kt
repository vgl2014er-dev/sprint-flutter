package sprint.app.direct

import kotlinx.coroutines.flow.StateFlow
import sprint.app.nearby.LocalLeaderboardSnapshot

interface DirectLeaderboardConnectionController {
    val sessionState: StateFlow<DirectSessionState>
    val receivedSnapshot: StateFlow<LocalLeaderboardSnapshot?>

    fun startHosting(localEndpointName: String)
    fun stopHosting()
    fun connectViaUsbTether(localEndpointName: String)
    fun disconnect()
    fun useDatabaseMode()
    fun publishHostedSnapshot(snapshot: LocalLeaderboardSnapshot)
}
