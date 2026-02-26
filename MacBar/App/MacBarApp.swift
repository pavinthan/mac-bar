import SwiftUI

@main
struct MacBarApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(appState)
                .focusable(false)
                .focusEffectDisabled()
        } label: {
            Image(systemName: "square.grid.2x2")
                .symbolRenderingMode(.hierarchical)
        }
        .menuBarExtraStyle(.window)
    }
}
