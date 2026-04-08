import AppKit
import Combine
import SwiftUI

final class VoiceOverlayWindow: NSPanel {
    private var cancellable: AnyCancellable?
    private let voiceManager: VoiceModeManager

    init(voiceManager: VoiceModeManager) {
        self.voiceManager = voiceManager

        let contentRect = NSRect(x: 0, y: 0, width: 300, height: 80)
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        let overlayView = VoiceOverlayView(voiceManager: voiceManager)
        let hostingView = NSHostingView(rootView: overlayView)
        hostingView.frame = contentRect
        contentView = hostingView

        positionAtBottomCenter()
        observeState()
    }

    private func positionAtBottomCenter() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - frame.width / 2
        let y = screenFrame.minY + 100
        setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func showOverlay() {
        positionAtBottomCenter()
        alphaValue = 0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 1
        }
    }

    private func hideOverlay() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }

    private func observeState() {
        cancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.voiceManager.isOverlayVisible {
                    if !self.isVisible {
                        self.showOverlay()
                    }
                } else {
                    if self.isVisible {
                        self.hideOverlay()
                    }
                }
            }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Overlay SwiftUI View

struct VoiceOverlayView: View {
    let voiceManager: VoiceModeManager

    var body: some View {
        VStack(spacing: 6) {
            statusContent
            if !voiceManager.currentTranscript.isEmpty {
                Text(voiceManager.currentTranscript)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(minWidth: 200, maxWidth: 300)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .animation(.easeInOut(duration: 0.3), value: voiceManager.pipelineState.isActive)
    }

    @ViewBuilder
    private var statusContent: some View {
        switch voiceManager.pipelineState {
        case .idle:
            EmptyView()

        case .listening:
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse)
                    .font(.title3)
                Text("Listening...")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

        case .transcribing:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                Text("Transcribing...")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

        case .processing:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
                Text("Processing...")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

        case .executing:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
                Text("Done")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

        case .error(let message):
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
    }
}
