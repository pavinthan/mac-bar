import SwiftUI

struct VoiceModeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.voiceModeManager

        Button {
            manager.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.isActive ? "waveform.circle.fill" : "waveform")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(manager.isActive ? "Stop" : "Voice")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(manager.isActive ? Color.blue.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
