import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Divider()

            generalSection

            Divider()

            timezoneSection

            Divider()

            colorSection
        }
        .padding(16)
        .frame(width: 340)
        .sheet(isPresented: Bindable(appState).clockManager.showingAddSheet) {
            AddTimezoneSheet(clockManager: appState.clockManager)
        }
    }

    private var header: some View {
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

            // Balance the back button width
            Color.clear
                .frame(width: 40)
        }
    }

    @ViewBuilder
    private var generalSection: some View {
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
        }
    }

    private var timezoneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Timezones")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    appState.clockManager.showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
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
        }
    }

    @ViewBuilder
    private var colorSection: some View {
        @Bindable var state = appState

        VStack(alignment: .leading, spacing: 10) {
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
    }

}
