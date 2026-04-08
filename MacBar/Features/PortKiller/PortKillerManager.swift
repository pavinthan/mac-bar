import Foundation

struct PortEntry: Identifiable, Equatable {
    let id: String
    let port: Int
    let pid: Int
    let command: String
    let address: String

    var displayName: String {
        // Friendly names for common ports
        switch port {
        case 80: return "HTTP"
        case 443: return "HTTPS"
        case 3000: return "Dev Server"
        case 3001: return "Dev Server"
        case 4000: return "Dev Server"
        case 5000: return "Dev Server"
        case 5173: return "Vite"
        case 5432: return "PostgreSQL"
        case 3306: return "MySQL"
        case 6379: return "Redis"
        case 8080: return "HTTP Alt"
        case 8000: return "Django"
        case 8888: return "Jupyter"
        case 9000: return "PHP-FPM"
        case 27017: return "MongoDB"
        default: return command
        }
    }
}

@Observable
final class PortKillerManager {
    var ports: [PortEntry] = []
    var isScanning = false

    func scan() {
        isScanning = true
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-iTCP", "-sTCP:LISTEN", "-P", "-n"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            isScanning = false
            return
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        var seen = Set<String>()
        var entries: [PortEntry] = []

        for line in output.components(separatedBy: "\n").dropFirst() {
            let parts = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard parts.count >= 9 else { continue }

            let command = parts[0]
            guard let pid = Int(parts[1]) else { continue }
            let name = parts[8]

            // Parse address:port from e.g. "*:3000" or "127.0.0.1:8080"
            guard let colonIdx = name.lastIndex(of: ":") else { continue }
            let address = String(name[name.startIndex..<colonIdx])
            guard let port = Int(name[name.index(after: colonIdx)...]) else { continue }

            // Deduplicate by port+pid (IPv4/IPv6 show separately)
            let key = "\(port)-\(pid)"
            guard !seen.contains(key) else { continue }
            seen.insert(key)

            entries.append(PortEntry(
                id: key,
                port: port,
                pid: pid,
                command: command,
                address: address == "*" ? "0.0.0.0" : address
            ))
        }

        ports = entries.sorted { $0.port < $1.port }
        isScanning = false
    }

    func kill(entry: PortEntry) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/kill")
        process.arguments = ["-9", String(entry.pid)]
        try? process.run()
        process.waitUntilExit()

        // Rescan after kill
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.scan()
        }
    }
}
