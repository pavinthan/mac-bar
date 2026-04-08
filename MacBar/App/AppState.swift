import Foundation
import SwiftUI
import ServiceManagement

enum ColorFormat: String, CaseIterable, Codable {
    case hex = "HEX"
    case rgb = "RGB"
    case hsl = "HSL"
    case swiftUI = "SwiftUI"
}

@Observable
final class AppState {
    var browserManager = BrowserManager()
    var colorPickerManager = ColorPickerManager()
    var cleaningModeManager = CleaningModeManager()
    var systemStatsManager = SystemStatsManager()
    var qrScannerManager = QRScannerManager()
    var clockManager = ClockManager()
    var audioManager = AudioManager.shared
    var aiUsageManager = AIUsageManager()
    var voiceModeManager = VoiceModeManager()
    var finderUtilsManager = FinderUtilsManager.shared
    var lockdownModeManager = LockdownModeManager.shared
    var keepAwakeManager = KeepAwakeManager()
    var portKillerManager = PortKillerManager()
    var textCaptureManager = TextCaptureManager()
    var shortcutsManager = GlobalShortcutsManager()

    var showingSettings = false
    var showingOnboarding = false
    var showingPortKiller = false

    var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update launch at login: \(error)")
            }
        }
    }

    var colorCopyFormat: ColorFormat {
        get {
            if let raw = UserDefaults.standard.string(forKey: "macbar_color_format"),
               let format = ColorFormat(rawValue: raw) {
                return format
            }
            return .hex
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "macbar_color_format")
        }
    }

    init() {
        browserManager.refresh()
        systemStatsManager.startMonitoring()
        aiUsageManager.startMonitoring()
        voiceModeManager.setupHotkey()
        voiceModeManager.setupOverlay()
        setupGlobalShortcuts()

        // Show onboarding on first launch
        if !UserDefaults.standard.bool(forKey: "macbar.onboardingCompleted") {
            showingOnboarding = true
        }
    }

    private func setupGlobalShortcuts() {
        shortcutsManager.start { [weak self] actionID in
            Task { @MainActor in
                guard let self else { return }
                switch actionID {
                case "colorPicker":
                    await self.colorPickerManager.pickColor()
                case "qrScanner":
                    self.qrScannerManager.scanScreen()
                case "cleaningMode":
                    self.cleaningModeManager.toggle()
                case "lockdownMode":
                    self.lockdownModeManager.toggle()
                case "muteSpeaker":
                    self.audioManager.toggleSound()
                case "muteMic":
                    self.audioManager.toggleMic()
                case "openTerminal":
                    self.finderUtilsManager.openInTerminal()
                case "copyPath":
                    self.finderUtilsManager.copyPath()
                case "hiddenFiles":
                    self.finderUtilsManager.toggleHiddenFiles()
                default:
                    break
                }
            }
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "macbar.onboardingCompleted")
        showingOnboarding = false
    }
}
