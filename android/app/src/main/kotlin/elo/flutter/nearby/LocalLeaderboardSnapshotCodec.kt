package elo.flutter.nearby

import org.json.JSONArray
import org.json.JSONObject
import elo.flutter.domain.Player

object LocalLeaderboardSnapshotCodec {

    fun encode(snapshot: LocalLeaderboardSnapshot): ByteArray {
        val root = JSONObject().apply {
            put("hostDisplayName", snapshot.hostDisplayName)
            put("generatedAtEpochMillis", snapshot.generatedAtEpochMillis)
            put("kFactor", snapshot.kFactor)
            put("lastSyncedEpochMillis", snapshot.lastSyncedEpochMillis)
            put("players", JSONArray().apply {
                snapshot.players.forEach { player ->
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
            })
        }
        return root.toString().toByteArray(Charsets.UTF_8)
    }

    fun decode(payloadBytes: ByteArray): LocalLeaderboardSnapshot? {
        return try {
            val root = JSONObject(payloadBytes.toString(Charsets.UTF_8))
            val playersArray = root.optJSONArray("players") ?: return null
            LocalLeaderboardSnapshot(
                hostDisplayName = root.optString("hostDisplayName").takeIf { it.isNotBlank() } ?: return null,
                generatedAtEpochMillis = root.optLong("generatedAtEpochMillis"),
                kFactor = root.optInt("kFactor"),
                lastSyncedEpochMillis = root.opt("lastSyncedEpochMillis")?.let {
                    when (it) {
                        is Number -> it.toLong()
                        is String -> it.toLongOrNull()
                        else -> null
                    }
                },
                players = playersArray.toPlayers(),
            )
        } catch (_: Exception) {
            null
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
