import AppKit
import Carbon.HIToolbox

@Observable
final class CleaningModeManager {
    var isEnabled = false
    private var cleaningWindows: [NSWindow] = []
    private var eventMonitor: Any?
    private var commandPressCount = 0
    private var lastCommandPressTime: Date = .distantPast

    func toggle() {
        if isEnabled {
            disableCleaningMode()
        } else {
            enableCleaningMode()
        }
    }

    private func enableCleaningMode() {
        isEnabled = true
        commandPressCount = 0

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.level = .screenSaver
            window.backgroundColor = .black
            window.isOpaque = true
            window.ignoresMouseEvents = false
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            let label = NSTextField(labelWithString: "Screen Cleaning Mode\n\nPress ⌘ Command key 6 times to exit")
            label.font = NSFont.systemFont(ofSize: 16, weight: .medium)
            label.textColor = NSColor.white.withAlphaComponent(0.5)
            label.alignment = .center
            label.maximumNumberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false

            let contentView = NSView(frame: screen.frame)
            contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                label.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            ])

            window.contentView = contentView
            window.makeKeyAndOrderFront(nil)
            cleaningWindows.append(window)
        }

        eventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged, .leftMouseDown, .rightMouseDown, .scrollWheel, .mouseMoved]
        ) { [weak self] event in
            guard let self else { return nil }

            if event.type == .flagsChanged {
                self.handleFlagsChanged(event)
            }

            return nil
        }
    }

    private func disableCleaningMode() {
        isEnabled = false

        for window in cleaningWindows {
            window.orderOut(nil)
        }
        cleaningWindows.removeAll()

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }

        commandPressCount = 0
    }

    private func handleFlagsChanged(_ event: NSEvent) {
        let commandPressed = event.modifierFlags.contains(.command)

        if commandPressed {
            let now = Date()
            if now.timeIntervalSince(lastCommandPressTime) > 2.0 {
                commandPressCount = 0
            }
            commandPressCount += 1
            lastCommandPressTime = now

            if commandPressCount >= 6 {
                disableCleaningMode()
            }
        }
    }
}
