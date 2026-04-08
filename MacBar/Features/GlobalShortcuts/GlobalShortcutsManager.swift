import Carbon
import Cocoa

struct ShortcutDefinition: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    var keyCode: UInt32
    var modifiers: UInt32
    var isEnabled: Bool

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        if let name = keyName(keyCode) { parts.append(name) }
        return parts.joined()
    }

    private func keyName(_ code: UInt32) -> String? {
        let map: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J",
            40: "K", 45: "N", 46: "M",
        ]
        return map[code]
    }
}

@Observable
final class GlobalShortcutsManager {
    var shortcuts: [ShortcutDefinition] = []

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?
    private var actionHandler: ((String) -> Void)?

    private static let defaultsKey = "macbar.globalShortcuts"

    // Default: Control+Option+<key>
    static let defaults: [ShortcutDefinition] = [
        ShortcutDefinition(id: "colorPicker", label: "Color Picker", keyCode: 8, modifiers: UInt32(controlKey | optionKey), isEnabled: true),       // ⌃⌥C
        ShortcutDefinition(id: "qrScanner", label: "QR Scanner", keyCode: 12, modifiers: UInt32(controlKey | optionKey), isEnabled: true),           // ⌃⌥Q
        ShortcutDefinition(id: "cleaningMode", label: "Cleaning Mode", keyCode: 40, modifiers: UInt32(controlKey | optionKey), isEnabled: true),     // ⌃⌥K
        ShortcutDefinition(id: "lockdownMode", label: "Lockdown Mode", keyCode: 37, modifiers: UInt32(controlKey | optionKey), isEnabled: true),     // ⌃⌥L
        ShortcutDefinition(id: "muteSpeaker", label: "Mute Speaker", keyCode: 46, modifiers: UInt32(controlKey | optionKey), isEnabled: true),       // ⌃⌥M
        ShortcutDefinition(id: "muteMic", label: "Mute Mic", keyCode: 45, modifiers: UInt32(controlKey | optionKey), isEnabled: true),               // ⌃⌥N
        ShortcutDefinition(id: "openTerminal", label: "Open Terminal", keyCode: 17, modifiers: UInt32(controlKey | optionKey), isEnabled: true),     // ⌃⌥T
        ShortcutDefinition(id: "copyPath", label: "Copy Path", keyCode: 35, modifiers: UInt32(controlKey | optionKey), isEnabled: true),             // ⌃⌥P
        ShortcutDefinition(id: "hiddenFiles", label: "Hidden Files", keyCode: 4, modifiers: UInt32(controlKey | optionKey), isEnabled: true),        // ⌃⌥H
    ]

    init() {
        shortcuts = Self.loadShortcuts()
    }

    func start(actionHandler: @escaping (String) -> Void) {
        self.actionHandler = actionHandler
        registerAll()
    }

    func stop() {
        unregisterAll()
    }

    func updateShortcut(_ shortcut: ShortcutDefinition) {
        if let idx = shortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            shortcuts[idx] = shortcut
            saveShortcuts()
            unregisterAll()
            registerAll()
        }
    }

    func resetDefaults() {
        shortcuts = Self.defaults
        saveShortcuts()
        unregisterAll()
        registerAll()
    }

    // MARK: - Carbon Hot Key Registration

    private func registerAll() {
        unregisterAll()

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<GlobalShortcutsManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                  nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                let index = Int(hotKeyID.id)
                if index < manager.shortcuts.count {
                    let shortcutID = manager.shortcuts[index].id
                    DispatchQueue.main.async {
                        manager.actionHandler?(shortcutID)
                    }
                }
                return noErr
            },
            1, &eventType, selfPtr, &eventHandler
        )

        // Register each shortcut
        for (index, shortcut) in shortcuts.enumerated() {
            guard shortcut.isEnabled else {
                hotKeyRefs.append(nil)
                continue
            }

            let hotKeyID = EventHotKeyID(signature: OSType(0x4D424152), id: UInt32(index)) // "MBAR"
            let carbonMods = carbonModifiers(from: shortcut.modifiers)
            var ref: EventHotKeyRef?

            let status = RegisterEventHotKey(
                shortcut.keyCode,
                carbonMods,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &ref
            )

            hotKeyRefs.append(status == noErr ? ref : nil)
        }
    }

    private func unregisterAll() {
        for ref in hotKeyRefs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    private func carbonModifiers(from mods: UInt32) -> UInt32 {
        var result: UInt32 = 0
        if mods & UInt32(controlKey) != 0 { result |= UInt32(controlKey) }
        if mods & UInt32(optionKey) != 0 { result |= UInt32(optionKey) }
        if mods & UInt32(shiftKey) != 0 { result |= UInt32(shiftKey) }
        if mods & UInt32(cmdKey) != 0 { result |= UInt32(cmdKey) }
        return result
    }

    // MARK: - Persistence

    private static func loadShortcuts() -> [ShortcutDefinition] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let saved = try? JSONDecoder().decode([ShortcutDefinition].self, from: data)
        else {
            return defaults
        }
        // Merge with defaults in case new shortcuts were added
        var result = saved
        for def in defaults {
            if !result.contains(where: { $0.id == def.id }) {
                result.append(def)
            }
        }
        return result
    }

    private func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
