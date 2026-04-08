import Carbon
import Foundation

@Observable
final class VoiceModeManager {
    var pipelineState: VoicePipelineState = .idle
    var currentTranscript: String = ""
    var isOverlayVisible: Bool = false
    var isActive: Bool { pipelineState.isActive }

    private(set) var pipeline: VoicePipeline!
    private var hotkeyManager: VoiceHotkeyManager?
    private var overlayWindow: VoiceOverlayWindow?
    private let intentParser: VoiceIntentParser

    init() {
        let audioCaptureService = AudioCaptureService()
        let whisperKitService = WhisperKitService()
        let intentParser = VoiceIntentParser()
        let actionRegistry = ActionRegistry()
        let keySimulator = KeySimulator()

        actionRegistry.register(DictateAction(keySimulator: keySimulator))
        actionRegistry.register(CopyAction())
        actionRegistry.register(PasteTextAction())
        actionRegistry.register(SwitchAppAction())
        actionRegistry.register(SwitchTabAction(keySimulator: keySimulator))

        self.intentParser = intentParser

        self.pipeline = VoicePipeline(
            audioService: audioCaptureService,
            transcriptionService: whisperKitService,
            intentParser: intentParser,
            actionRegistry: actionRegistry,
            stateCallback: { [weak self] state in
                Task { @MainActor in
                    self?.pipelineState = state
                    self?.isOverlayVisible = state != .idle
                }
            },
            transcriptCallback: { [weak self] transcript in
                Task { @MainActor in
                    self?.currentTranscript = transcript
                }
            }
        )

        // Warm up WhisperKit model in background
        Task(priority: .utility) {
            await whisperKitService.warmUp()
        }
    }

    func setupHotkey() {
        hotkeyManager = VoiceHotkeyManager { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                switch event {
                case .keyDown:
                    await self.pipeline.startListening()
                case .keyUp:
                    await self.pipeline.stopListening()
                }
            }
        }
        hotkeyManager?.start()
    }

    func setupOverlay() {
        overlayWindow = VoiceOverlayWindow(voiceManager: self)
    }

    func toggle() {
        switch pipelineState {
        case .idle:
            Task {
                await pipeline.startListening()
            }
        case .listening:
            Task {
                await pipeline.stopListening()
            }
        default:
            // Already processing — ignore toggle
            break
        }
    }

    func tearDown() {
        hotkeyManager?.stop()
        overlayWindow?.close()
    }

    static func systemInputLanguage() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages),
              let languages = Unmanaged<CFArray>.fromOpaque(idPtr).takeUnretainedValue() as? [String],
              let primary = languages.first else {
            return "en"
        }
        return String(primary.prefix(2))
    }
}
