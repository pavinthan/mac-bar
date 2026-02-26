import AppKit
import CoreImage
import Vision

@Observable
final class QRScannerManager {
    var copied = false

    @MainActor
    func scanScreen() {
        copied = false

        // Close the popover so it doesn't overlap the screen capture
        NSApp.keyWindow?.orderOut(nil)

        let tempPath = NSTemporaryDirectory() + "macbar_qr.png"
        try? FileManager.default.removeItem(atPath: tempPath)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", tempPath]

        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }

                defer { try? FileManager.default.removeItem(atPath: tempPath) }

                guard FileManager.default.fileExists(atPath: tempPath),
                      let nsImage = NSImage(contentsOfFile: tempPath),
                      let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
                else {
                    return
                }

                self.detectQR(from: cgImage)
            }
        }

        do {
            try process.run()
        } catch {
            // silently fail
        }
    }

    private func detectQR(from cgImage: CGImage) {
        let ciImage = CIImage(cgImage: cgImage)

        let request = VNDetectBarcodesRequest()
        request.symbologies = [.qr]

        guard let results = try? {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            try handler.perform([request])
            return request.results
        }(), let code = results.compactMap({ $0.payloadStringValue }).first else {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        copied = true
    }
}
