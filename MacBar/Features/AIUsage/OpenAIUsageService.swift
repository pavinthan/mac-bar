import Foundation

struct CodexUsage {
    var sessionPercent: Double
    var weeklyPercent: Double
    var plan: String
    var sessionResetsAt: Date?
    var weeklyResetsAt: Date?
}

enum OpenAIUsageService {
    struct Credentials {
        let accessToken: String
        let refreshToken: String?
        let planType: String
    }

    static func loadCredentials() -> Credentials? {
        let path = authFilePath()
        guard let data = FileManager.default.contents(atPath: path),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        // Modern format: { "tokens": { "access_token": "...", "refresh_token": "..." } }
        if let tokens = json["tokens"] as? [String: Any],
           let accessToken = tokens["access_token"] as? String {
            let refreshToken = tokens["refresh_token"] as? String
            let planType = extractPlanFromJWT(accessToken) ?? "unknown"
            return Credentials(accessToken: accessToken, refreshToken: refreshToken, planType: planType)
        }

        // Legacy format: { "OPENAI_API_KEY": "sk-..." }
        if let apiKey = json["OPENAI_API_KEY"] as? String {
            return Credentials(accessToken: apiKey, refreshToken: nil, planType: "unknown")
        }

        return nil
    }

    static func planDisplayName(for credentials: Credentials) -> String {
        switch credentials.planType {
        case "plus": return "ChatGPT Plus"
        case "pro": return "ChatGPT Pro"
        case "team": return "ChatGPT Team"
        case "enterprise": return "ChatGPT Enterprise"
        case "free": return "ChatGPT Free"
        default: return "Codex"
        }
    }

    static func fetch(credentials: Credentials) async throws -> CodexUsage {
        let url = URL(string: "https://chatgpt.com/backend-api/wham/usage")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("MacBar/1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            throw OpenAIError.unauthorized
        }

        if httpResponse.statusCode == 429 {
            throw OpenAIError.rateLimited
        }

        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else {
            throw URLError(.badServerResponse)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }

        let plan = planDisplayName(for: credentials)

        // Parse rate limit windows from response
        // API returns: { "rate_limit": { "primary_window": { "used_percent": N, "reset_at": unix }, "secondary_window": { ... } } }
        var sessionPercent = 0.0
        var weeklyPercent = 0.0
        var sessionResetsAt: Date?
        var weeklyResetsAt: Date?

        if let rateLimit = json["rate_limit"] as? [String: Any] {
            if let primaryWindow = rateLimit["primary_window"] as? [String: Any] {
                sessionPercent = primaryWindow["used_percent"] as? Double
                    ?? (primaryWindow["used_percent"] as? Int).map(Double.init) ?? 0
                sessionResetsAt = extractTimestamp(primaryWindow["reset_at"])
            }
            if let secondaryWindow = rateLimit["secondary_window"] as? [String: Any] {
                weeklyPercent = secondaryWindow["used_percent"] as? Double
                    ?? (secondaryWindow["used_percent"] as? Int).map(Double.init) ?? 0
                weeklyResetsAt = extractTimestamp(secondaryWindow["reset_at"])
            }
        }

        return CodexUsage(
            sessionPercent: sessionPercent,
            weeklyPercent: weeklyPercent,
            plan: plan,
            sessionResetsAt: sessionResetsAt,
            weeklyResetsAt: weeklyResetsAt
        )
    }

    static func refreshToken(credentials: Credentials) async throws -> Credentials {
        guard let refreshToken = credentials.refreshToken else {
            throw OpenAIError.noRefreshToken
        }

        let url = URL(string: "https://auth.openai.com/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: String] = [
            "client_id": "app_EMoamEEZ73f0CkXaXp7hrann",
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "scope": "openid profile email"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
        else {
            throw OpenAIError.tokenRefreshFailed
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccessToken = json["access_token"] as? String
        else {
            throw OpenAIError.tokenRefreshFailed
        }

        let newRefreshToken = json["refresh_token"] as? String ?? refreshToken
        let planType = extractPlanFromJWT(newAccessToken) ?? credentials.planType

        // Update auth.json with new tokens
        updateAuthFile(accessToken: newAccessToken, refreshToken: newRefreshToken)

        return Credentials(accessToken: newAccessToken, refreshToken: newRefreshToken, planType: planType)
    }

    // MARK: - Private

    private static func authFilePath() -> String {
        if let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"] {
            return codexHome + "/auth.json"
        }
        return NSHomeDirectory() + "/.codex/auth.json"
    }

    private static func extractPlanFromJWT(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }

        var base64 = String(parts[1])
        while base64.count % 4 != 0 {
            base64.append("=")
        }

        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let auth = json["https://api.openai.com/auth"] as? [String: Any],
              let planType = auth["chatgpt_plan_type"] as? String
        else {
            return nil
        }

        return planType
    }

    private static func extractTimestamp(_ value: Any?) -> Date? {
        if let ts = value as? Double {
            return Date(timeIntervalSince1970: ts)
        }
        if let ts = value as? Int {
            return Date(timeIntervalSince1970: TimeInterval(ts))
        }
        return nil
    }

    private static func parseDate(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.date(from: string) ?? ISO8601DateFormatter().date(from: string)
    }

    private static func updateAuthFile(accessToken: String, refreshToken: String) {
        let path = authFilePath()
        guard let data = FileManager.default.contents(atPath: path),
              var json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              var tokens = json["tokens"] as? [String: Any]
        else {
            return
        }

        tokens["access_token"] = accessToken
        tokens["refresh_token"] = refreshToken
        json["tokens"] = tokens

        if let updated = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            try? updated.write(to: URL(fileURLWithPath: path))
        }
    }

    enum OpenAIError: LocalizedError {
        case unauthorized
        case rateLimited
        case noRefreshToken
        case tokenRefreshFailed

        var errorDescription: String? {
            switch self {
            case .unauthorized: return "Token expired or invalid"
            case .rateLimited: return "Rate limited, retrying..."
            case .noRefreshToken: return "No refresh token available"
            case .tokenRefreshFailed: return "Token refresh failed"
            }
        }
    }
}
