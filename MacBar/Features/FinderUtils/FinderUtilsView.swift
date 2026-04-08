import SwiftUI

struct ToggleHiddenFilesView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.finderUtilsManager

        Button {
            manager.toggleHiddenFiles()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.hiddenFilesVisible ? "eye.fill" : "eye.slash.fill")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(manager.hiddenFilesVisible ? "Visible" : "Hidden")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(manager.hiddenFilesVisible ? Color.purple.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct OpenInTerminalView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.finderUtilsManager.openInTerminal()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "terminal.fill")
                    .font(.title3)
                Text("Terminal")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct CopyPathView: View {
    @Environment(AppState.self) private var appState
    @State private var copied = false

    var body: some View {
        Button {
            appState.finderUtilsManager.copyPath()
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: copied ? "checkmark" : "doc.on.clipboard")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(copied ? "Copied" : "Path")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(copied ? Color.green.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct NewTextFileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.finderUtilsManager.newTextFile()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "doc.badge.plus")
                    .font(.title3)
                Text("New File")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
