import Foundation

struct ClaudeUsage: Codable {
    var sessionPercent: Double
    var weeklyPercent: Double
    var opusPercent: Double
    var sonnetPercent: Double
    var plan: String
    var sessionResetsAt: Date?
    var weeklyResetsAt: Date?
    var fetchedAt: Date?
}

enum ClaudeServiceError: LocalizedError {
    case rateLimited
    case unauthorized
    case serverError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .rateLimited: return "Rate limited"
        case .unauthorized: return "Token expired"
        case .serverError(let code): return "Error (\(code))"
        case .noData: return "No data"
        }
    }
}

enum ClaudeUsageService {
    private static let usageURL = "https://api.anthropic.com/api/oauth/usage"
    private static let cacheFile = NSHomeDirectory() + "/.cache/macbar/claude_usage.json"

    struct Credentials {
        let accessToken: String
        let subscriptionType: String
    }

    // MARK: - Fetch with fallback: OAuth → Cache

    static func fetchWithFallback(credentials: Credentials) async -> ClaudeUsage? {
        // Strategy 1: OAuth API
        if let usage = try? await fetchOAuth(credentials: credentials) {
            saveCache(usage)
            return usage
        }

        // Strategy 2: Disk cache (from last successful fetch)
        return loadCache()
    }

    // MARK: - Strategy 1: OAuth API

    static func fetchOAuth(credentials: Credentials) async throws -> ClaudeUsage {
        let url = URL(string: usageURL)!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code/1.0.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 429 {
            throw ClaudeServiceError.rateLimited
        }
        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw ClaudeServiceError.unauthorized
        }
        guard httpResponse.statusCode == 200 else {
            throw ClaudeServiceError.serverError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        return ClaudeUsage(
            sessionPercent: extractUtil(json, "five_hour"),
            weeklyPercent: extractUtil(json, "seven_day"),
            opusPercent: extractUtil(json, "seven_day_opus"),
            sonnetPercent: extractUtil(json, "seven_day_sonnet"),
            plan: planName(for: credentials),
            sessionResetsAt: extractReset(json, "five_hour"),
            weeklyResetsAt: extractReset(json, "seven_day"),
            fetchedAt: Date()
        )
    }

    // MARK: - Strategy 2: CLI Probe

    static func fetchViaCLI(plan: String) -> ClaudeUsage? {
        guard let claudePath = findClaudeCLI() else { return nil }

        // Use expect-style approach: pipe /usage command to claude
        let process = Process()
        process.executableURL = URL(fileURLWithPath: claudePath)
        process.arguments = ["-p", "Reply with only the output of /usage. No other text."]

        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = FileHandle.nullDevice
        process.environment = ProcessInfo.processInfo.environment

        do {
            try process.run()
        } catch {
            return nil
        }

        // Timeout after 20 seconds
        let deadline = DispatchTime.now() + .seconds(20)
        DispatchQueue.global().asyncAfter(deadline: deadline) {
            if process.isRunning { process.terminate() }
        }

        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }

