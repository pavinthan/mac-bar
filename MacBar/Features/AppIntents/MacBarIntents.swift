import AppIntents

// MARK: - Toggle Sound Mute

struct ToggleSoundMuteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Sound Mute"
    static var description = IntentDescription("Toggles the system sound mute state.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AudioManager.shared.toggleSound()
        }
        return .result()
    }
}

// MARK: - Toggle Mic Mute

struct ToggleMicMuteIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Microphone Mute"
    static var description = IntentDescription("Toggles the microphone mute state.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            AudioManager.shared.toggleMic()
        }
        return .result()
    }
}

// MARK: - Toggle Cleaning Mode

struct ToggleCleaningModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Cleaning Mode"
    static var description = IntentDescription("Toggles cleaning mode which blacks out the screen.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            CleaningModeManager.shared.toggle()
        }
        return .result()
    }
}

// MARK: - Toggle Lockdown Mode

struct ToggleLockdownModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Lockdown Mode"
    static var description = IntentDescription("Toggles lockdown mode which blocks keyboard and mouse input.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            LockdownModeManager.shared.toggle()
        }
        return .result()
    }
}

// MARK: - Toggle Hidden Files

struct ToggleHiddenFilesIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Hidden Files"
    static var description = IntentDescription("Shows or hides hidden files in Finder.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            FinderUtilsManager.shared.toggleHiddenFiles()
        }
        return .result()
    }
}

// MARK: - Open Terminal

struct OpenTerminalIntent: AppIntent {
    static var title: LocalizedStringResource = "Open in Terminal"
    static var description = IntentDescription("Opens the current Finder folder in Terminal.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            FinderUtilsManager.shared.openInTerminal()
        }
        return .result()
    }
}

// MARK: - Copy Finder Path

struct CopyFinderPathIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Finder Path"
    static var description = IntentDescription("Copies the selected Finder item path to clipboard.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            FinderUtilsManager.shared.copyPath()
        }
        return .result()
    }
}

// MARK: - Shortcuts Provider

struct MacBarShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ToggleSoundMuteIntent(), phrases: [
            "Toggle sound mute in \(.applicationName)",
            "Mute sound with \(.applicationName)"
        ], shortTitle: "Toggle Sound", systemImageName: "speaker.slash")

        AppShortcut(intent: ToggleMicMuteIntent(), phrases: [
            "Toggle microphone in \(.applicationName)",
            "Mute mic with \(.applicationName)"
        ], shortTitle: "Toggle Mic", systemImageName: "mic.slash")

        AppShortcut(intent: ToggleCleaningModeIntent(), phrases: [
            "Start cleaning mode in \(.applicationName)"
        ], shortTitle: "Cleaning Mode", systemImageName: "sparkles")

        AppShortcut(intent: ToggleLockdownModeIntent(), phrases: [
            "Lock keyboard in \(.applicationName)",
            "Start lockdown with \(.applicationName)"
        ], shortTitle: "Lockdown Mode", systemImageName: "lock.fill")

        AppShortcut(intent: ToggleHiddenFilesIntent(), phrases: [
            "Toggle hidden files with \(.applicationName)"
        ], shortTitle: "Hidden Files", systemImageName: "eye")
    }
}
