import Cocoa

enum HotkeyEvent {
    case keyDown
    case keyUp
}

final class VoiceHotkeyManager {
    private let callback: (HotkeyEvent) -> Void
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isPressed = false

    private static let rightOptionKeyCode: UInt16 = 61

    init(callback: @escaping (HotkeyEvent) -> Void) {
        self.callback = callback
    }

    func start() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.globalMonitor == nil, self.localMonitor == nil else { return }

            self.globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event)
            }
            self.localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
                self?.handleFlagsChanged(event)
                return event
            }
        }
    }

    func stop() {
        DispatchQueue.main.async {
            if let globalMonitor = self.globalMonitor {
                NSEvent.removeMonitor(globalMonitor)
            }
            if let localMonitor = self.localMonitor {
                NSEvent.removeMonitor(localMonitor)
            }

            self.globalMonitor = nil
            self.localMonitor = nil
            self.isPressed = false
        }
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let keyCode = UInt16(event.keyCode)
        let optionPressed = event.modifierFlags.contains(.option)

        if keyCode == VoiceHotkeyManager.rightOptionKeyCode && optionPressed && !isPressed {
            isPressed = true
            callback(.keyDown)
        } else if !optionPressed && isPressed {
            isPressed = false
            callback(.keyUp)
        }
    }
}
