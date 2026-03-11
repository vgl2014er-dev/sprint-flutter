package elo.flutter.domain

data class Player(
    val id: String,
    val name: String,
    val elo: Int,
    val wins: Int,
    val losses: Int,
    val draws: Int,
    val matchesPlayed: Int,
)