        return parseCLIOutput(output, plan: plan)
    }

    private static func findClaudeCLI() -> String? {
        let paths = [
            NSHomeDirectory() + "/.local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
        ]
        return paths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func parseCLIOutput(_ output: String, plan: String) -> ClaudeUsage? {
        // Parse percentages from CLI output like "5-hour: 9.0%" or "7-day: 19.0%"
        let lines = output.lowercased()

        var session = 0.0
        var weekly = 0.0

        // Look for patterns like "9.0%" near "5-hour" or "session"
        if let range = lines.range(of: #"5.?hour[^0-9]*?([\d.]+)\s*%"#, options: .regularExpression) {
            let match = String(lines[range])
            if let num = Double(match.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)) {
                session = num
            }
        }

        if let range = lines.range(of: #"7.?day[^0-9]*?([\d.]+)\s*%"#, options: .regularExpression) {
            let match = String(lines[range])
            if let num = Double(match.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)) {
                weekly = num
            }
        }

        // Also try "session" and "weekly" labels
        if session == 0, let range = lines.range(of: #"session[^0-9]*?([\d.]+)\s*%"#, options: .regularExpression) {
            let match = String(lines[range])
            if let num = Double(match.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)) {
                session = num
            }
        }

        if weekly == 0, let range = lines.range(of: #"weekly[^0-9]*?([\d.]+)\s*%"#, options: .regularExpression) {
            let match = String(lines[range])
            if let num = Double(match.replacingOccurrences(of: #"[^0-9.]"#, with: "", options: .regularExpression)) {
                weekly = num
            }
        }

        guard session > 0 || weekly > 0 else { return nil }

        return ClaudeUsage(
            sessionPercent: session,
            weeklyPercent: weekly,
            opusPercent: 0,
            sonnetPercent: 0,
            plan: plan,
            sessionResetsAt: nil,
            weeklyResetsAt: nil,
            fetchedAt: Date()
        )
    }

    // MARK: - Strategy 3: Disk Cache

    static func saveCache(_ usage: ClaudeUsage) {
        let dir = (cacheFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(usage) {
            try? data.write(to: URL(fileURLWithPath: cacheFile))
        }
    }

    static func loadCache() -> ClaudeUsage? {
        guard let data = FileManager.default.contents(atPath: cacheFile) else {
            print("Claude cache: file not found at \(cacheFile)")
            return nil
        }
        do {
            return try JSONDecoder().decode(ClaudeUsage.self, from: data)
        } catch {
            print("Claude cache: decode error: \(error)")
            return nil
        }
    }

    // MARK: - Credentials

    static func loadCredentials() -> Credentials? {
        if let creds = loadFromKeychainCLI() { return creds }
        if let creds = loadFromFile() { return creds }
        return loadFromOAuthProfile()
    }

    private static func loadFromKeychainCLI() -> Credentials? {
        let accounts = [NSUserName(), NSFullUserName()]
        var tried = Set<String>()

        for account in accounts {
            if account.isEmpty || tried.contains(account) { continue }
            tried.insert(account)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
            process.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-a", account, "-w"]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            do { try process.run(); process.waitUntilExit() } catch { continue }
            guard process.terminationStatus == 0 else { continue }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let jsonStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !jsonStr.isEmpty,
                  let jsonData = jsonStr.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                  let oauth = json["claudeAiOauth"] as? [String: Any],
                  let accessToken = oauth["accessToken"] as? String
            else { continue }

            let subscriptionType = oauth["subscriptionType"] as? String ?? "unknown"
            return Credentials(accessToken: accessToken, subscriptionType: subscriptionType)
        }
        return nil
    }

    private static func loadFromFile() -> Credentials? {
        let path = NSHomeDirectory() + "/.claude/.credentials.json"
        guard let data = FileManager.default.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let accessToken = oauth["accessToken"] as? String
        else { return nil }
        return Credentials(accessToken: accessToken, subscriptionType: oauth["subscriptionType"] as? String ?? "unknown")
    }

    private static func loadFromOAuthProfile() -> Credentials? {
        let path = NSHomeDirectory() + "/.claude/profiles/default/claude_oauth.json"
        guard let data = FileManager.default.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["accessToken"] as? String
        else { return nil }
        let subscriptionType = json["subscriptionType"] as? String ?? json["rateLimitTier"] as? String ?? "unknown"
        return Credentials(accessToken: accessToken, subscriptionType: subscriptionType)
    }

    static func planName(for credentials: Credentials) -> String {
        switch credentials.subscriptionType {
        case "max": return "Claude Max"
        case "pro": return "Claude Pro"
        case "team": return "Claude Team"
        case "enterprise": return "Claude Enterprise"
        default: return "Claude"
        }
    }

    // MARK: - Helpers

    private static func extractUtil(_ json: [String: Any], _ key: String) -> Double {
        (json[key] as? [String: Any])?["utilization"] as? Double ?? 0
    }

    private static func extractReset(_ json: [String: Any], _ key: String) -> Date? {
        guard let str = (json[key] as? [String: Any])?["resets_at"] as? String else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
}
