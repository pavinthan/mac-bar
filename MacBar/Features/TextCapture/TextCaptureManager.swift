import AppKit
import CoreServices
import Vision

@Observable
final class TextCaptureManager {
    var copied = false

    @MainActor
    func captureText() {
        copied = false
        NSApp.keyWindow?.orderOut(nil)

        let tempPath = NSTemporaryDirectory() + "macbar_ocr.png"
        try? FileManager.default.removeItem(atPath: tempPath)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", "-x", tempPath]

        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                defer { try? FileManager.default.removeItem(atPath: tempPath) }

                guard FileManager.default.fileExists(atPath: tempPath),
                      let nsImage = NSImage(contentsOfFile: tempPath),
                      let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
                else { return }

                let text = self?.recognizeText(from: cgImage) ?? ""
                guard !text.isEmpty else { return }

                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                self?.copied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { self?.copied = false }
            }
        }

        try? process.run()
    }

    private func recognizeText(from cgImage: CGImage) -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])

        guard let results = request.results else { return "" }

        return results
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
    }
}
