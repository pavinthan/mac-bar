import SwiftUI

struct AIUsageView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.aiUsageManager

        VStack(spacing: 6) {
            if manager.claudeDetected {
                Text(manager.claudePlan ?? "Claude")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let error = manager.claudeError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if manager.isLoading && manager.claudeUsage == nil {
                    ProgressView().controlSize(.mini)
                } else {
                    usageRow(
                        label: "Session",
                        value: manager.claudeUsage?.sessionPercent ?? 0,
                        resetsAt: manager.claudeUsage?.sessionResetsAt
                    )
                    usageRow(
                        label: "Weekly",
                        value: manager.claudeUsage?.weeklyPercent ?? 0,
                        resetsAt: manager.claudeUsage?.weeklyResetsAt
                    )
                }
            }

            if manager.claudeDetected && manager.codexDetected {
                Divider().padding(.vertical, 2)
            }

            if manager.codexDetected {
                Text(manager.codexPlanName ?? "Codex")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let error = manager.codexError {
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if manager.isLoading && manager.codexUsage == nil {
                    ProgressView().controlSize(.mini)
                } else {
                    usageRow(
                        label: "Session",
                        value: manager.codexUsage?.sessionPercent ?? 0,
                        resetsAt: manager.codexUsage?.sessionResetsAt
                    )
                    usageRow(
                        label: "Weekly",
                        value: manager.codexUsage?.weeklyPercent ?? 0,
                        resetsAt: manager.codexUsage?.weeklyResetsAt
                    )
                }
            }
        }
    }

    private func usageRow(label: String, value: Double, resetsAt: Date?) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.medium))
                    .frame(width: 50, alignment: .leading)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.quaternary)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor(for: value))
                            .frame(width: max(0, geometry.size.width * min(value / 100, 1)))
                    }
                }
                .frame(height: 8)

                Text("\(Int(value))%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)

                if let resetsAt {
                    Text(resetText(resetsAt))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 45, alignment: .trailing)
                }
            }
        }
    }

    private func barColor(for value: Double) -> Color {
        if value < 50 {
            return .green
        } else if value < 80 {
            return .yellow
        } else {
            return .red
        }
    }

    private func resetText(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "soon" }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if days > 0 {
            return "\(days)d \(hours)h"
        }
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
