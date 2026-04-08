import AppKit
import Foundation

@Observable
final class FinderUtilsManager {
    static let shared = FinderUtilsManager()

    var hiddenFilesVisible = false

    init() {
        hiddenFilesVisible = readHiddenFilesState()
    }

    // MARK: - Toggle Hidden Files

    func toggleHiddenFiles() {
        hiddenFilesVisible.toggle()
        let value = hiddenFilesVisible ? "TRUE" : "FALSE"
        let write = Process()
        write.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        write.arguments = ["write", "com.apple.finder", "AppleShowAllFiles", "-bool", value]
        try? write.run()
        write.waitUntilExit()

        let restart = Process()
        restart.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        restart.arguments = ["Finder"]
        try? restart.run()
    }

    private func readHiddenFilesState() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        process.arguments = ["read", "com.apple.finder", "AppleShowAllFiles"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return output == "1" || output.lowercased() == "true"
    }

    // MARK: - Open in Terminal

    func openInTerminal() {
        let script = """
        tell application "Finder"
            if (count of windows) > 0 then
                set currentFolder to POSIX path of (target of front window as alias)
            else
                set currentFolder to POSIX path of (path to desktop)
            end if
        end tell
        return currentFolder
        """

        guard let path = runAppleScript(script) else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", path]
        try? process.run()
    }

    // MARK: - Copy Path

    func copyPath() {
        let script = """
        tell application "Finder"
            set theSelection to selection
            if (count of theSelection) > 0 then
                set pathList to {}
                repeat with anItem in theSelection
                    set end of pathList to POSIX path of (anItem as alias)
                end repeat
                set AppleScript's text item delimiters to linefeed
                return pathList as text
            else if (count of windows) > 0 then
                return POSIX path of (target of front window as alias)
            else
                return POSIX path of (path to desktop)
            end if
        end tell
        """

        guard let paths = runAppleScript(script), !paths.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths, forType: .string)
    }

    // MARK: - New Text File

    func newTextFile() {
        let script = """
        tell application "Finder"
            if (count of windows) > 0 then
                return POSIX path of (target of front window as alias)
            else
                return POSIX path of (path to desktop)
            end if
        end tell
        """

        guard let folder = runAppleScript(script) else { return }

        let baseName = "Untitled"
        let ext = "txt"
        var fileName = "\(baseName).\(ext)"
        var counter = 2

        while FileManager.default.fileExists(atPath: (folder as NSString).appendingPathComponent(fileName)) {
            fileName = "\(baseName) \(counter).\(ext)"
            counter += 1
        }

        let fullPath = (folder as NSString).appendingPathComponent(fileName)
        FileManager.default.createFile(atPath: fullPath, contents: nil)

        // Reveal in Finder
        NSWorkspace.shared.selectFile(fullPath, inFileViewerRootedAtPath: folder)
    }

    // MARK: - Helpers

    private func runAppleScript(_ source: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
