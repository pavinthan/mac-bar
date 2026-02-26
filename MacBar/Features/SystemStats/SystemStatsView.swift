import SwiftUI

struct SystemStatsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let stats = appState.systemStatsManager

        VStack(spacing: 6) {
            ProgressBarView(
                label: "CPU",
                value: stats.cpuUsage,
                detail: String(format: "%.1f%%", stats.cpuUsage)
            )

            ProgressBarView(
                label: "Memory",
                value: stats.memoryUsage,
                detail: String(format: "%.1f/%.0f GB", stats.memoryUsedGB, stats.memoryTotalGB)
            )

            ProgressBarView(
                label: "Disk",
                value: stats.diskUsage,
                detail: String(format: "%.0f/%.0f GB", stats.diskUsedGB, stats.diskTotalGB)
            )

            HStack {
                Text("Network")
                    .font(.caption.weight(.medium))
                    .frame(width: 50, alignment: .leading)

                Spacer()

                HStack(spacing: 8) {
                    Label(
                        NetworkMonitor.formatRate(stats.networkInRate),
                        systemImage: "arrow.down"
                    )

                    Label(
                        NetworkMonitor.formatRate(stats.networkOutRate),
                        systemImage: "arrow.up"
                    )
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
    }
}
