import SwiftUI

struct BrowserSwitchView: View {
    @Environment(AppState.self) private var appState
    @State private var showingPermissionHint = false

    var body: some View {
        let manager = appState.browserManager

        if manager.browsers.isEmpty {
            Text("No browsers detected")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(manager.browsers) { browser in
                            browserButton(browser: browser)
                        }
                    }
                }

                if showingPermissionHint {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                        Text("Grant Accessibility permission, then try again.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func browserButton(browser: BrowserInfo) -> some View {
        Button {
            let manager = appState.browserManager
            if manager.hasAccessibilityPermission {
                showingPermissionHint = false
                manager.setDefault(browserID: browser.id)
            } else {
                manager.requestAccessibilityPermission()
                showingPermissionHint = true
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: browser.icon)
                        .resizable()
                        .frame(width: 32, height: 32)

                    if browser.isDefault {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white, .green)
                            .offset(x: 2, y: 2)
                    }
                }

                Text(browser.name)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .frame(width: 48)
            }
            .padding(6)
            .background(
                browser.isDefault
                    ? AnyShapeStyle(.tint.opacity(0.15))
                    : AnyShapeStyle(.clear),
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }
}
