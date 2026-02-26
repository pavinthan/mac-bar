import SwiftUI

struct AIUsageView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.aiUsageManager

        VStack(spacing: 6) {
            if let usage = manager.claudeUsage {
                HStack {
                    Text(usage.plan)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    if let resetsAt = usage.resetsAt {
                        Text(resetText(resetsAt))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                ProgressBarView(
                    label: "Session",
                    value: usage.sessionPercent,
                    detail: "\(Int(usage.sessionPercent))%"
                )
                ProgressBarView(
                    label: "Weekly",
                    value: usage.weeklyPercent,
                    detail: "\(Int(usage.weeklyPercent))%"
                )
                if usage.opusPercent > 0 {
                    ProgressBarView(
                        label: "Opus",
                        value: usage.opusPercent,
                        detail: "\(Int(usage.opusPercent))%"
                    )
                }
                if usage.sonnetPercent > 0 {
                    ProgressBarView(
                        label: "Sonnet",
                        value: usage.sonnetPercent,
                        detail: "\(Int(usage.sonnetPercent))%"
                    )
                }
            } else if manager.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func resetText(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "Resets soon" }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "Resets in \(hours)h \(minutes)m"
        }
        return "Resets in \(minutes)m"
    }
}
