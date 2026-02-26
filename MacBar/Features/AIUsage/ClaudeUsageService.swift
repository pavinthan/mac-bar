import Foundation

struct ClaudeUsage {
    var sessionPercent: Double
    var weeklyPercent: Double
    var opusPercent: Double
    var sonnetPercent: Double
    var plan: String
    var resetsAt: Date?
}

struct ClaudeCredentials {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let subscriptionType: String

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

enum ClaudeUsageService {
    private static let credentialsPath = NSHomeDirectory() + "/.claude/.credentials.json"
    private static let usageURL = "https://api.anthropic.com/api/oauth/usage"

    static func loadCredentials() -> ClaudeCredentials? {
        guard let data = FileManager.default.contents(atPath: credentialsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let accessToken = oauth["accessToken"] as? String,
              let refreshToken = oauth["refreshToken"] as? String,
              let expiresAtMs = oauth["expiresAt"] as? Double
        else {
            return nil
        }

        let subscriptionType = oauth["subscriptionType"] as? String ?? "unknown"

        return ClaudeCredentials(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date(timeIntervalSince1970: expiresAtMs / 1000),
            subscriptionType: subscriptionType
        )
    }

    static func fetch(credentials: ClaudeCredentials) async throws -> ClaudeUsage {
        let url = URL(string: usageURL)!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("MacBar", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let sessionUtil = extractUtilization(from: json, key: "five_hour")
        let weeklyUtil = extractUtilization(from: json, key: "seven_day")
        let opusUtil = extractUtilization(from: json, key: "seven_day_opus")
        let sonnetUtil = extractUtilization(from: json, key: "seven_day_sonnet")
        let resetsAt = extractResetsAt(from: json, key: "five_hour")

        let plan: String
        switch credentials.subscriptionType {
        case "max": plan = "Claude Max"
        case "pro": plan = "Claude Pro"
        case "team": plan = "Claude Team"
        case "enterprise": plan = "Claude Enterprise"
        default: plan = "Claude"
        }

        return ClaudeUsage(
            sessionPercent: sessionUtil,
            weeklyPercent: weeklyUtil,
            opusPercent: opusUtil,
            sonnetPercent: sonnetUtil,
            plan: plan,
            resetsAt: resetsAt
        )
    }

    private static func extractUtilization(from json: [String: Any], key: String) -> Double {
        guard let section = json[key] as? [String: Any],
              let utilization = section["utilization"] as? Double
        else {
            return 0
        }
        return utilization
    }

    private static func extractResetsAt(from json: [String: Any], key: String) -> Date? {
        guard let section = json[key] as? [String: Any],
              let resetsAtStr = section["resets_at"] as? String
        else {
            return nil
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: resetsAtStr) ?? ISO8601DateFormatter().date(from: resetsAtStr)
    }
}
