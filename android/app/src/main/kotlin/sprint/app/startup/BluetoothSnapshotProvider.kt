package sprint.app.startup

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager

interface BluetoothSnapshotProvider {
    fun isBluetoothAvailable(): Boolean
    fun isBluetoothEnabled(): Boolean
    fun connectedA2dpDeviceNames(): List<String>
    fun bondedDeviceNames(): List<String>
    fun isAnyBluetoothAudioConnected(): Boolean
}

class AndroidBluetoothSnapshotProvider(
    context: Context,
) : BluetoothSnapshotProvider {
    private val bluetoothManager: BluetoothManager? =
        context.getSystemService(BluetoothManager::class.java)
    private val audioManager: AudioManager? =
        context.getSystemService(AudioManager::class.java)
    private val adapter: BluetoothAdapter?
        get() = bluetoothManager?.adapter

    override fun isBluetoothAvailable(): Boolean = adapter != null

    override fun isBluetoothEnabled(): Boolean = adapter?.isEnabled == true

    @SuppressLint("MissingPermission")
    override fun connectedA2dpDeviceNames(): List<String> {
        val directNames = try {
            bluetoothManager
                ?.getConnectedDevices(BluetoothProfile.A2DP)
                .orEmpty()
                .mapNotNull { it.name }
        } catch (_: SecurityException) {
            emptyList()
        } catch (_: IllegalArgumentException) {
            // Some Android builds do not support querying A2DP via BluetoothManager.
            emptyList()
        }
        if (directNames.isNotEmpty()) {
            return directNames
        }
        return connectedAudioDeviceNamesFallback()
    }

    @SuppressLint("MissingPermission")
    override fun bondedDeviceNames(): List<String> {
        return try {
            adapter
                ?.bondedDevices
                .orEmpty()
                .mapNotNull { it.name }
        } catch (_: SecurityException) {
            emptyList()
        }
    }

    override fun isAnyBluetoothAudioConnected(): Boolean {
        val hasConnectedA2dpState = try {
            adapter?.getProfileConnectionState(BluetoothProfile.A2DP) == BluetoothAdapter.STATE_CONNECTED
        } catch (_: SecurityException) {
            false
        } catch (_: IllegalArgumentException) {
            false
        }
        return hasConnectedA2dpState || connectedAudioDeviceNamesFallback().isNotEmpty()
    }

    @SuppressLint("MissingPermission")
    private fun connectedAudioDeviceNamesFallback(): List<String> {
        val bluetoothOutputTypes = setOf(
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_BLE_HEADSET,
            AudioDeviceInfo.TYPE_BLE_SPEAKER,
        )

        val bondedByAddress = try {
            adapter
                ?.bondedDevices
                .orEmpty()
                .associate { device ->
                    device.address.trim().uppercase() to device.name.orEmpty().trim()
                }
        } catch (_: SecurityException) {
            emptyMap()
        }

        return audioManager
            ?.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            .orEmpty()
            .asSequence()
            .filter { it.type in bluetoothOutputTypes }
            .mapNotNull { deviceInfo ->
                val normalizedAddress = deviceInfo.address.orEmpty().trim().uppercase()
                val bondedName = bondedByAddress[normalizedAddress].orEmpty()
                val productName = deviceInfo.productName?.toString().orEmpty().trim()
                when {
                    bondedName.isNotEmpty() -> bondedName
                    productName.isNotEmpty() -> productName
                    else -> null
                }
            }
            .distinct()
            .toList()
    }
}
