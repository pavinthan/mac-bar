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
    var audioManager = AudioManager()
    var aiUsageManager = AIUsageManager()

    var showingSettings = false

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
    }
}
