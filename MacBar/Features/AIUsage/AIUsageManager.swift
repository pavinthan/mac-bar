import Foundation

@Observable
final class AIUsageManager {
    var claudeUsage: ClaudeUsage?
    var claudeDetected = false
    var isLoading = false

    private var timer: Timer?
    private var credentials: ClaudeCredentials?

    var isConfigured: Bool {
        claudeDetected
    }

    func startMonitoring() {
        detectServices()
        guard isConfigured else { return }
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func detectServices() {
        credentials = ClaudeUsageService.loadCredentials()
        claudeDetected = credentials != nil
    }

    func refresh() {
        Task { @MainActor in
            isLoading = true
            await fetchAll()
            isLoading = false
        }
    }

    @MainActor
    private func fetchAll() async {
        if credentials == nil {
            detectServices()
        }

        if let creds = credentials {
            do {
                claudeUsage = try await ClaudeUsageService.fetch(credentials: creds)
            } catch {
                print("Claude usage fetch failed: \(error)")
            }
        }
    }
}
