import Sparkle
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button {
                    appState.showingSettings = false
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Text("Settings")
                    .font(.headline)

                Spacer()

                Color.clear.frame(width: 40)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("General").tag(0)
                Text("Shortcuts").tag(1)
                Text("About").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Tab content
            switch selectedTab {
            case 0: generalTab
            case 1: shortcutsTab
            case 2: aboutTab
            default: EmptyView()
            }
        }
        .frame(width: 340)
        .sheet(isPresented: Bindable(appState).clockManager.showingAddSheet) {
            AddTimezoneSheet(clockManager: appState.clockManager)
        }
    }

    // MARK: - General Tab

    @ViewBuilder
    private var generalTab: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 10) {
            Text("General")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                Text("Launch at Login")
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $state.launchAtLogin)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }

            Divider()

            // Timezones
            HStack {
                Text("Timezones")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    appState.clockManager.showingAddSheet = true
                } label: {
                    Image(systemName: "plus").font(.caption)
                }
                .buttonStyle(.plain)
            }

            ForEach(appState.clockManager.clocks) { clock in
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(clock.label)
                            .font(.system(size: 12, weight: .medium))
                        Text(clock.timezoneID)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    if appState.clockManager.clocks.count > 1 {
                        Button {
                            appState.clockManager.removeClock(id: clock.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundStyle(.red.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }

            Divider()

            // Color Picker
            Text("Color Picker")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                Text("Default copy format")
                    .font(.system(size: 12))
                Spacer()
                Picker("", selection: $state.colorCopyFormat) {
                    ForEach(ColorFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }

        }
        .padding(16)
    }

    // MARK: - Shortcuts Tab

    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Global Keyboard Shortcuts")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("Control + Option + Key")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            ForEach(appState.shortcutsManager.shortcuts) { shortcut in
                HStack {
                    Text(shortcut.label)
                        .font(.system(size: 12))

                    Spacer()

                    Text(shortcut.displayString)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))

                    Toggle("", isOn: Binding(
                        get: { shortcut.isEnabled },
                        set: { newValue in
                            var updated = shortcut
                            updated.isEnabled = newValue
                            appState.shortcutsManager.updateShortcut(updated)
                        }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .labelsHidden()
                }
                .padding(.vertical, 2)
            }

            Divider()

            HStack {
                Text("Voice Mode: Hold Right Option key")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }

            Button("Reset to Defaults") {
                appState.shortcutsManager.resetDefaults()
            }
            .font(.caption)
            .buttonStyle(.plain)
            .foregroundStyle(.blue)
        }
        .padding(16)
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            // App info
            HStack(spacing: 12) {
                if let icon = NSApp.applicationIconImage {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("MacBar")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Update
            Text("Updates")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            UpdateCheckView()

            Divider()

            // Links
            Text("Links")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Button {
                NSWorkspace.shared.open(URL(string: "https://github.com/pavinthan/mac-bar")!)
            } label: {
                HStack {
                    Text("GitHub Repository")
                        .font(.system(size: 12))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)

            Button {
                NSWorkspace.shared.open(URL(string: "https://github.com/pavinthan/mac-bar/issues")!)
            } label: {
                HStack {
                    Text("Report an Issue")
                        .font(.system(size: 12))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
}

// MARK: - Sparkle Update View

struct UpdateCheckView: View {
    @State private var updaterController: SPUStandardUpdaterController?
    @State private var checkStatus: String?

    var body: some View {
        HStack {
            Text("Check for Updates")
                .font(.system(size: 12))

            if let status = checkStatus {
                Text(status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Check Now") {
                checkForUpdates()
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func checkForUpdates() {
        if updaterController == nil {
            updaterController = SPUStandardUpdaterController(startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil)
            do {
                try updaterController?.updater.start()
            } catch {
                checkStatus = "Not available"
                return
            }
        }
        updaterController?.checkForUpdates(nil)
    }
}
