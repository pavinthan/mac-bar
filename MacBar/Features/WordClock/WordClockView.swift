import SwiftUI

struct ClockEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var timezoneID: String
    var label: String

    init(timezoneID: String, label: String) {
        self.id = UUID()
        self.timezoneID = timezoneID
        self.label = label
    }
}

@Observable
final class ClockManager {
    var clocks: [ClockEntry] {
        didSet {
            save()
        }
    }

    var showingAddSheet = false

    private static let storageKey = "macbar_clocks"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([ClockEntry].self, from: data),
           !saved.isEmpty {
            self.clocks = saved
        } else {
            self.clocks = [ClockEntry(timezoneID: "UTC", label: "UTC")]
        }
    }

    func addClock(timezoneID: String, label: String) {
        clocks.append(ClockEntry(timezoneID: timezoneID, label: label))
    }

    func removeClock(id: UUID) {
        clocks.removeAll { $0.id == id }
        if clocks.isEmpty {
            clocks = [ClockEntry(timezoneID: "UTC", label: "UTC")]
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(clocks) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

struct WordClockView: View {
    @Environment(AppState.self) private var appState
    @State private var now = Date()
    @State private var publicIP: String?
    @State private var showPublicIP = false
    @State private var copiedTime = false
    @State private var copiedIP = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 6) {
            ForEach(appState.clockManager.clocks) { clock in
                clockRow(clock: clock)
            }
        }
        .frame(maxWidth: .infinity)
        .onReceive(timer) { _ in
            now = Date()
        }
        .task {
            if publicIP == nil {
                publicIP = await fetchPublicIP()
            }
        }
    }

    private func clockRow(clock: ClockEntry) -> some View {
        let tz = TimeZone(identifier: clock.timezoneID) ?? .gmt

        let timeString: String = {
            let f = DateFormatter()
            f.timeZone = tz
            f.dateFormat = "HH:mm:ss"
            return f.string(from: now)
        }()

        let dateString: String = {
            let f = DateFormatter()
            f.timeZone = tz
            f.dateFormat = "EEE, d MMM yyyy"
            return f.string(from: now)
        }()

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Button {
                        let f = ISO8601DateFormatter()
                        f.formatOptions = [.withInternetDateTime]
                        f.timeZone = TimeZone(identifier: "UTC")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(f.string(from: now), forType: .string)
                        copiedTime = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedTime = false }
                    } label: {
                        Text(copiedTime ? "Copied!" : timeString)
                            .font(.system(size: 18, weight: .semibold, design: .monospaced))
                    }
                    .buttonStyle(.plain)

                    Text(clock.label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()

                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(localIP(), forType: .string)
                        copiedIP = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedIP = false }
                    } label: {
                        Text(copiedIP ? "Copied" : localIP())
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    Text(dateString)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Button {
                        if let ip = publicIP {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(ip, forType: .string)
                            showPublicIP = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showPublicIP = false
                            }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: showPublicIP ? "checkmark" : "network")
                                .font(.system(size: 8))
                            Text(showPublicIP ? "Copied" : "Public IP")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            if appState.clockManager.clocks.count > 1 {
                Button {
                    appState.clockManager.removeClock(id: clock.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension WordClockView {
    var publicIPDisplay: String {
        guard let ip = publicIP else { return "•••••••" }
        if showPublicIP {
            return ip
        }
        // Mask: show first octet, mask the rest
        let parts = ip.split(separator: ".")
        if parts.count == 4 {
            return "\(parts[0]).*.*.*"
        }
        return "•••••••"
    }

    func fetchPublicIP() async -> String? {
        guard let url = URL(string: "https://api.ipify.org") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    func localIP() -> String {
        var address = "—"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return address }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let sa = ptr.pointee.ifa_addr.pointee
            guard sa.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: ptr.pointee.ifa_name)
            guard name == "en0" || name == "en1" else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(ptr.pointee.ifa_addr, socklen_t(sa.sa_len),
                        &hostname, socklen_t(hostname.count),
                        nil, 0, NI_NUMERICHOST)
            address = String(cString: hostname)
            break
        }
        return address
    }
}

struct AddTimezoneSheet: View {
    let clockManager: ClockManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTZ: String?

    private var filteredTimezones: [(id: String, display: String)] {
        let all = TimeZone.knownTimeZoneIdentifiers.map { id in
            let display = id.replacingOccurrences(of: "_", with: " ")
            return (id: id, display: display)
        }

        if searchText.isEmpty {
            return all
        }

        return all.filter {
            $0.display.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Add Timezone")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            TextField("Search timezones...", text: $searchText)
                .textFieldStyle(.roundedBorder)

            List(filteredTimezones, id: \.id) { tz in
                Button {
                    selectedTZ = tz.id
                } label: {
                    HStack {
                        Text(tz.display)
                            .font(.system(size: 12))
                        Spacer()
                        if selectedTZ == tz.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .frame(height: 200)

            Button("Add") {
                if let tz = selectedTZ {
                    let label = tz.components(separatedBy: "/").last?
                        .replacingOccurrences(of: "_", with: " ") ?? tz
                    clockManager.addClock(timezoneID: tz, label: label)
                    dismiss()
                }
            }
            .disabled(selectedTZ == nil)
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(width: 300, height: 340)
    }
}
