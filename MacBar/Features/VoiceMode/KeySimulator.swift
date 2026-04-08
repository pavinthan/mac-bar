import CoreGraphics
import Foundation

final class KeySimulator {
    private let keystrokeDelay: useconds_t = 8000
    private let maxUnicodeChunkSize = 20

    func typeText(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)

        for character in text {
            let scalar = String(character)

            if character.isASCII, let asciiValue = character.asciiValue {
                if let keyCode = asciiKeyCode(for: asciiValue) {
                    let flags = asciiFlags(for: asciiValue)
                    simulateKeystroke(keyCode: keyCode, flags: flags, source: source)
                } else {
                    typeUnicodeString(scalar, source: source)
                }
            } else {
                typeUnicodeString(scalar, source: source)
            }

            usleep(keystrokeDelay)
        }
    }

    func simulateKeystroke(
        keyCode: CGKeyCode,
        flags: CGEventFlags = [],
        source: CGEventSource? = nil
    ) {
        let src = source ?? CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    func simulatePaste() {
        simulateKeystroke(keyCode: 9, flags: .maskCommand)
    }

    func simulateCopy() {
        simulateKeystroke(keyCode: 8, flags: .maskCommand)
    }

    // MARK: - Private

    private func typeUnicodeString(_ string: String, source: CGEventSource?) {
        let utf16 = Array(string.utf16)
        let chunks = stride(from: 0, to: utf16.count, by: maxUnicodeChunkSize).map {
            Array(utf16[$0..<min($0 + maxUnicodeChunkSize, utf16.count)])
        }

        for chunk in chunks {
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                continue
            }

            keyDown.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)
            keyUp.keyboardSetUnicodeString(stringLength: chunk.count, unicodeString: chunk)

            keyDown.post(tap: .cghidEventTap)
            keyUp.post(tap: .cghidEventTap)

            usleep(keystrokeDelay)
        }
    }

    private func asciiKeyCode(for ascii: UInt8) -> CGKeyCode? {
        let map: [UInt8: CGKeyCode] = [
            0x61: 0, 0x73: 1, 0x64: 2, 0x66: 3, 0x68: 4, 0x67: 5, 0x7A: 6, 0x78: 7,
            0x63: 8, 0x76: 9, 0x62: 11, 0x71: 12, 0x77: 13, 0x65: 14, 0x72: 15,
            0x79: 16, 0x74: 17, 0x31: 18, 0x32: 19, 0x33: 20, 0x34: 21, 0x36: 22,
            0x35: 23, 0x3D: 24, 0x39: 25, 0x37: 26, 0x2D: 27, 0x38: 28, 0x30: 29,
            0x5D: 30, 0x6F: 31, 0x75: 32, 0x5B: 33, 0x69: 34, 0x70: 35, 0x6C: 37,
            0x6A: 38, 0x27: 39, 0x6B: 40, 0x3B: 41, 0x5C: 42, 0x2C: 43, 0x2F: 44,
            0x6E: 45, 0x6D: 46, 0x2E: 47, 0x60: 50, 0x20: 49, 0x0D: 36, 0x09: 48,
        ]

        let lower = (ascii >= 0x41 && ascii <= 0x5A) ? ascii + 32 : ascii
        return map[lower]
    }

    private func asciiFlags(for ascii: UInt8) -> CGEventFlags {
        if ascii >= 0x41 && ascii <= 0x5A {
            return .maskShift
        }

        let shiftChars: Set<UInt8> = [
            0x21, 0x40, 0x23, 0x24, 0x25, 0x5E, 0x26, 0x2A,
            0x28, 0x29, 0x5F, 0x2B, 0x7B, 0x7D, 0x7C, 0x3A,
            0x22, 0x3C, 0x3E, 0x3F, 0x7E,
        ]

        if shiftChars.contains(ascii) {
            return .maskShift
        }

        return []
    }
}
