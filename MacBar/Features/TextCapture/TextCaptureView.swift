import SwiftUI

struct CaptureTextView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let manager = appState.textCaptureManager

        Button {
            manager.captureText()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: manager.copied ? "checkmark" : "text.viewfinder")
                    .font(.title3)
                    .contentTransition(.symbolEffect(.replace))
                Text(manager.copied ? "Copied" : "OCR")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(manager.copied ? Color.green.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
