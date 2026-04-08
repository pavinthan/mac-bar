import Foundation

@Observable
final class AIUsageManager {
    var claudeUsage: ClaudeUsage?
    var claudeDetected = false
    var claudePlan: String?
    var claudeError: String?

    var codexUsage: CodexUsage?
    var codexDetected = false
    var codexPlanName: String?
    var codexError: String?

    var isLoading = false

    private var timer: Timer?
    private var claudeCredentials: ClaudeUsageService.Credentials?
    private var codexCredentials: OpenAIUsageService.Credentials?

    var isConfigured: Bool {
        claudeDetected || codexDetected
    }

    func startMonitoring() {
        detectServices()
        if claudeDetected || codexDetected {
            refresh()
            timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
                self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func detectServices() {
        claudeCredentials = ClaudeUsageService.loadCredentials()
        claudeDetected = claudeCredentials != nil
        if let creds = claudeCredentials {
            claudePlan = ClaudeUsageService.planName(for: creds)
            // Load cached data immediately so UI isn't empty
            if let cached = ClaudeUsageService.loadCache() {
                claudeUsage = cached
            }
        }

        codexCredentials = OpenAIUsageService.loadCredentials()
        codexDetected = codexCredentials != nil
        if let creds = codexCredentials {
            codexPlanName = OpenAIUsageService.planDisplayName(for: creds)
        }
    }

    func refresh() {
        Task { @MainActor in
            isLoading = true
            await withTaskGroup(of: Void.self) { group in
                if claudeCredentials != nil {
                    group.addTask { await self.refreshClaude() }
                }
                if codexCredentials != nil {
                    group.addTask { await self.refreshCodex() }
                }
            }
            isLoading = false
        }
    }

    @MainActor
    private func refreshClaude() async {
        guard let creds = claudeCredentials else { return }

        if let usage = await ClaudeUsageService.fetchWithFallback(credentials: creds) {
            claudeUsage = usage
            claudeError = nil

            // Show staleness indicator if data is from cache (>10 min old)
            if let fetchedAt = usage.fetchedAt, Date().timeIntervalSince(fetchedAt) > 600 {
                let mins = Int(Date().timeIntervalSince(fetchedAt) / 60)
                claudeError = mins > 60 ? "\(mins / 60)h ago" : "\(mins)m ago"
            }
        }
        // If fallback returned nil but we already have data, keep showing it silently
    }

    @MainActor
    private func refreshCodex() async {
        guard var creds = codexCredentials else { return }

        do {
            codexUsage = try await OpenAIUsageService.fetch(credentials: creds)
            codexError = nil
        } catch let error as OpenAIUsageService.OpenAIError where error == .unauthorized {
            do {
                let refreshed = try await OpenAIUsageService.refreshToken(credentials: creds)
                codexCredentials = refreshed
                creds = refreshed
                codexPlanName = OpenAIUsageService.planDisplayName(for: refreshed)
                codexUsage = try await OpenAIUsageService.fetch(credentials: refreshed)
                codexError = nil
            } catch {
                if codexUsage == nil {
                    codexError = "Token expired"
                }
            }
        } catch {
            print("Codex fetch failed: \(error)")
            if codexUsage == nil {
                codexError = error.localizedDescription
            }
        }
    }
}
