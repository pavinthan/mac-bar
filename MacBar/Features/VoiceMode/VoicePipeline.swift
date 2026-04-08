import ApplicationServices
import Foundation

final class VoicePipeline {
    private let audioService: AudioCaptureService
    private let transcriptionService: TranscriptionService
    private let intentParser: VoiceIntentParser
    private let actionRegistry: ActionRegistry

    private let stateCallback: ((VoicePipelineState) -> Void)?
    private let transcriptCallback: ((String) -> Void)?

    init(
        audioService: AudioCaptureService,
        transcriptionService: TranscriptionService,
        intentParser: VoiceIntentParser,
        actionRegistry: ActionRegistry,
        stateCallback: ((VoicePipelineState) -> Void)? = nil,
        transcriptCallback: ((String) -> Void)? = nil
    ) {
        self.audioService = audioService
        self.transcriptionService = transcriptionService
        self.intentParser = intentParser
        self.actionRegistry = actionRegistry
        self.stateCallback = stateCallback
        self.transcriptCallback = transcriptCallback
    }

    func startListening() async {
        do {
            try await audioService.startRecording()
            stateCallback?(.listening)
        } catch {
            stateCallback?(.error(error.localizedDescription))
        }
    }

    func stopListening() async {
        var audioURL: URL?
        do {
            stateCallback?(.transcribing)
            audioURL = try await audioService.stopRecording()

            guard let audioURL else {
                stateCallback?(.idle)
                return
            }

            let transcript = try await transcriptionService.transcribe(
                audioURL: audioURL,
                language: VoiceModeManager.systemInputLanguage()
            )
            transcriptCallback?(transcript)

            guard !transcript.isEmpty else {
                stateCallback?(.idle)
                try? FileManager.default.removeItem(at: audioURL)
                return
            }

            stateCallback?(.processing)
            let intent = intentParser.parseIntent(transcript: transcript)
            let forceDictation = isTextInputFocused() && !looksLikeExplicitCommand(transcript)

            stateCallback?(.executing)
            if forceDictation {
                let context = ActionContext(text: transcript, params: ["text": transcript])
                try await actionRegistry.execute(action: "dictate", context: context)
            } else {
                switch intent {
                case .dictation(let text):
                    let context = ActionContext(text: text, params: ["text": text])
                    try await actionRegistry.execute(action: "dictate", context: context)
                case .command(let action, let params):
                    let text = params["text"] ?? transcript
                    let context = ActionContext(text: text, params: params)
                    try await actionRegistry.execute(action: action, context: context)
                }
            }

            stateCallback?(.idle)
            try? FileManager.default.removeItem(at: audioURL)
        } catch {
            print("Voice pipeline error: \(error)")
            // Clean up temp file
            if let audioURL {
                try? FileManager.default.removeItem(at: audioURL)
            }
            stateCallback?(.error(error.localizedDescription))
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                stateCallback?(.idle)
            }
        }
    }

    private func looksLikeExplicitCommand(_ transcript: String) -> Bool {
        let normalized = transcript.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = [
            "switch to ", "go to ", "open ", "copy", "paste",
            "type ", "insert ", "write ", "dictate "
        ]
        return prefixes.contains { normalized.hasPrefix($0) || normalized == $0 }
    }

    private func isTextInputFocused() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElementRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )

        guard result == .success,
              let focusedElementRef,
              CFGetTypeID(focusedElementRef) == AXUIElementGetTypeID() else {
            return false
        }
        let focusedElement = focusedElementRef as! AXUIElement

        var editableRef: CFTypeRef?
        let editableResult = AXUIElementCopyAttributeValue(
            focusedElement,
            "AXEditable" as CFString,
            &editableRef
        )
        if editableResult == .success, let editable = editableRef as? Bool, editable {
            return true
        }

        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(
            focusedElement,
            kAXRoleAttribute as CFString,
            &roleRef
        )
        guard roleResult == .success, let role = roleRef as? String else {
            return false
        }

        let textRoles: Set<String> = ["AXTextField", "AXTextArea", "AXSearchField", "AXComboBox"]
        return textRoles.contains(role)
    }
}
