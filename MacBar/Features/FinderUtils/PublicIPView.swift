import AppKit
import SwiftUI

struct PublicIPView: View {
    @State private var copied = false

    var body: some View {
        Button {
            Task {
                if let ip = await fetchPublicIP() {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(ip, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "network")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? "Copied" : "Public IP")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(copied ? Color.green.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func fetchPublicIP() async -> String? {
        guard let url = URL(string: "https://api.ipify.org") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }
}
