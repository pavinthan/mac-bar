import Cocoa
import CoreGraphics

@Observable
final class LockdownModeManager {
    static let shared = LockdownModeManager()

    var isActive = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var commandPressCount = 0
    private var lastCommandPressTime: Date?

    private static let requiredCommandPresses = 6
    private static let commandPressWindow: TimeInterval = 3.0

    func toggle() {
        if isActive {
            deactivate()
        } else {
            activate()
        }
    }

    func activate() {
        guard !isActive else { return }

        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue) |
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue)

        // Store self pointer for the C callback
        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<LockdownModeManager>.fromOpaque(userInfo).takeUnretainedValue()
                return manager.handleEvent(type: type, event: event)
            },
            userInfo: selfPtr
        ) else {
            Unmanaged<LockdownModeManager>.fromOpaque(selfPtr).release()
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        commandPressCount = 0
        lastCommandPressTime = nil
        isActive = true
    }

    func deactivate() {
        guard isActive else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        // Release the retained self from activate()
        if eventTap != nil {
            Unmanaged.passUnretained(self).release()
        }

        eventTap = nil
        runLoopSource = nil
        isActive = false
        commandPressCount = 0
        lastCommandPressTime = nil
    }

    // MARK: - Event handling

    private func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Allow flagsChanged through so we can detect Command key presses
        if type == .flagsChanged {
            let flags = event.flags
            let isCommandDown = flags.contains(.maskCommand)

            if isCommandDown {
                let now = Date()
                if let last = lastCommandPressTime, now.timeIntervalSince(last) > Self.commandPressWindow {
                    commandPressCount = 0
                }
                commandPressCount += 1
                lastCommandPressTime = now

                if commandPressCount >= Self.requiredCommandPresses {
                    DispatchQueue.main.async {
                        self.deactivate()
                    }
                }
            }

            // Block the flags event too (don't pass through)
            return nil
        }

        // Block all other events
        return nil
    }
}
