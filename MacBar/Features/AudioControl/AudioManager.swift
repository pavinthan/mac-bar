import CoreAudio
import Foundation

@Observable
final class AudioManager {
    var isSoundMuted = false
    var isMicMuted = false

    init() {
        refresh()
    }

    func refresh() {
        isSoundMuted = getMute(for: defaultOutputDevice)
        isMicMuted = getMute(for: defaultInputDevice)
    }

    func toggleSound() {
        isSoundMuted.toggle()
        setMute(isSoundMuted, for: defaultOutputDevice)
    }

    func toggleMic() {
        isMicMuted.toggle()
        setMute(isMicMuted, for: defaultInputDevice)
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

    private func getMute(for device: AudioDeviceID) -> Bool {
        var mute: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // Check if this is an input device
        if device == defaultInputDevice {
            address.mScope = kAudioDevicePropertyScopeInput
        }

        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &mute)
        if status != noErr {
            return false
        }
        return mute != 0
    }

    private func setMute(_ mute: Bool, for device: AudioDeviceID) {
        var value: UInt32 = mute ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        if device == defaultInputDevice {
            address.mScope = kAudioDevicePropertyScopeInput
        }

        AudioObjectSetPropertyData(device, &address, 0, nil, size, &value)
    }
}
