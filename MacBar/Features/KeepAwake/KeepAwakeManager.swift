import Foundation

@Observable
final class KeepAwakeManager {
    var isActive = false
    private var process: Process?

    func toggle() {
        if isActive {
            deactivate()
        } else {
            activate()
        }
    }

    func activate() {
        guard !isActive else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        proc.arguments = ["-di"] // prevent display and idle sleep
        try? proc.run()
        process = proc
        isActive = true
    }

    func deactivate() {
        guard isActive else { return }
        process?.terminate()
        process = nil
        isActive = false
    }
}
