import SwiftUI

struct QRScannerView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.qrScannerManager

        Button {
            manager.scanScreen()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.copied ? "checkmark" : "qrcode.viewfinder")
                    .font(.title2)
                    .contentTransition(.symbolEffect(.replace))
                Text("Scan QR")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
