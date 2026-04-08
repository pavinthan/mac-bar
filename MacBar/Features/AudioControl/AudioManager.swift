import CoreAudio
import Foundation

@Observable
final class AudioManager {
    static let shared = AudioManager()

    var isSoundMuted = false
    var isMicMuted = false

    private var savedMicVolume: Float32 = 1.0

    init() {
        refresh()
    }

    func refresh() {
        isSoundMuted = getOutputMuted()
        isMicMuted = getInputMuted()
    }

    private func getOutputMuted() -> Bool {
        let device = defaultOutputDevice
        // Check mute property first
        if getMute(for: device, scope: kAudioDevicePropertyScopeOutput) {
            // Verify via volume — some devices report mute=true while volume > 0
            let volume = getOutputVolume(for: device)
            if volume < 0.01 {
                return true
            }
            // Mute flag set but volume is audible — trust volume
            return false
        }
        // Mute not set — check if volume is essentially zero
        let volume = getOutputVolume(for: device)
        return volume < 0.01
    }

    func toggleSound() {
        isSoundMuted.toggle()
        setMute(isSoundMuted, for: defaultOutputDevice, scope: kAudioDevicePropertyScopeOutput)
    }

    func toggleMic() {
        let device = defaultInputDevice
        if isMicMuted {
            // Unmute: restore saved volume
            setInputVolume(savedMicVolume > 0 ? savedMicVolume : 1.0, for: device)
            setMute(false, for: device, scope: kAudioDevicePropertyScopeInput)
            isMicMuted = false
        } else {
            // Mute: save current volume, then mute
            savedMicVolume = getInputVolume(for: device)
            if savedMicVolume < 0.01 {
                savedMicVolume = 1.0
            }
            setMute(true, for: device, scope: kAudioDevicePropertyScopeInput)
            setInputVolume(0, for: device)
            isMicMuted = true
        }
    }

    // MARK: - CoreAudio helpers

    private var defaultOutputDevice: AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
    }

    private var defaultInputDevice: AudioDeviceID {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return deviceID
    }

    private func getInputMuted() -> Bool {
        let device = defaultInputDevice
        // Check mute property first
        if getMute(for: device, scope: kAudioDevicePropertyScopeInput) {
            return true
        }
        // Fall back to checking if volume is zero
        let volume = getInputVolume(for: device)
        return volume < 0.01
    }

    private func getMute(for device: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var mute: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &mute)
        if status != noErr {
            return false
        }
        return mute != 0
    }

    private func setMute(_ mute: Bool, for device: AudioDeviceID, scope: AudioObjectPropertyScope) {
        var value: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectSetPropertyData(device, &address, 0, nil, size, &value)
    }

    private func getOutputVolume(for device: AudioDeviceID) -> Float32 {
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
        if status != noErr {
            address.mElement = 1
            status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
        }
        if status != noErr {
            return 1.0
        }
        return volume
    }

    private func getInputVolume(for device: AudioDeviceID) -> Float32 {
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Try element 0 (master), then element 1 (channel 1)
        var status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
        if status != noErr {
            address.mElement = 1
            status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &volume)
        }
        if status != noErr {
            return 1.0
        }
        return volume
    }

    private func setInputVolume(_ volume: Float32, for device: AudioDeviceID) {
        var vol = volume
        let size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(device, &address, 0, nil, size, &vol)
        if status != noErr {
            address.mElement = 1
            AudioObjectSetPropertyData(device, &address, 0, nil, size, &vol)
        }
    }
}
