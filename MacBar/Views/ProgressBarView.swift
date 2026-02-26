import SwiftUI

struct ProgressBarView: View {
    let label: String
    let value: Double
    let detail: String

    private var barColor: Color {
        if value < 50 {
            return .green
        } else if value < 80 {
            return .yellow
        } else {
            return .red
        }
    }

    var body: some View {
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
                            .fill(barColor)
                            .frame(width: max(0, geometry.size.width * min(value / 100, 1)))
                    }
                }
                .frame(height: 8)

                Text(detail)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }
}
