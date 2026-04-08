import AppKit
import SwiftUI

struct UUIDGeneratorView: View {
    @State private var copied = false

    var body: some View {
        Button {
            let uuid = UUID().uuidString
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(uuid, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "number")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? "Copied" : "UUID")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(copied ? Color.green.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct ULIDGeneratorView: View {
    @State private var copied = false

    var body: some View {
        Button {
            let ulid = ULID.generate()
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(ulid, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "key")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? "Copied" : "ULID")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(copied ? Color.green.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ULID Generator (Crockford Base32, timestamp + random)

enum ULID {
    private static let encoding: [Character] = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    static func generate() -> String {
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        var chars = [Character](repeating: "0", count: 26)

        // Encode 48-bit timestamp into first 10 characters
        var t = timestamp
        for i in stride(from: 9, through: 0, by: -1) {
            chars[i] = encoding[Int(t & 0x1F)]
            t >>= 5
        }

        // Encode 80 bits of randomness into last 16 characters
        for i in 10..<26 {
            chars[i] = encoding[Int.random(in: 0..<32)]
        }

        return String(chars)
    }
}
