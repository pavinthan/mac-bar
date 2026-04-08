import Foundation
import WhisperKit

protocol TranscriptionService {
    func transcribe(audioURL: URL, language: String) async throws -> String
}

final class WhisperKitService: TranscriptionService {
    private var whisperKit: WhisperKit?
    private(set) var isModelLoaded = false

    func warmUp() async {
        _ = try? await loadModelIfNeeded()
    }

    private func loadModelIfNeeded() async throws {
        if whisperKit != nil {
            return
        }

        let recommendedDefault = WhisperKit.recommendedModels().default
        let candidateOrder = [
            "openai_whisper-tiny",
            "openai_whisper-base",
            "openai_whisper-small",
            recommendedDefault
        ]
        var seen = Set<String>()
        let modelCandidates = candidateOrder.filter { seen.insert($0).inserted }

        var lastError: Error?
        for modelName in modelCandidates {
            do {
                let config = WhisperKitConfig(
                    model: modelName,
                    verbose: false,
                    logLevel: .none,
                    prewarm: false,
                    load: true
                )
                let kit = try await WhisperKit(config)
                whisperKit = kit
                isModelLoaded = true
                return
            } catch {
                lastError = error
            }
        }

        throw WhisperKitServiceError.modelLoadFailed(lastError?.localizedDescription ?? "Unknown model load error")
    }

    func transcribe(audioURL: URL, language: String) async throws -> String {
        try await loadModelIfNeeded()

        guard let whisperKit = whisperKit else {
            throw WhisperKitServiceError.modelNotLoaded
        }

        let options = DecodingOptions(language: language)

        let results = try await whisperKit.transcribe(
            audioPath: audioURL.path,
            decodeOptions: options
        )

        let text = results
            .compactMap { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            throw WhisperKitServiceError.emptyTranscription
        }

        return text
    }
}

enum WhisperKitServiceError: LocalizedError {
    case modelNotLoaded
    case emptyTranscription
    case modelLoadFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "WhisperKit model is not loaded."
        case .emptyTranscription:
            return "Transcription returned no text."
        case .modelLoadFailed(let message):
            return "Failed to load WhisperKit model: \(message)"
        }
    }
}
