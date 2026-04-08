import SwiftUI

struct KeepAwakeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.keepAwakeManager

        Button {
            manager.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.isActive ? "cup.and.heat.waves.fill" : "cup.and.heat.waves")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(manager.isActive ? "Awake" : "Caffeine")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(manager.isActive ? Color.green.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
