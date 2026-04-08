import SwiftUI

struct LockdownModeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.lockdownModeManager

        Button {
            manager.toggle()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.isActive ? "lock.open.fill" : "lock.fill")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(manager.isActive ? "Unlock" : "Lockdown")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(manager.isActive ? Color.orange.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
