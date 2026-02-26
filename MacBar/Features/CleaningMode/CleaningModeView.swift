import SwiftUI

struct CleaningModeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.cleaningModeManager.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "sparkles.rectangle.stack")
                    .font(.title2)
                Text("Clean")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
