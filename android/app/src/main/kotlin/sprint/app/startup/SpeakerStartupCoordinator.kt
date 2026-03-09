package sprint.app.startup

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings

class SpeakerStartupCoordinator(
    private val targetSpeakerName: String = TARGET_SPEAKER_NAME,
    private val bluetoothSnapshotProvider: BluetoothSnapshotProvider,
) {

    fun evaluateStartupState(permissionState: BluetoothPermissionState): SpeakerStartupState {
        return when (permissionState) {
            BluetoothPermissionState.REQUIRED -> SpeakerStartupState.PermissionRequired
            BluetoothPermissionState.DENIED -> SpeakerStartupState.PermissionDenied
            BluetoothPermissionState.GRANTED -> evaluateBluetoothState()
        }
    }

    fun openBluetoothSettings(context: Context) {
        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    fun openAppSettings(context: Context) {
        val uri = Uri.fromParts("package", context.packageName, null)
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun evaluateBluetoothState(): SpeakerStartupState {
        if (!bluetoothSnapshotProvider.isBluetoothAvailable()) {
            return SpeakerStartupState.BluetoothOff
        }
        if (!bluetoothSnapshotProvider.isBluetoothEnabled()) {
            return SpeakerStartupState.BluetoothOff
        }

        val normalizedTarget = normalize(targetSpeakerName)
        val connectedNames = bluetoothSnapshotProvider.connectedA2dpDeviceNames()
        val connected = connectedNames.any { normalize(it) == normalizedTarget }
        if (connected) {
            return SpeakerStartupState.Connected
        }

        val bondedNames = bluetoothSnapshotProvider.bondedDeviceNames()
        val paired = bondedNames.any { normalize(it) == normalizedTarget }
        if (paired && bluetoothSnapshotProvider.isAnyBluetoothAudioConnected()) {
            return SpeakerStartupState.Connected
        }
        return if (paired) {
            SpeakerStartupState.SpeakerNotConnected
        } else {
            SpeakerStartupState.SpeakerNotPaired
        }
    }

    private fun normalize(value: String): String = value.trim().uppercase()

    companion object {
        const val TARGET_SPEAKER_NAME = "MEGABLAST"
    }
}
