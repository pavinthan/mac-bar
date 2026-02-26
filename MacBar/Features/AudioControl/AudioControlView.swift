import SwiftUI

struct MuteSoundView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.audioManager

        Button {
            manager.toggleSound()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.isSoundMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
                Text(manager.isSoundMuted ? "Unmute" : "Sound")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(manager.isSoundMuted ? Color.red.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct MuteMicView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.audioManager

        Button {
            manager.toggleMic()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.isMicMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
                Text(manager.isMicMuted ? "Unmute" : "Mic")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(manager.isMicMuted ? Color.red.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
