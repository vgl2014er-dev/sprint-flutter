package sprint.app.startup

enum class BluetoothPermissionState {
    GRANTED,
    REQUIRED,
    DENIED,
}

sealed interface SpeakerStartupState {
    data object Checking : SpeakerStartupState
    data object Connected : SpeakerStartupState
    data object PermissionRequired : SpeakerStartupState
    data object PermissionDenied : SpeakerStartupState
    data object BluetoothOff : SpeakerStartupState
    data object SpeakerNotConnected : SpeakerStartupState
    data object SpeakerNotPaired : SpeakerStartupState
}

