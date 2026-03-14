package elo.flutter.nearby

import org.json.JSONArray
import org.json.JSONObject
import elo.flutter.domain.Player

object LocalLeaderboardSnapshotCodec {

    fun encodeSnapshot(snapshot: LocalLeaderboardSnapshot): ByteArray {
        val root = JSONObject().apply {
            put("type", "snapshot")
            put("snapshot", snapshot.toJson())
        }
        return root.toString().toByteArray(Charsets.UTF_8)
    }

    fun encodeControl(control: LocalControlMessage): ByteArray {
        val root = JSONObject().apply {
            put("type", "control")
            put(
                "action",
                when (control) {
                    LocalControlMessage.START_MATCH_BEEP -> "start_match_beep"
                },
            )
        }
        return root.toString().toByteArray(Charsets.UTF_8)
    }

    fun decode(payloadBytes: ByteArray): LocalNearbyPayload? {
        return try {
            val root = JSONObject(payloadBytes.toString(Charsets.UTF_8))
            when (root.optString("type")) {
                "control" -> root.optString("action")
                    .toControlMessage()
                    ?.let { LocalNearbyPayload.Control(it) }

                "snapshot" -> root.optJSONObject("snapshot")
                    ?.toSnapshot()
                    ?.let { LocalNearbyPayload.Snapshot(it) }

                else -> root.toSnapshot()?.let { LocalNearbyPayload.Snapshot(it) }
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun JSONObject.toSnapshot(): LocalLeaderboardSnapshot? {
        val playersArray = optJSONArray("players") ?: return null
        return LocalLeaderboardSnapshot(
            hostDisplayName = optString("hostDisplayName").takeIf { it.isNotBlank() } ?: return null,
            generatedAtEpochMillis = optLong("generatedAtEpochMillis"),
            kFactor = optInt("kFactor"),
            lastSyncedEpochMillis = opt("lastSyncedEpochMillis")?.let {
                when (it) {
                    is Number -> it.toLong()
                    is String -> it.toLongOrNull()
                    else -> null
                }
            },
            players = playersArray.toPlayers(),
        )
    }

    private fun LocalLeaderboardSnapshot.toJson(): JSONObject {
        return JSONObject().apply {
            put("hostDisplayName", hostDisplayName)
            put("generatedAtEpochMillis", generatedAtEpochMillis)
            put("kFactor", kFactor)
            put("lastSyncedEpochMillis", lastSyncedEpochMillis)
            put(
                "players",
                JSONArray().apply {
                    players.forEach { player ->
                        put(
                            JSONObject().apply {
                                put("id", player.id)
                                put("name", player.name)
                                put("elo", player.elo)
                                put("wins", player.wins)
                                put("losses", player.losses)
                                put("draws", player.draws)
                                put("matchesPlayed", player.matchesPlayed)
                            },
                        )
                    }
                },
            )
        }
    }

    private fun String?.toControlMessage(): LocalControlMessage? {
        return when (this) {
            "start_match_beep" -> LocalControlMessage.START_MATCH_BEEP
            else -> null
        }
    }

    private fun JSONArray.toPlayers(): List<Player> {
        val players = ArrayList<Player>(length())
        for (index in 0 until length()) {
            val item = optJSONObject(index) ?: continue
            players += Player(
                id = item.optString("id"),
                name = item.optString("name"),
                elo = item.optInt("elo"),
                wins = item.optInt("wins"),
                losses = item.optInt("losses"),
                draws = item.optInt("draws"),
                matchesPlayed = item.optInt("matchesPlayed"),
            )
        }
        return players
    }
}

sealed interface LocalNearbyPayload {
    data class Snapshot(val snapshot: LocalLeaderboardSnapshot) : LocalNearbyPayload
    data class Control(val control: LocalControlMessage) : LocalNearbyPayload
}
