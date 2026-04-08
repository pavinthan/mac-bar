import AppKit
import CoreGraphics

struct ActionContext {
    let text: String
    let params: [String: String]
}

protocol ActionExecutor {
    var actionName: String { get }
    func execute(context: ActionContext) async throws
}

final class ActionRegistry {
    private var executors: [String: ActionExecutor] = [:]

    func register(_ executor: ActionExecutor) {
        executors[executor.actionName] = executor
    }

    func execute(action: String, context: ActionContext) async throws {
        guard let executor = executors[action] else {
            return
        }
        try await executor.execute(context: context)
    }
}

// MARK: - Dictate

final class DictateAction: ActionExecutor {
    let actionName = "dictate"
    private let keySimulator: KeySimulator

    init(keySimulator: KeySimulator) {
        self.keySimulator = keySimulator
    }

    func execute(context: ActionContext) async throws {
        let text = context.text
        if text.count < 50 {
            keySimulator.typeText(text)
        } else {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)
            keySimulator.simulatePaste()
        }
    }
}

// MARK: - Copy

final class CopyAction: ActionExecutor {
    let actionName = "copy"
    private let keySimulator = KeySimulator()

    func execute(context: ActionContext) async throws {
        let pasteboard = NSPasteboard.general
        let initialChangeCount = pasteboard.changeCount

        keySimulator.simulateCopy()
        try await Task.sleep(nanoseconds: 100_000_000)

        if pasteboard.changeCount == initialChangeCount {
            keySimulator.simulateKeystroke(keyCode: 0, flags: .maskCommand)
            try await Task.sleep(nanoseconds: 80_000_000)
            keySimulator.simulateCopy()
        }
    }
}

// MARK: - Paste

final class PasteTextAction: ActionExecutor {
    let actionName = "paste"
    private let keySimulator = KeySimulator()

    func execute(context: ActionContext) async throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(context.text, forType: .string)
        keySimulator.simulatePaste()
    }
}

// MARK: - Switch App

final class SwitchAppAction: ActionExecutor {
    let actionName = "switch_to"

    func execute(context: ActionContext) async throws {
        let targetName = context.params["app"] ?? context.text
        let normalizedTarget = normalizedAppQuery(targetName)
        let workspace = NSWorkspace.shared

        let matchingApp = workspace.runningApplications.first { app in
            guard let name = app.localizedName else { return false }
            let normalizedName = name.lowercased().filter { $0.isLetter || $0.isNumber }
            let bundleID = app.bundleIdentifier?.lowercased() ?? ""
            return normalizedName == normalizedTarget
                || normalizedName.contains(normalizedTarget)
                || bundleID.contains(normalizedTarget)
        }

        if let app = matchingApp {
            app.activate(options: [.activateAllWindows])
        } else if let url = tryOpenInstalledApp(matching: normalizedTarget, workspace: workspace) {
            try await workspace.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else if let url = workspace.urlForApplication(withBundleIdentifier: targetName) {
            try await workspace.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    private func normalizedAppQuery(_ raw: String) -> String {
        let lowered = raw.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "switch to ", with: "")
            .replacingOccurrences(of: "go to ", with: "")
            .replacingOccurrences(of: "open ", with: "")
        return lowered
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty && $0 != "my" && $0 != "the" && $0 != "app" }
            .joined()
    }

    private func tryOpenInstalledApp(matching target: String, workspace: NSWorkspace) -> URL? {
        let roots = ["/Applications", NSHomeDirectory() + "/Applications"]
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(atPath: root) else { continue }
            for case let entry as String in enumerator {
                guard entry.hasSuffix(".app") else { continue }
                let name = URL(fileURLWithPath: entry).deletingPathExtension().lastPathComponent
                let normalized = name.lowercased().filter { $0.isLetter || $0.isNumber }
                if normalized == target || normalized.contains(target) {
                    return URL(fileURLWithPath: root).appendingPathComponent(entry)
                }
            }
        }
        return nil
    }
}

// MARK: - Switch Tab

final class SwitchTabAction: ActionExecutor {
    let actionName = "switch_tab"
    private let keySimulator: KeySimulator

    init(keySimulator: KeySimulator) {
        self.keySimulator = keySimulator
    }

    func execute(context: ActionContext) async throws {
        guard let raw = context.params["index"] ?? context.params["tab"],
              let number = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              (1...9).contains(number) else {
            return
        }

        let keyCodeMap: [Int: CGKeyCode] = [
            1: 18, 2: 19, 3: 20, 4: 21, 5: 23, 6: 22, 7: 26, 8: 28, 9: 25
        ]

        guard let keyCode = keyCodeMap[number] else { return }
        keySimulator.simulateKeystroke(keyCode: keyCode, flags: .maskCommand)
    }
}
