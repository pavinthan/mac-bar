import SwiftUI

struct ColorPickerFeatureView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Button {
            Task {
                await appState.colorPickerManager.pickColor()
                autoCopy()
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "eyedropper")
                    .font(.title2)
                Text("Pick Color")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func autoCopy() {
        let manager = appState.colorPickerManager
        guard manager.pickedColor != nil else { return }

        let value: String
        switch appState.colorCopyFormat {
        case .hex: value = manager.hexString
        case .rgb: value = manager.rgbString
        case .hsl: value = manager.hslString
        case .swiftUI: value = manager.swiftUIString
        }
        manager.copyToClipboard(value)
    }

}
