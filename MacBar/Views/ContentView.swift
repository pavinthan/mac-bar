import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.showingSettings {
                SettingsView()
                    .environment(appState)
                    .transition(.move(edge: .trailing))
            } else {
                mainView
                    .transition(.move(edge: .leading))
            }
        }
        .frame(width: 340)
        .clipped()
        .animation(.easeInOut(duration: 0.25), value: appState.showingSettings)
        .focusable(false)
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 14) {
            WordClockView()

            Divider()

            SectionHeader(title: "Default Browser", icon: "globe")
            BrowserSwitchView()

            Divider()

            SectionHeader(title: "Quick Actions", icon: "bolt.fill")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ColorPickerFeatureView()
                CleaningModeView()
                QRScannerView()
                MuteSoundView()
                MuteMicView()
            }

            Divider()

            SectionHeader(title: "System", icon: "cpu")
            SystemStatsView()

            if appState.aiUsageManager.isConfigured {
                Divider()

                SectionHeader(title: "AI Usage", icon: "brain")
                AIUsageView()
            }

            Divider()

            footerSection
        }
        .padding(16)
        .frame(width: 340)
    }

    private var footerSection: some View {
        HStack {
            Button {
                appState.showingSettings = true
            } label: {
                Label("Settings", systemImage: "gear")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }
}
