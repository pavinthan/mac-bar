import SwiftUI

struct PortKillerButtonView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            appState.portKillerManager.scan()
            appState.showingPortKiller = true
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title3)
                Text("Ports")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .popover(isPresented: Bindable(appState).showingPortKiller, attachmentAnchor: .point(.center), arrowEdge: .top) {
            PortKillerPopover(manager: appState.portKillerManager, isPresented: Bindable(appState).showingPortKiller)
        }
    }
}

struct PortKillerPopover: View {
    let manager: PortKillerManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Listening Ports")
                    .font(.headline)

                Text("\(manager.ports.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())

                Spacer()

                Button {
                    manager.scan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if manager.isScanning {
                HStack {
                    Spacer()
                    ProgressView().controlSize(.small)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if manager.ports.isEmpty {
                Text("No listening ports found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                List {
                    ForEach(manager.ports) { entry in
                        HStack(spacing: 8) {
                            Text("\(entry.port)")
                                .font(.caption.monospacedDigit().weight(.medium))
                                .frame(width: 45, alignment: .leading)

                            Text(entry.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 70, alignment: .leading)
                                .lineLimit(1)

                            Text("\(entry.pid)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                                .frame(width: 50, alignment: .leading)

                            Text(entry.address)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineLimit(1)

                            Button {
                                manager.kill(entry: entry)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 1)
                    }
                }
                .listStyle(.plain)
                .frame(height: min(CGFloat(manager.ports.count) * 28 + 10, 300))
            }
        }
        .padding(14)
        .frame(width: 340)
    }
}
