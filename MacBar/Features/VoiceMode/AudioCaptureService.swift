import AVFoundation
import Foundation

final class AudioCaptureService {
    private let audioEngine = AVAudioEngine()
    private var capturedSamples: [Float] = []
    private let captureQueue = DispatchQueue(label: "com.macbar.audio.capture")
    private var isRecording = false
    private var recordedSampleRate: Double = 16000

    private let outputChannels: AVAudioChannelCount = 1

    func startRecording() async throws {
        guard !isRecording else {
            throw AudioCaptureError.alreadyRecording
        }

        captureQueue.sync {
            capturedSamples.removeAll()
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        recordedSampleRate = inputFormat.sampleRate

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else {
                return
            }
            guard let channelData = buffer.floatChannelData else {
                return
            }

            let frameCount = Int(buffer.frameLength)
            let source = UnsafeBufferPointer(start: channelData[0], count: frameCount)

            self.captureQueue.sync {
                self.capturedSamples.append(contentsOf: source)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
    }

    func stopRecording() async throws -> URL {
        guard isRecording else {
            throw AudioCaptureError.notRecording
        }

        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRecording = false

        let sampleCount = captureQueue.sync { capturedSamples.count }
        guard sampleCount > 0 else {
            throw AudioCaptureError.notRecording
        }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        try writeWAVFile(to: tempURL)
        return tempURL
    }

    private func writeWAVFile(to url: URL) throws {
        let allSamples = captureQueue.sync { capturedSamples }

        let bytesPerSample: UInt32 = 4
        let dataSize = UInt32(allSamples.count) * bytesPerSample
        let sampleRateUInt: UInt32 = UInt32(recordedSampleRate)
        let channelCount: UInt16 = UInt16(outputChannels)
        let bitsPerSample: UInt16 = 32
        let byteRate: UInt32 = sampleRateUInt * UInt32(channelCount) * bytesPerSample
        let blockAlign: UInt16 = UInt16(bytesPerSample) * channelCount

        var header = Data()

        header.append(contentsOf: "RIFF".utf8)
        header.append(withUnsafeBytes(of: (36 + dataSize).littleEndian) { Data($0) })
        header.append(contentsOf: "WAVE".utf8)

        header.append(contentsOf: "fmt ".utf8)
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(3).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: channelCount.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRateUInt.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })

        header.append(contentsOf: "data".utf8)
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })

        var fileData = header
        allSamples.withUnsafeBytes { rawBuffer in
            fileData.append(contentsOf: rawBuffer)
        }

        try fileData.write(to: url)
    }
}

enum AudioCaptureError: LocalizedError {
    case alreadyRecording
    case notRecording

    var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "Audio capture is already in progress."
        case .notRecording:
            return "No audio capture in progress."
        }
    }
}
